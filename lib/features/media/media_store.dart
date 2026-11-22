import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// The only image format the v1 media protocol accepts. The sticker editor
/// emits PNG, and the media endpoint checks the magic bytes before storing.
const mediaPngMime = 'image/png';

/// Media bytes above this size are rejected instead of being truncated.
const maxMediaBytes = 4 * 1024 * 1024;

/// The whole media response has to fit in this budget so one request cannot
/// exhaust a small device. Clients batch by count and retry the rest.
const maxMediaResponseBytes = 8 * 1024 * 1024;
const maxMediaIdsPerRequest = 32;

final _mediaIdPattern = RegExp(r'^[0-9a-f]{64}$');

bool isMediaId(String value) => _mediaIdPattern.hasMatch(value);

/// A device-local cache entry for one content-addressed image.
class MediaCacheEntry {
  const MediaCacheEntry({required this.id, required this.path, required this.mime, required this.byteSize});

  final String id;
  final String path;
  final String mime;
  final int byteSize;
}

/// A verified image returned by the local cache.
class MediaBlob {
  const MediaBlob({required this.id, required this.mime, required this.bytes});

  final String id;
  final String mime;
  final Uint8List bytes;

  int get byteSize => bytes.length;
}

class MediaTooLargeException implements Exception {
  const MediaTooLargeException(this.byteSize);

  final int byteSize;

  @override
  String toString() => 'MediaTooLargeException: $byteSize bytes';
}

/// Copies a sticker PNG into the app's private media folder.
Future<String> saveStickerImage(Uint8List bytes) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory(p.join(support.path, 'media'));
  if (!directory.existsSync()) await directory.create(recursive: true);
  final file = File(p.join(directory.path, '${const Uuid().v4()}.png'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Removes an editor-owned display image. Content-addressed cache files are
/// immutable and shared by every row with the same bytes, so a stale editor
/// reference must never delete one.
Future<void> deleteStickerImage(String? path) async {
  if (path == null || path.isEmpty) return;
  if (MediaStore.isCachePath(path)) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// Removes every sticker copied into the app's private media folder, including
/// the content-addressed cache.
Future<void> deleteAllStickerImages() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory(p.join(support.path, 'media'));
  if (directory.existsSync()) await directory.delete(recursive: true);
}

/// Content-addressed storage for synced images.
///
/// The cache lives at `.../media/cache/<sha256>.png` and is immutable: several
/// rows may share one file, and an editor replacing an image never deletes it.
/// Delayed peers may still ask for the old hash, so v1 has no cache garbage
/// collection beyond an explicit clear-all.
class MediaStore {
  MediaStore({Directory? directory}) : _directory = directory;

  static const mime = mediaPngMime;
  static const maxBytes = maxMediaBytes;
  static const maxResponseBytes = maxMediaResponseBytes;
  static const maxIdsPerRequest = maxMediaIdsPerRequest;

  final Directory? _directory;
  Directory? _resolved;

  /// True when the store has an injected directory or has resolved the default
  /// one. Delete-all uses this to avoid touching the platform path provider on
  /// a database that never stored an image.
  bool get isConfigured => _directory != null || _resolved != null;

  /// Resolves the managed media folder once. Tests inject a temp directory;
  /// production uses `getApplicationSupportDirectory()/media`.
  Future<Directory> root() async {
    final existing = _resolved;
    if (existing != null) return existing;
    final override = _directory;
    final directory = override ?? Directory(p.join((await getApplicationSupportDirectory()).path, 'media'));
    _resolved = directory;
    return directory;
  }

  Future<Directory> cacheDirectory() async {
    final directory = Directory(p.join((await root()).path, 'cache'));
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  /// The immutable cache path for [id]. The file may not exist yet.
  Future<String> cachePath(String id) async => p.join((await cacheDirectory()).path, '$id.png');

  static String hashBytes(List<int> bytes) => sha256.convert(bytes).toString();

  /// Only the PNG signature is required for v1; the sticker editor always emits
  /// a complete PNG, and the signature stops arbitrary bytes from travelling as
  /// `image/png`.
  static bool looksLikePng(List<int> bytes) {
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
  }

  /// True when [path] is a content-addressed cache file. Used by the editor
  /// deletion helper so a shared cache file is never removed.
  static bool isCachePath(String path) {
    final segments = p.split(p.normalize(path)).where((segment) => segment.isNotEmpty).toList();
    if (segments.length >= 2) {
      final parent = segments[segments.length - 2];
      final name = segments.last;
      if (parent == 'cache' && RegExp(r'^[0-9a-f]{64}\.png$').hasMatch(name)) return true;
    }
    for (var index = 1; index < segments.length; index++) {
      if (segments[index - 1] == 'media' && segments[index] == 'cache') return true;
    }
    return false;
  }

  /// Stores [bytes] and returns their content address. Invalid or oversized
  /// images return null / throw so a caller can keep the row without media.
  Future<MediaCacheEntry?> cacheBytes(Uint8List bytes) async {
    if (!looksLikePng(bytes)) return null;
    if (bytes.length > maxBytes) throw MediaTooLargeException(bytes.length);
    final id = hashBytes(bytes);
    final path = await cachePath(id);
    await _writeIfNeeded(path, bytes, id);
    return MediaCacheEntry(id: id, path: path, mime: mime, byteSize: bytes.length);
  }

  /// Reads a display file, validates it and ensures its cache copy.
  Future<MediaCacheEntry?> cacheFromFile(String path) async {
    if (path.trim().isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length > maxBytes) throw MediaTooLargeException(length);
    return cacheBytes(await file.readAsBytes());
  }

  /// Verifies an image received from a peer against its content address and
  /// stores it. Anything that does not match is rejected; callers treat that as
  /// a pending image rather than a corrupted row.
  Future<MediaCacheEntry?> storeVerified(String id, Uint8List bytes) async {
    if (!isMediaId(id)) return null;
    if (!looksLikePng(bytes)) return null;
    if (bytes.length > maxBytes) throw MediaTooLargeException(bytes.length);
    if (hashBytes(bytes) != id) return null;
    final path = await cachePath(id);
    await _writeIfNeeded(path, bytes, id);
    return MediaCacheEntry(id: id, path: path, mime: mime, byteSize: bytes.length);
  }

  /// The cache is immutable for well-formed files, but a crashed or truncated
  /// write must not strand a hash forever. Rewriting a mismatched file is safe
  /// because the name is the content address.
  Future<void> _writeIfNeeded(String path, Uint8List bytes, String id) async {
    final file = File(path);
    if (await file.exists()) {
      final existing = await file.readAsBytes();
      if (existing.length == bytes.length && hashBytes(existing) == id) return;
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  /// True when the cache file for [id] exists.
  Future<bool> contains(String id) async {
    if (!isMediaId(id)) return false;
    final path = await cachePath(id);
    return File(path).exists();
  }

  /// The local path to show in the UI, or null while the image is pending or
  /// its cache file no longer verifies.
  Future<String?> displayPath(String id) async {
    try {
      if (await readCached(id) == null) return null;
    } on MediaTooLargeException {
      return null;
    }
    return cachePath(id);
  }

  /// Reads and verifies a cached image. Used only by the LAN media endpoint.
  Future<MediaBlob?> readCached(String id, {int maxSize = maxBytes}) async {
    if (!isMediaId(id)) return null;
    final path = await cachePath(id);
    final file = File(path);
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length > maxSize) throw MediaTooLargeException(length);
    final bytes = await file.readAsBytes();
    if (hashBytes(bytes) != id) return null;
    return MediaBlob(id: id, mime: mime, bytes: bytes);
  }

  Future<void> clearCache() async {
    final directory = Directory(p.join((await root()).path, 'cache'));
    if (directory.existsSync()) await directory.delete(recursive: true);
  }

  /// Clears the cache only when this store has a directory. A database that
  /// never stored an image must not ask the platform for an app folder.
  Future<void> clearCacheIfConfigured() async {
    if (!isConfigured) return;
    await clearCache();
  }
}

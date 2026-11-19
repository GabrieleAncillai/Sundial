import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a sticker PNG into the app's private media folder.
Future<String> saveStickerImage(Uint8List bytes) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory(p.join(support.path, 'media'));
  if (!directory.existsSync()) await directory.create(recursive: true);
  final file = File(p.join(directory.path, '${const Uuid().v4()}.png'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> deleteStickerImage(String? path) async {
  if (path == null || path.isEmpty) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// Removes every sticker copied into the app's private media folder.
Future<void> deleteAllStickerImages() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory(p.join(support.path, 'media'));
  if (directory.existsSync()) await directory.delete(recursive: true);
}

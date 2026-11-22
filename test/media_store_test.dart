import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';

import 'support/media_fixture.dart';

void main() {
  late Directory root;
  late MediaStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sundial-media-store');
    store = MediaStore(directory: root);
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('hashes are stable and duplicate bytes share one cache file', () async {
    final first = await store.cacheBytes(tinyPng);
    final second = await store.cacheBytes(Uint8List.fromList(tinyPng));

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.id, MediaStore.hashBytes(tinyPng));
    expect(first.id, second!.id);
    expect(first.path, second.path);
    expect(File(first.path).existsSync(), isTrue);
    expect(isMediaId(first.id), isTrue);
    expect(first.id.length, 64);
    expect(first.id, first.id.toLowerCase());
  });

  test('the cache is immutable when an editor deletes its old display file', () async {
    final cached = await store.cacheBytes(tinyPng);
    expect(cached, isNotNull);

    await deleteStickerImage(cached!.path);

    expect(File(cached.path).existsSync(), isTrue);
    expect(MediaStore.isCachePath(cached.path), isTrue);
    expect(MediaStore.isCachePath('/tmp/sundial/stickers/one.png'), isFalse);
  });

  test('a display file outside the cache is still removable', () async {
    final display = await writePng(root, 'display.png', tinyPng);
    await deleteStickerImage(display.path);
    expect(display.existsSync(), isFalse);
  });

  test('non-PNG bytes are rejected', () async {
    expect(await store.cacheBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
    expect(await store.storeVerified(MediaStore.hashBytes([1, 2, 3]), Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('oversized images are rejected instead of truncated', () async {
    final oversized = Uint8List(MediaStore.maxBytes + 1)..setRange(0, 8, tinyPng);
    await expectLater(store.cacheBytes(oversized), throwsA(isA<MediaTooLargeException>()));
    await expectLater(
      store.storeVerified(MediaStore.hashBytes(oversized), oversized),
      throwsA(isA<MediaTooLargeException>()),
    );
  });

  test('a received image must match its content address', () async {
    final id = MediaStore.hashBytes(tinyPng);

    expect(await store.storeVerified('0' * 64, tinyPng), isNull);
    expect(await store.storeVerified(id, secondPng), isNull);
    expect(await store.contains(id), isFalse);

    final stored = await store.storeVerified(id, tinyPng);
    expect(stored, isNotNull);
    expect(await store.contains(id), isTrue);
    final blob = await store.readCached(id);
    expect(blob, isNotNull);
    expect(blob!.bytes, tinyPng);
  });

  test('a corrupt cache file is reported as missing', () async {
    final cached = await store.cacheBytes(tinyPng);
    await File(cached!.path).writeAsBytes([0, 1, 2, 3], flush: true);

    expect(await store.readCached(cached.id), isNull);
  });

  test('a display file is read into the same content-addressed cache', () async {
    final first = await writePng(root, 'one.png', tinyPng);
    final second = await writePng(root, 'two.png', tinyPng);

    final one = await store.cacheFromFile(first.path);
    final two = await store.cacheFromFile(second.path);

    expect(one, isNotNull);
    expect(two, isNotNull);
    expect(one!.id, two!.id);
    expect(File(one.path).existsSync(), isTrue);
    expect(await store.cacheFromFile('${root.path}/missing.png'), isNull);
  });
}

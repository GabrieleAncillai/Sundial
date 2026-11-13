import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mane/features/media/sticker_processor.dart';

Future<Uint8List> _encodeRedSquareOnWhite() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 8, 8), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  canvas.drawRect(const ui.Rect.fromLTWH(2, 2, 4, 4), ui.Paint()..color = const ui.Color(0xFFFF0000));
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildStickerPng returns a 512 square with a transparent corner and a white outline', () async {
    final source = await _encodeRedSquareOnWhite();
    final png = await buildStickerPng(sourceBytes: source);

    expect(png, isNotEmpty);

    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    addTearDown(image.dispose);
    addTearDown(codec.dispose);

    expect(image.width, stickerOutputSize);
    expect(image.height, stickerOutputSize);

    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    expect(data, isNotNull);
    final pixels = data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    int channel(int x, int y, int index) => pixels[(y * stickerOutputSize + x) * 4 + index];

    expect(channel(0, 0, 3), 0, reason: 'the corner background should become transparent');
    expect(channel(stickerOutputSize - 1, stickerOutputSize - 1, 3), 0);

    // The red square is opaque and still red in the centre.
    expect(channel(256, 256, 0), greaterThan(200));
    expect(channel(256, 256, 1), lessThan(80));
    expect(channel(256, 256, 2), lessThan(80));
    expect(channel(256, 256, 3), 255);

    // The removed background leaves the opaque white dilated ring as the only
    // white pixels left of the red square on the centre row.
    final whiteRing = <int>[
      for (var x = 0; x < stickerOutputSize ~/ 2; x++)
        if (channel(x, 256, 3) == 255 &&
            channel(x, 256, 0) > 240 &&
            channel(x, 256, 1) > 240 &&
            channel(x, 256, 2) > 240)
          x,
    ];
    expect(whiteRing, isNotEmpty, reason: 'a white outline should surround the red square');
  });
}

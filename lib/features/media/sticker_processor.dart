import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Edge length, in pixels, of the PNG produced by [buildStickerPng].
const int stickerOutputSize = 512;

/// Builds a square sticker PNG from [sourceBytes].
///
/// The source is centre-cropped to a square and scaled to [stickerOutputSize].
/// When [removeBackground] is true, the four corners seed a flood fill that
/// clears the background within [tolerance] (0 matches only the exact corner
/// colour). A white silhouette is then dilated by [outlineWidth] pixels and
/// composited behind the remaining pixels, keeping their original colours.
Future<Uint8List> buildStickerPng({
  required Uint8List sourceBytes,
  double tolerance = 0.12,
  int outlineWidth = 10,
  bool removeBackground = true,
}) async {
  final source = await decodeStickerImage(sourceBytes);
  ui.Image? square;
  ui.Image? result;
  try {
    square = await _renderSquare(source);
    final raw = await square.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (raw == null) {
      throw StateError('Could not read the sticker pixels.');
    }
    final pixels = Uint8List.fromList(raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes));
    _applyStickerLook(
      pixels,
      tolerance: tolerance,
      outlineWidth: outlineWidth,
      removeBackground: removeBackground,
    );
    result = await _imageFromStraightRgba(pixels, stickerOutputSize, stickerOutputSize);
    final encoded = await result.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null) {
      throw StateError('Could not encode the sticker.');
    }
    return encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes);
  } finally {
    result?.dispose();
    square?.dispose();
    source.dispose();
  }
}

/// Decodes encoded image [bytes] for preview or processing.
Future<ui.Image> decodeStickerImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

Future<ui.Image> _renderSquare(ui.Image source) async {
  final side = stickerOutputSize.toDouble();
  final cover = math.max(side / source.width, side / source.height);
  final sourceSide = side / cover;
  final sourceRect = ui.Rect.fromLTWH(
    (source.width - sourceSide) / 2,
    (source.height - sourceSide) / 2,
    sourceSide,
    sourceSide,
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    source,
    sourceRect,
    ui.Rect.fromLTWH(0, 0, side, side),
    ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(stickerOutputSize, stickerOutputSize);
  } finally {
    picture.dispose();
  }
}

void _applyStickerLook(
  Uint8List pixels, {
  required double tolerance,
  required int outlineWidth,
  required bool removeBackground,
}) {
  final width = stickerOutputSize;
  final height = stickerOutputSize;
  final count = width * height;
  final original = Uint8List.fromList(pixels);
  final corners = _cornerColors(original, width, height);
  final background = Uint8List(count);
  final clampedTolerance = tolerance.clamp(0.0, 1.0).toDouble();
  if (removeBackground) {
    _floodBackground(original, background, width, height, clampedTolerance, corners);
  }

  final alpha = Uint8List(count);
  for (var index = 0; index < count; index++) {
    alpha[index] = background[index] == 0 ? original[index * 4 + 3] : 0;
  }
  if (removeBackground) {
    _featherEdge(original, background, alpha, width, height, clampedTolerance, corners);
  }

  final foreground = Uint8List(count);
  var hasForeground = false;
  for (var index = 0; index < count; index++) {
    if (alpha[index] > 0) {
      foreground[index] = 1;
      hasForeground = true;
    }
  }

  final output = Uint8List(pixels.length);
  final radius = outlineWidth.clamp(0, stickerOutputSize);
  if (radius > 0 && hasForeground) {
    final distances = _distanceTransformSquared(foreground, width, height);
    final outer = radius + 0.5;
    final outerSquared = outer * outer;
    for (var index = 0; index < count; index++) {
      final offset = index * 4;
      if (foreground[index] != 0) {
        _compositeOverWhite(original, alpha[index], output, offset);
      } else if (distances[index] <= outerSquared) {
        final coverage = (outer - math.sqrt(distances[index].toDouble())).clamp(0.0, 1.0).toDouble();
        output[offset] = 255;
        output[offset + 1] = 255;
        output[offset + 2] = 255;
        output[offset + 3] = (255 * coverage).round();
      }
    }
  } else {
    for (var index = 0; index < count; index++) {
      final alphaValue = alpha[index];
      if (alphaValue == 0) continue;
      final offset = index * 4;
      output[offset] = original[offset];
      output[offset + 1] = original[offset + 1];
      output[offset + 2] = original[offset + 2];
      output[offset + 3] = alphaValue;
    }
  }
  pixels.setAll(0, output);
}

void _compositeOverWhite(Uint8List source, int alpha, Uint8List output, int offset) {
  final coverage = alpha / 255.0;
  final white = 255.0 * (1.0 - coverage);
  output[offset] = (source[offset] * coverage + white).round();
  output[offset + 1] = (source[offset + 1] * coverage + white).round();
  output[offset + 2] = (source[offset + 2] * coverage + white).round();
  output[offset + 3] = 255;
}

const double _featherBand = 0.08;

void _featherEdge(
  Uint8List pixels,
  Uint8List background,
  Uint8List alpha,
  int width,
  int height,
  double tolerance,
  List<int> corners,
) {
  final limit = tolerance + _featherBand;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      if (background[index] != 0 || alpha[index] == 0) continue;
      if (!_touchesBackground(background, width, height, x, y)) continue;
      final offset = index * 4;
      var closest = double.infinity;
      for (final corner in corners) {
        final distance = _colorDistanceSquared(
          pixels[offset],
          pixels[offset + 1],
          pixels[offset + 2],
          corner,
        );
        if (distance < closest) closest = distance;
      }
      final distance = math.sqrt(closest);
      if (distance >= limit) continue;
      final factor = ((distance - tolerance) / _featherBand).clamp(0.0, 1.0).toDouble();
      alpha[index] = (alpha[index].toDouble() * factor).round();
    }
  }
}

bool _touchesBackground(Uint8List background, int width, int height, int x, int y) {
  for (var deltaY = -1; deltaY <= 1; deltaY++) {
    final neighbourY = y + deltaY;
    if (neighbourY < 0 || neighbourY >= height) continue;
    for (var deltaX = -1; deltaX <= 1; deltaX++) {
      final neighbourX = x + deltaX;
      if (neighbourX < 0 || neighbourX >= width) continue;
      if (background[neighbourY * width + neighbourX] != 0) return true;
    }
  }
  return false;
}

void _floodBackground(
  Uint8List pixels,
  Uint8List background,
  int width,
  int height,
  double tolerance,
  List<int> corners,
) {
  final threshold = tolerance * tolerance;
  final queue = Int32List(width * height);
  var head = 0;
  var tail = 0;

  bool matches(int index) {
    final offset = index * 4;
    if (pixels[offset + 3] == 0) return true;
    for (final corner in corners) {
      final distance = _colorDistanceSquared(pixels[offset], pixels[offset + 1], pixels[offset + 2], corner);
      if (distance <= threshold) return true;
    }
    return false;
  }

  void seed(int index) {
    if (background[index] != 0 || !matches(index)) return;
    background[index] = 1;
    queue[tail++] = index;
  }

  for (var x = 0; x < width; x++) {
    seed(x);
    seed((height - 1) * width + x);
  }
  for (var y = 1; y < height - 1; y++) {
    seed(y * width);
    seed(y * width + width - 1);
  }

  while (head < tail) {
    final index = queue[head++];
    final x = index % width;
    final y = index ~/ width;
    if (x > 0) seed(index - 1);
    if (x + 1 < width) seed(index + 1);
    if (y > 0) seed(index - width);
    if (y + 1 < height) seed(index + width);
  }
}

List<int> _cornerColors(Uint8List pixels, int width, int height) {
  final colors = <int>[];
  void add(int x, int y) {
    final offset = (y * width + x) * 4;
    colors.add((pixels[offset] << 16) | (pixels[offset + 1] << 8) | pixels[offset + 2]);
  }

  add(0, 0);
  add(width - 1, 0);
  add(0, height - 1);
  add(width - 1, height - 1);
  return colors;
}

double _colorDistanceSquared(int red, int green, int blue, int packed) {
  final deltaRed = (red - ((packed >> 16) & 0xFF)) / 255.0;
  final deltaGreen = (green - ((packed >> 8) & 0xFF)) / 255.0;
  final deltaBlue = (blue - (packed & 0xFF)) / 255.0;
  return (deltaRed * deltaRed + deltaGreen * deltaGreen + deltaBlue * deltaBlue) / 3.0;
}

Int32List _distanceTransformSquared(Uint8List mask, int width, int height) {
  const infinity = 1 << 24;
  final grid = Int32List(width * height);
  for (var index = 0; index < grid.length; index++) {
    grid[index] = mask[index] == 0 ? infinity : 0;
  }
  final line = Int32List(math.max(width, height));
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      line[y] = grid[y * width + x];
    }
    final transformed = _distanceTransformLine(line, height);
    for (var y = 0; y < height; y++) {
      grid[y * width + x] = transformed[y];
    }
  }
  for (var y = 0; y < height; y++) {
    final start = y * width;
    for (var x = 0; x < width; x++) {
      line[x] = grid[start + x];
    }
    final transformed = _distanceTransformLine(line, width);
    for (var x = 0; x < width; x++) {
      grid[start + x] = transformed[x];
    }
  }
  return grid;
}

Int32List _distanceTransformLine(Int32List source, int length) {
  final result = Int32List(length);
  final parabola = Int32List(length);
  final boundary = Float64List(length + 1);
  var k = 0;
  parabola[0] = 0;
  boundary[0] = double.negativeInfinity;
  boundary[1] = double.infinity;
  for (var q = 1; q < length; q++) {
    double intersection;
    while (true) {
      final p = parabola[k];
      intersection = ((source[q] + q * q) - (source[p] + p * p)) / (2.0 * q - 2.0 * p);
      if (intersection <= boundary[k] && k > 0) {
        k--;
      } else {
        break;
      }
    }
    k++;
    parabola[k] = q;
    boundary[k] = intersection;
    boundary[k + 1] = double.infinity;
  }
  k = 0;
  for (var q = 0; q < length; q++) {
    while (boundary[k + 1] < q) {
      k++;
    }
    final p = parabola[k];
    final delta = q - p;
    result[q] = source[p] + delta * delta;
  }
  return result;
}

Future<ui.Image> _imageFromStraightRgba(Uint8List pixels, int width, int height) {
  final premultiplied = Uint8List(pixels.length);
  for (var index = 0; index < pixels.length; index += 4) {
    final alpha = pixels[index + 3];
    if (alpha == 0) continue;
    if (alpha == 255) {
      premultiplied[index] = pixels[index];
      premultiplied[index + 1] = pixels[index + 1];
      premultiplied[index + 2] = pixels[index + 2];
    } else {
      premultiplied[index] = (pixels[index] * alpha / 255).round();
      premultiplied[index + 1] = (pixels[index + 1] * alpha / 255).round();
      premultiplied[index + 2] = (pixels[index + 2] * alpha / 255).round();
    }
    premultiplied[index + 3] = alpha;
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(premultiplied, width, height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

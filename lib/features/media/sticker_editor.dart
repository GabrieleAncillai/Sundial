import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sticker_processor.dart';

export 'sticker_processor.dart';

/// Strings rendered by the sticker editor.
///
/// The feature deliberately takes these rather than importing the app's
/// generated localisations, so it can be dropped into any host app.
class StickerEditorLabels {
  const StickerEditorLabels({
    required this.title,
    required this.pickImage,
    required this.zoomHint,
    required this.tolerance,
    required this.outline,
    required this.outlineWidth,
    required this.reset,
    required this.cancel,
    required this.useImage,
    required this.noImage,
    required this.error,
  });

  final String title,
      pickImage,
      zoomHint,
      tolerance,
      outline,
      outlineWidth,
      reset,
      cancel,
      useImage,
      noImage,
      error;
}

/// Picks an image, lets the user crop/zoom it to a square, optionally removes
/// the corner background with a tolerance-controlled magic wand and adds a
/// white sticker outline. Returns encoded PNG bytes, or null when cancelled.
Future<Uint8List?> pickAndEditSticker(BuildContext context, StickerEditorLabels labels) async {
  final Uint8List? bytes;
  try {
    bytes = await _pickImageBytes();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(labels.error)));
    }
    return null;
  }
  if (bytes == null || !context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      fullscreenDialog: true,
      builder: (context) => StickerEditorPage(labels: labels, initialBytes: bytes),
    ),
  );
}

Future<Uint8List?> _pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes != null && bytes.isNotEmpty) return bytes;
  final path = file.path;
  if (path == null) throw StateError('The picked image has no bytes or path.');
  return File(path).readAsBytes();
}

/// Full-screen square cropper and sticker controls.
class StickerEditorPage extends StatefulWidget {
  const StickerEditorPage({super.key, required this.labels, this.initialBytes});

  final StickerEditorLabels labels;
  final Uint8List? initialBytes;

  @override
  State<StickerEditorPage> createState() => _StickerEditorPageState();
}

class _StickerEditorPageState extends State<StickerEditorPage> {
  final GlobalKey _previewKey = GlobalKey();
  ui.Image? _image;
  double _zoom = 1;
  Offset _pan = Offset.zero;
  double _tolerance = 0.12;
  bool _outline = true;
  double _outlineWidth = 10;
  bool _busy = false;
  String? _error;

  double _gestureStartZoom = 1;
  Offset _gestureStartPan = Offset.zero;
  Offset _gestureFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBytes;
    if (initial != null) unawaited(_loadImage(initial));
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage(Uint8List bytes) async {
    try {
      final image = await decodeStickerImage(bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      final previous = _image;
      setState(() {
        _image = image;
        _zoom = 1;
        _pan = Offset.zero;
        _error = null;
      });
      previous?.dispose();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.labels.error);
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    try {
      final bytes = await _pickImageBytes();
      if (bytes == null || !mounted) return;
      await _loadImage(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.labels.error);
    }
  }

  void _reset() {
    setState(() {
      _zoom = 1;
      _pan = Offset.zero;
      _tolerance = 0.12;
      _outline = true;
      _outlineWidth = 10;
      _error = null;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
    _gestureStartPan = _pan;
    _gestureFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double side) {
    final image = _image;
    if (image == null) return;
    final base = _baseScale(image, side);
    final zoom = (_gestureStartZoom * details.scale).clamp(1.0, 8.0).toDouble();
    final centre = Offset(side / 2, side / 2);
    final content = (_gestureFocal - centre - _gestureStartPan) / (base * _gestureStartZoom);
    final nextPan = details.localFocalPoint - centre - content * (base * zoom);
    setState(() {
      _zoom = zoom;
      _pan = _clampPan(nextPan, image, side, zoom);
    });
  }

  void _onPointerScroll(PointerScrollEvent event, double side) {
    final image = _image;
    if (image == null) return;
    final base = _baseScale(image, side);
    final factor = math.exp(-event.scrollDelta.dy / 400.0);
    final zoom = (_zoom * factor).clamp(1.0, 8.0).toDouble();
    if (zoom == _zoom) return;
    final centre = Offset(side / 2, side / 2);
    final content = (event.localPosition - centre - _pan) / (base * _zoom);
    final nextPan = event.localPosition - centre - content * (base * zoom);
    setState(() {
      _zoom = zoom;
      _pan = _clampPan(nextPan, image, side, zoom);
    });
  }

  Future<void> _useImage() async {
    final image = _image;
    if (image == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cropped = await _renderCropPng(image, _previewSide());
      final png = await buildStickerPng(
        sourceBytes: cropped,
        tolerance: _tolerance,
        outlineWidth: _outline ? _outlineWidth.round() : 0,
        removeBackground: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(png);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = widget.labels.error;
      });
    }
  }

  double _previewSide() {
    final renderObject = _previewKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize && renderObject.size.shortestSide > 0) {
      return renderObject.size.shortestSide;
    }
    return stickerOutputSize.toDouble();
  }

  Future<Uint8List> _renderCropPng(ui.Image image, double side) async {
    final safeSide = side > 0 ? side : stickerOutputSize.toDouble();
    final base = _baseScale(image, safeSide);
    final scale = base * _zoom;
    final sourceSide = safeSide / scale;
    final left = safeSide / 2 + _pan.dx - image.width * scale / 2;
    final top = safeSide / 2 + _pan.dy - image.height * scale / 2;
    final sourceLeft = (-left / scale).clamp(0.0, image.width - sourceSide).toDouble();
    final sourceTop = (-top / scale).clamp(0.0, image.height - sourceSide).toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(sourceLeft, sourceTop, sourceSide, sourceSide),
      ui.Rect.fromLTWH(0, 0, stickerOutputSize.toDouble(), stickerOutputSize.toDouble()),
      ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    try {
      final cropped = await picture.toImage(stickerOutputSize, stickerOutputSize);
      try {
        final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Could not crop the sticker.');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        cropped.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: widget.labels.cancel,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(widget.labels.title),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = math.max(120.0, constraints.maxWidth - 32);
            final availableHeight = math.max(120.0, constraints.maxHeight * 0.5);
            final side = math.min(math.min(availableWidth, availableHeight), 420.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _buildPreview(theme, side)),
                  if (_image != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(widget.labels.pickImage),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.labels.zoomHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  if (_error != null) ...[const SizedBox(height: 12), _ErrorNotice(message: _error!)],
                  const SizedBox(height: 16),
                  _LabeledSlider(
                    label: widget.labels.tolerance,
                    valueText: '${(_tolerance * 100).round()}%',
                    value: _tolerance,
                    min: 0,
                    max: 0.5,
                    divisions: 50,
                    onChanged: _busy ? null : (value) => setState(() => _tolerance = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(widget.labels.outline),
                    value: _outline,
                    onChanged: _busy ? null : (value) => setState(() => _outline = value),
                  ),
                  if (_outline)
                    _LabeledSlider(
                      label: widget.labels.outlineWidth,
                      valueText: _outlineWidth.round().toString(),
                      value: _outlineWidth,
                      min: 0,
                      max: 24,
                      divisions: 24,
                      onChanged: _busy ? null : (value) => setState(() => _outlineWidth = value),
                    ),
                  if (_busy) ...[const SizedBox(height: 8), const LinearProgressIndicator()],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(onPressed: _busy ? null : _reset, child: Text(widget.labels.reset)),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                        child: Text(widget.labels.cancel),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _image != null && !_busy ? _useImage : null,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.labels.useImage),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, double side) {
    final image = _image;
    final radius = BorderRadius.circular(18);
    return SizedBox(
      key: _previewKey,
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: image == null
              ? _EmptyPreview(labels: widget.labels, busy: _busy, onPick: _pickImage)
              : Listener(
                  onPointerSignal: (event) {
                    if (event is! PointerScrollEvent) return;
                    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
                      _onPointerScroll(event as PointerScrollEvent, side);
                    });
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (details) => _onScaleUpdate(details, side),
                    child: CustomPaint(
                      painter: _StickerCropPainter(image: image, zoom: _zoom, pan: _pan),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

double _baseScale(ui.Image image, double side) => math.max(side / image.width, side / image.height);

Offset _clampPan(Offset pan, ui.Image image, double side, double zoom) {
  final scale = _baseScale(image, side) * zoom;
  final maxX = math.max(0.0, (image.width * scale - side) / 2);
  final maxY = math.max(0.0, (image.height * scale - side) / 2);
  return Offset(pan.dx.clamp(-maxX, maxX).toDouble(), pan.dy.clamp(-maxY, maxY).toDouble());
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.labels, required this.busy, required this.onPick});

  final StickerEditorLabels labels;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(labels.noImage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(labels.pickImage),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            Text(
              valueText,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StickerCropPainter extends CustomPainter {
  _StickerCropPainter({required this.image, required this.zoom, required this.pan});

  final ui.Image image;
  final double zoom;
  final Offset pan;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    final base = _baseScale(image, side);
    final scale = base * zoom;
    final sourceSide = side / scale;
    final left = side / 2 + pan.dx - image.width * scale / 2;
    final top = side / 2 + pan.dy - image.height * scale / 2;
    final sourceLeft = (-left / scale).clamp(0.0, image.width - sourceSide).toDouble();
    final sourceTop = (-top / scale).clamp(0.0, image.height - sourceSide).toDouble();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(sourceLeft, sourceTop, sourceSide, sourceSide),
      Offset.zero & Size.square(side),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _StickerCropPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.zoom != zoom || oldDelegate.pan != pan;
}

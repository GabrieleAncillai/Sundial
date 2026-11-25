import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Regenerates every interaction cue in both packs.
///
/// The cues are original, procedurally synthesised WAV files. Running this
/// script writes `assets/sounds/<pack>/<cue>.wav` and the matching Android
/// `res/raw/sundial_<pack>_<cue>.wav`, so the two never drift apart.
///
/// Keep the names in `_cues` in sync with `UiSound` in
/// `lib/core/sound/sound_service.dart`. `test/sound_assets_test.dart` fails if
/// a cue is missing from a pack or from Android.
void main() {
  final root = _projectRoot();
  for (final pack in _packs) {
    final assetDirectory = Directory('${root.path}/assets/sounds/${pack.name}')..createSync(recursive: true);
    final rawDirectory = Directory('${root.path}/android/app/src/main/res/raw')..createSync(recursive: true);
    for (final cue in _cues) {
      final bytes = _wav(_render(cue, pack));
      File('${assetDirectory.path}/$cue.wav').writeAsBytesSync(bytes, flush: true);
      File('${rawDirectory.path}/sundial_${pack.name}_$cue.wav').writeAsBytesSync(bytes, flush: true);
    }
    stdout.writeln('${pack.name}: ${_cues.length} cues at ${pack.rate} Hz');
  }
}

const _cues = <String>[
  'tap',
  'nav',
  'open',
  'back',
  'select',
  'toggle_on',
  'toggle_off',
  'complete',
  'uncomplete',
  'check',
  'uncheck',
  'confirm',
  'remove',
  'start',
  'pause',
  'finish',
  'error',
];

const _packs = <_Pack>[
  _Pack(name: 'aero', rate: 44100, peak: 0.55, bright: true),
  _Pack(name: 'soft', rate: 22050, peak: 0.18, bright: false),
];

class _Pack {
  const _Pack({required this.name, required this.rate, required this.peak, required this.bright});

  final String name;
  final int rate;
  final double peak;
  final bool bright;
}

Directory _projectRoot() {
  var directory = Directory.current;
  while (!File('${directory.path}/pubspec.yaml').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Run this script from inside the Sundial project.');
    }
    directory = parent;
  }
  return directory;
}

// A4, and the notes used by the cue motifs.
const _a3 = 220.0;
const _f3 = 174.61;
const _a4 = 440.0;
const _c5 = 523.25;
const _e5 = 659.25;
const _g5 = 783.99;
const _a5 = 880.0;
const _c6 = 1046.50;
const _d6 = 1174.66;
const _e6 = 1318.51;
const _g6 = 1567.98;

class _Buffer {
  _Buffer(this.rate, int milliseconds) : samples = Float64List((rate * milliseconds / 1000).ceil());

  final int rate;
  final Float64List samples;
}

_Buffer _render(String cue, _Pack pack) {
  final buffer = _Buffer(pack.rate, _lengthMs(cue));
  final partials = pack.bright ? const <double>[1, 2.01, 3.02, 4.98] : const <double>[1, 2];
  final partialWeights = pack.bright ? const <double>[1, 0.30, 0.13, 0.05] : const <double>[1, 0.085];

  void note(
    double at,
    double frequency,
    double duration,
    double amplitude, {
    double? endFrequency,
    double attack = 0.003,
    double decay = 0.1,
  }) {
    _tone(
      buffer,
      at: at,
      duration: duration,
      frequency: frequency,
      endFrequency: endFrequency,
      amplitude: amplitude,
      partials: partials,
      partialAmplitudes: partialWeights,
      attack: attack,
      decay: decay,
    );
  }

  void body(
    double at,
    double frequency,
    double duration,
    double amplitude, {
    double attack = 0.002,
    double decay = 0.04,
  }) {
    _tone(
      buffer,
      at: at,
      duration: duration,
      frequency: frequency,
      amplitude: amplitude,
      attack: attack,
      decay: decay,
    );
  }

  void air(double at, double duration, double amplitude, {double smoothing = 0.25, int seed = 7}) {
    _noise(
      buffer,
      at: at,
      duration: duration,
      amplitude: amplitude * (pack.bright ? 1 : 0.35),
      smoothing: smoothing,
      seed: seed,
    );
  }

  switch (cue) {
    case 'tap':
      note(0, 1800, 0.048, 0.50, attack: 0.0012, decay: 0.011);
      body(0, 380, 0.06, 0.26, decay: 0.02);
      air(0, 0.012, 0.18, smoothing: 0.55, seed: 11);
    case 'nav':
      note(0, _e5, 0.055, 0.38, decay: 0.03);
      note(0.045, _a5, 0.10, 0.34, decay: 0.055);
      note(0.09, 2600, 0.028, 0.08, decay: 0.012);
      air(0.04, 0.03, 0.07, smoothing: 0.3, seed: 12);
    case 'open':
      note(0, 330, 0.17, 0.32, endFrequency: 880, attack: 0.012, decay: 0.2);
      note(0.12, _c6, 0.08, 0.22, decay: 0.06);
      air(0, 0.16, 0.12, smoothing: 0.1, seed: 13);
    case 'back':
      note(0, 760, 0.13, 0.34, endFrequency: 320, attack: 0.006, decay: 0.16);
      body(0.02, 240, 0.12, 0.16, decay: 0.06);
      air(0, 0.12, 0.08, smoothing: 0.25, seed: 14);
    case 'select':
      note(0, 2400, 0.038, 0.36, attack: 0.001, decay: 0.009);
      air(0, 0.01, 0.10, smoothing: 0.5, seed: 15);
    case 'toggle_on':
      note(0, _g5, 0.05, 0.34, decay: 0.03);
      note(0.04, _d6, 0.10, 0.32, decay: 0.06);
      air(0.035, 0.03, 0.06, smoothing: 0.3, seed: 16);
    case 'toggle_off':
      note(0, _d6, 0.045, 0.30, decay: 0.025);
      note(0.06, _g5, 0.09, 0.28, decay: 0.055);
      body(0, 196, 0.1, 0.14, decay: 0.05);
    case 'complete':
      body(0, 262, 0.12, 0.20, decay: 0.09);
      note(0, _c5, 0.09, 0.34, decay: 0.06);
      note(0.07, _g5, 0.12, 0.33, decay: 0.08);
      note(0.15, _c6, 0.22, 0.36, decay: 0.14);
      note(0.17, _e6, 0.16, 0.10, decay: 0.1);
      air(0.14, 0.08, 0.05, smoothing: 0.2, seed: 17);
    case 'uncomplete':
      note(0, _g5, 0.06, 0.30, decay: 0.035);
      note(0.05, _e5, 0.08, 0.26, decay: 0.05);
      note(0.11, _c5, 0.14, 0.24, decay: 0.08);
      air(0, 0.08, 0.05, smoothing: 0.2, seed: 18);
    case 'check':
      note(0, _a5, 0.038, 0.32, attack: 0.001, decay: 0.012);
      note(0.025, _e6, 0.05, 0.22, decay: 0.02);
      air(0, 0.014, 0.08, smoothing: 0.55, seed: 19);
    case 'uncheck':
      note(0, _a5, 0.04, 0.24, decay: 0.015);
      note(0.03, _e5, 0.06, 0.18, decay: 0.025);
      air(0, 0.012, 0.04, smoothing: 0.55, seed: 20);
    case 'confirm':
      note(0, _e5, 0.06, 0.34, decay: 0.04);
      note(0.05, _a5, 0.13, 0.32, decay: 0.08);
      body(0, 220, 0.1, 0.14, decay: 0.06);
    case 'remove':
      body(0, 300, 0.09, 0.38, attack: 0.003, decay: 0.04);
      body(0.06, 200, 0.14, 0.30, attack: 0.003, decay: 0.07);
      body(0.02, 110, 0.12, 0.16, decay: 0.06);
      air(0, 0.05, 0.06, smoothing: 0.4, seed: 22);
    case 'start':
      note(0, _a4, 0.045, 0.36, attack: 0.002, decay: 0.025);
      note(0.07, _a4, 0.04, 0.24, decay: 0.02);
      note(0.12, _e5, 0.12, 0.32, decay: 0.07);
    case 'pause':
      note(0, _a4, 0.055, 0.32, decay: 0.04);
      body(0.01, 220, 0.1, 0.22, decay: 0.06);
      air(0, 0.04, 0.04, smoothing: 0.35, seed: 23);
    case 'finish':
      note(0, _c5, 0.06, 0.34, decay: 0.04);
      note(0.055, _e5, 0.06, 0.32, decay: 0.04);
      note(0.11, _g5, 0.07, 0.32, decay: 0.05);
      note(0.17, _c6, 0.21, 0.36, decay: 0.14);
      note(0.19, _g6, 0.12, 0.10, decay: 0.09);
    case 'error':
      note(0, _a3, 0.11, 0.34, attack: 0.006, decay: 0.09);
      note(0.09, _f3, 0.17, 0.30, attack: 0.006, decay: 0.12);
      body(0, 110, 0.14, 0.16, decay: 0.08);
      air(0, 0.06, 0.03, smoothing: 0.35, seed: 21);
    default:
      throw ArgumentError('Unknown cue: $cue');
  }

  if (pack.bright) {
    _echo(buffer, delaySeconds: 0.028, gain: 0.16);
    _lowPass(buffer, 14000);
  } else {
    _echo(buffer, delaySeconds: 0.018, gain: 0.07);
    _lowPass(buffer, 4800);
  }
  _edgeFade(buffer);
  _normalize(buffer, pack.peak);
  return buffer;
}

int _lengthMs(String cue) => switch (cue) {
  'tap' => 70,
  'nav' => 170,
  'open' => 230,
  'back' => 180,
  'select' => 60,
  'toggle_on' || 'toggle_off' => 160,
  'complete' => 430,
  'uncomplete' => 300,
  'check' => 110,
  'uncheck' => 120,
  'confirm' => 240,
  'remove' => 320,
  'start' => 300,
  'pause' => 190,
  'finish' => 440,
  'error' => 340,
  _ => throw ArgumentError('Unknown cue: $cue'),
};

void _tone(
  _Buffer buffer, {
  required double at,
  required double duration,
  required double frequency,
  required double amplitude,
  double? endFrequency,
  List<double> partials = const <double>[1],
  List<double> partialAmplitudes = const <double>[1],
  double attack = 0.003,
  double decay = 0.1,
}) {
  final start = (at * buffer.rate).round();
  final length = (duration * buffer.rate).round();
  final phases = List<double>.filled(partials.length, 0);
  final target = endFrequency ?? frequency;
  for (var i = 0; i < length; i++) {
    final index = start + i;
    if (index < 0 || index >= buffer.samples.length) continue;
    final t = i / buffer.rate;
    final frequencyNow = frequency + (target - frequency) * (t / duration);
    var sample = 0.0;
    for (var p = 0; p < partials.length; p++) {
      phases[p] += 2 * math.pi * frequencyNow * partials[p] / buffer.rate;
      sample += partialAmplitudes[p] * math.sin(phases[p]);
    }
    final remaining = duration - t;
    final release = math.min(0.008, duration);
    final envelope =
        _attack(t, attack) * math.exp(-t / decay) * (remaining < release ? remaining / release : 1);
    buffer.samples[index] += amplitude * envelope * sample;
  }
}

void _noise(
  _Buffer buffer, {
  required double at,
  required double duration,
  required double amplitude,
  double smoothing = 0.25,
  int seed = 1,
}) {
  final start = (at * buffer.rate).round();
  final length = (duration * buffer.rate).round();
  final random = math.Random(seed);
  var filtered = 0.0;
  for (var i = 0; i < length; i++) {
    final index = start + i;
    if (index < 0 || index >= buffer.samples.length) continue;
    final t = i / buffer.rate;
    final white = random.nextDouble() * 2 - 1;
    filtered += smoothing * (white - filtered);
    final remaining = duration - t;
    final release = math.min(0.006, duration);
    final envelope =
        _attack(t, 0.0015) *
        math.exp(-t / (duration * 0.45)) *
        (remaining < release ? remaining / release : 1);
    // A one-pole filter loses roughly this much energy; scale it back so the
    // air detail stays audible after normalisation.
    buffer.samples[index] += amplitude * envelope * filtered * 2.4;
  }
}

double _attack(double t, double attack) => attack <= 0 ? 1 : 1 - math.exp(-t / attack);

void _echo(_Buffer buffer, {required double delaySeconds, required double gain}) {
  final delay = (delaySeconds * buffer.rate).round();
  if (delay <= 0 || delay >= buffer.samples.length) return;
  for (var i = delay; i < buffer.samples.length; i++) {
    buffer.samples[i] += gain * buffer.samples[i - delay];
  }
}

void _lowPass(_Buffer buffer, double cutoff) {
  final alpha = 1 - math.exp(-2 * math.pi * cutoff / buffer.rate);
  var previous = 0.0;
  for (var i = 0; i < buffer.samples.length; i++) {
    previous += alpha * (buffer.samples[i] - previous);
    buffer.samples[i] = previous;
  }
}

void _edgeFade(_Buffer buffer) {
  final fade = math.min((0.0015 * buffer.rate).round(), buffer.samples.length ~/ 2);
  for (var i = 0; i < fade; i++) {
    buffer.samples[i] *= i / fade;
    buffer.samples[buffer.samples.length - 1 - i] *= i / fade;
  }
}

void _normalize(_Buffer buffer, double peak) {
  var loudest = 0.0;
  for (final sample in buffer.samples) {
    final value = sample.abs();
    if (value > loudest) loudest = value;
  }
  if (loudest == 0) return;
  final gain = peak / loudest;
  for (var i = 0; i < buffer.samples.length; i++) {
    buffer.samples[i] *= gain;
  }
}

Uint8List _wav(_Buffer buffer) {
  final data = ByteData(buffer.samples.length * 2);
  for (var i = 0; i < buffer.samples.length; i++) {
    final sample = (buffer.samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(i * 2, sample, Endian.little);
  }
  final dataLength = data.lengthInBytes;

  final header = ByteData(44);
  _ascii(header, 0, 'RIFF');
  header.setUint32(4, 36 + dataLength, Endian.little);
  _ascii(header, 8, 'WAVE');
  _ascii(header, 12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, buffer.rate, Endian.little);
  header.setUint32(28, buffer.rate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  _ascii(header, 36, 'data');
  header.setUint32(40, dataLength, Endian.little);

  final builder = BytesBuilder(copy: false)
    ..add(header.buffer.asUint8List())
    ..add(data.buffer.asUint8List());
  return builder.toBytes();
}

void _ascii(ByteData data, int offset, String value) {
  for (var i = 0; i < value.length; i++) {
    data.setUint8(offset + i, value.codeUnitAt(i));
  }
}

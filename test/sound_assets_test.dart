import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/sound/sound_service.dart';
import 'package:sundial/models/app_settings.dart';

void main() {
  test('every cue ships in every pack and in the Android raw resources', () {
    for (final pack in SundialSoundPack.values) {
      for (final sound in UiSound.values) {
        final asset = File(SoundController.assetFor(sound, pack));
        expect(asset.existsSync(), isTrue, reason: 'missing ${asset.path}');
        final raw = File('android/app/src/main/res/raw/sundial_${pack.name}_${sound.file}.wav');
        expect(raw.existsSync(), isTrue, reason: 'missing ${raw.path}');
      }
    }
  });

  test('cue assets are valid, short PCM wav files', () {
    for (final pack in SundialSoundPack.values) {
      for (final sound in UiSound.values) {
        final path = SoundController.assetFor(sound, pack);
        final bytes = File(path).readAsBytesSync();
        expect(bytes.length, greaterThan(44), reason: path);
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: path);
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: path);

        final data = ByteData.sublistView(bytes);
        final rate = data.getUint32(24, Endian.little);
        final bits = data.getUint16(34, Endian.little);
        final channels = data.getUint16(22, Endian.little);
        final dataLength = data.getUint32(40, Endian.little);
        expect(bits, 16, reason: path);
        expect(channels, 1, reason: path);
        expect(dataLength, bytes.length - 44, reason: path);

        final seconds = dataLength / (rate * 2);
        expect(seconds, lessThan(0.5), reason: '$path is too long');
        expect(seconds, greaterThan(0.02), reason: '$path is too short');

        var peak = 0;
        for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
          final sample = data.getInt16(offset, Endian.little).abs();
          if (sample > peak) peak = sample;
        }
        expect(peak, greaterThan(3000), reason: '$path is silent');
      }
    }
  });

  test('cue file names are unique', () {
    final names = UiSound.values.map((sound) => sound.file).toSet();
    expect(names, hasLength(UiSound.values.length));
  });

  test('the generator knows every cue', () {
    final source = File('tool/generate_sounds.dart').readAsStringSync();
    for (final sound in UiSound.values) {
      expect(
        source.contains("'${sound.file}'"),
        isTrue,
        reason: '${sound.file} is missing from tool/generate_sounds.dart',
      );
    }
  });
}

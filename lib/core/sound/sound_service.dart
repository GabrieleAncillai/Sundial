import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/app_settings.dart';
import '../../state/settings_controller.dart';

/// Short feedback blips tied to user actions.
enum UiSound {
  tap('tap'),
  toggleOn('toggle_on'),
  toggleOff('toggle_off'),
  confirm('confirm'),
  back('back'),
  error('error');

  const UiSound(this.file);

  /// Snake-case name shared by the asset path and the Android raw resource.
  final String file;
}

/// Plays optional interaction sounds and alarm previews.
///
/// Android delegates to a SoundPool bridge so no new plugin is needed. Linux
/// shells out to `aplay` with a cached copy of the bundled asset. Every other
/// platform, and every failure path, uses Flutter's system sounds.
class SoundController {
  SoundController(this._ref);

  final Ref _ref;

  static const MethodChannel _androidChannel = MethodChannel('sundial/sound');
  static const String _assetRoot = 'assets/sounds';

  final Map<String, String> _cachedPaths = <String, String>{};
  final Map<String, Future<String?>> _pendingPaths = <String, Future<String?>>{};
  bool _linuxAudioDisabled = false;
  bool _androidChannelDisabled = false;

  /// Returns immediately when sounds are off. [force] is for explicit previews.
  void play(UiSound sound, {bool force = false}) {
    final settings = _readSettings();
    if (settings == null) return;
    if (!force && !settings.soundsEnabled) return;

    final fallback = sound == UiSound.error ? SystemSoundType.alert : SystemSoundType.click;
    final pack = settings.soundPack.name;
    unawaited(
      _dispatch(
        '$_assetRoot/$pack/${sound.file}.wav',
        fallback: fallback,
        androidArgs: <String, String>{'file': sound.file, 'pack': pack},
      ),
    );
  }

  /// Plays the selected alarm sample regardless of the interaction-sound switch.
  void previewAlarm(SundialAlarmSound sound) {
    unawaited(
      _dispatch(
        '$_assetRoot/alarm_${sound.name}.wav',
        fallback: SystemSoundType.alert,
        androidArgs: <String, String>{'alarm': sound.name},
      ),
    );
  }

  /// Forgets cached Linux file paths. The temporary files are left for the OS.
  void dispose() {
    _cachedPaths.clear();
    _pendingPaths.clear();
  }

  AppSettings? _readSettings() {
    try {
      return _ref.read(settingsProvider);
    } catch (error) {
      debugPrint('Sound settings unavailable: $error');
      return null;
    }
  }

  Future<void> _dispatch(
    String asset, {
    required SystemSoundType fallback,
    required Map<String, String> androidArgs,
  }) async {
    try {
      if (kIsWeb) {
        await SystemSound.play(fallback);
        return;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          if (await _playAndroid(androidArgs)) return;
          await SystemSound.play(fallback);
        case TargetPlatform.linux:
          if (await _playLinux(asset)) return;
          await SystemSound.play(fallback);
        default:
          await SystemSound.play(fallback);
      }
    } catch (error) {
      debugPrint('Sound playback failed: $error');
    }
  }

  Future<bool> _playAndroid(Map<String, String> arguments) async {
    if (_androidChannelDisabled) return false;
    try {
      final played = await _androidChannel.invokeMethod<bool>('play', arguments);
      return played ?? false;
    } on MissingPluginException {
      _androidChannelDisabled = true;
      debugPrint('Sound channel unavailable; using system sounds.');
      return false;
    } catch (error) {
      debugPrint('Android sound failed: $error');
      return false;
    }
  }

  Future<bool> _playLinux(String asset) async {
    if (_linuxAudioDisabled) return false;
    try {
      final path = await _cachedAssetPath(asset);
      if (path == null) {
        _linuxAudioDisabled = true;
        return false;
      }
      final result = await Process.run('aplay', <String>['-q', path]);
      if (result.exitCode == 0) return true;
      _linuxAudioDisabled = true;
      debugPrint('aplay exited with ${result.exitCode}; disabling Linux sounds.');
      return false;
    } on ProcessException {
      _linuxAudioDisabled = true;
      debugPrint('aplay is not available; disabling Linux sounds.');
      return false;
    } catch (error) {
      _linuxAudioDisabled = true;
      debugPrint('Linux sound failed: $error');
      return false;
    }
  }

  Future<String?> _cachedAssetPath(String asset) {
    final cached = _cachedPaths[asset];
    if (cached != null) return Future<String?>.value(cached);
    return _pendingPaths.putIfAbsent(
      asset,
      () => _materialize(asset).whenComplete(() => _pendingPaths.remove(asset)),
    );
  }

  Future<String?> _materialize(String asset) async {
    try {
      final directory = await getTemporaryDirectory();
      final soundsDirectory = Directory(p.join(directory.path, 'sundial_sounds'));
      if (!await soundsDirectory.exists()) {
        await soundsDirectory.create(recursive: true);
      }
      // Keep the pack in the file name so aero and soft never collide.
      final file = File(p.join(soundsDirectory.path, asset.replaceAll('/', '_')));
      if (!await file.exists()) {
        final data = await rootBundle.load(asset);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      _cachedPaths[asset] = file.path;
      return file.path;
    } catch (error) {
      debugPrint('Sound asset unavailable: $error');
      return null;
    }
  }
}

final soundControllerProvider = Provider<SoundController>((ref) {
  final controller = SoundController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

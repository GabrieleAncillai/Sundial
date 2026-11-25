import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/app_settings.dart';
import '../../state/settings_controller.dart';

/// Semantic feedback cues tied to user actions.
///
/// The names are the asset file names and the Android raw-resource suffixes.
/// Keep them in sync with `tool/generate_sounds.dart`.
enum UiSound {
  /// A generic press on a small control.
  tap('tap'),

  /// Switching a shell destination.
  nav('nav'),

  /// A sheet or editor opens.
  open('open'),

  /// A sheet, page or editor closes.
  back('back'),

  /// Choosing one option in a segmented control.
  select('select'),

  toggleOn('toggle_on'),
  toggleOff('toggle_off'),

  /// A task or habit is completed.
  complete('complete'),

  /// A completed task is reopened.
  uncomplete('uncomplete'),

  /// A checklist item or shopping line is ticked.
  check('check'),

  /// A checklist item or shopping line is unticked.
  uncheck('uncheck'),

  /// A save, import or other successful write.
  confirm('confirm'),

  /// A delete or archive.
  remove('remove'),

  /// A timer starts, pauses or finishes.
  start('start'),
  pause('pause'),
  finish('finish'),

  error('error');

  const UiSound(this.file);

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
  final Map<UiSound, DateTime> _lastPlayed = <UiSound, DateTime>{};
  bool _linuxAudioDisabled = false;
  bool _androidChannelDisabled = false;

  /// The bundled path for [sound] in [pack], shared with the asset tests.
  static String assetFor(UiSound sound, SundialSoundPack pack) =>
      '$_assetRoot/${pack.name}/${sound.file}.wav';

  /// Plays a cue. Repeated identical cues within 35 ms are dropped so a nested
  /// tap target cannot double-fire. [force] is for explicit previews and for
  /// the switch that turns sounds on.
  void play(UiSound sound, {bool force = false}) {
    final settings = _readSettings();
    if (settings == null) return;
    if (!force && !settings.soundsEnabled) return;

    final now = DateTime.now();
    final last = _lastPlayed[sound];
    if (!force && last != null && now.difference(last) < const Duration(milliseconds: 35)) return;
    _lastPlayed[sound] = now;

    final fallback = sound == UiSound.error ? SystemSoundType.alert : SystemSoundType.click;
    unawaited(
      _dispatch(
        assetFor(sound, settings.soundPack),
        fallback: fallback,
        androidArgs: <String, String>{'file': sound.file, 'pack': settings.soundPack.name},
      ),
    );
  }

  /// Loads the selected pack ahead of the first interaction so it does not
  /// arrive late. Called on startup and when the pack or switch changes.
  void preload() {
    final settings = _readSettings();
    if (settings == null || !settings.soundsEnabled) return;
    unawaited(_preloadPack(settings.soundPack));
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
    _lastPlayed.clear();
  }

  AppSettings? _readSettings() {
    try {
      return _ref.read(settingsProvider);
    } catch (error) {
      debugPrint('Sound settings unavailable: $error');
      return null;
    }
  }

  Future<void> _preloadPack(SundialSoundPack pack) async {
    try {
      if (kIsWeb) return;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await _preloadAndroid(pack);
        case TargetPlatform.linux:
          await Future.wait<String?>([
            for (final sound in UiSound.values) _cachedAssetPath(assetFor(sound, pack)),
          ]);
        default:
          return;
      }
    } catch (error) {
      debugPrint('Sound preload failed: $error');
    }
  }

  Future<void> _preloadAndroid(SundialSoundPack pack) async {
    if (_androidChannelDisabled) return;
    try {
      await _androidChannel.invokeMethod<int>('preload', <String, Object>{
        'pack': pack.name,
        'files': <String>[for (final sound in UiSound.values) sound.file],
      });
    } on MissingPluginException {
      _androidChannelDisabled = true;
      debugPrint('Sound channel unavailable; using system sounds.');
    } catch (error) {
      debugPrint('Android sound preload failed: $error');
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
      // Keep the pack in the file name so aero and soft never collide. Rewrite
      // on every session: the temporary directory survives app updates, and a
      // stale copy would otherwise keep playing the previous cue.
      final file = File(p.join(soundsDirectory.path, asset.replaceAll('/', '_')));
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
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

/// Plays a cue from a widget that is not a [ConsumerState].
///
/// Widget tests and the first frames before `ProviderScope` settles have no
/// scope; those calls are intentionally silent rather than throwing.
void playUiSound(BuildContext context, UiSound sound, {bool force = false}) {
  try {
    ProviderScope.containerOf(context, listen: false).read(soundControllerProvider).play(sound, force: force);
  } catch (_) {
    // No ProviderScope in scope: this is a test-only or early-lifecycle frame.
  }
}

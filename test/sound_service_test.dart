import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/sound/sound_service.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/state/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('sundial/sound');
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return call.method == 'preload' ? UiSound.values.length : true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  ProviderContainer containerWith(AppSettings settings) {
    final container = ProviderContainer(overrides: [initialSettingsProvider.overrideWithValue(settings)]);
    addTearDown(container.dispose);
    return container;
  }

  test('dispatch uses the selected pack and cue file', () async {
    final container = containerWith(const AppSettings(soundsEnabled: true, soundPack: SundialSoundPack.soft));
    container.read(soundControllerProvider).play(UiSound.complete);
    await pumpEventQueue();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'play');
    expect(calls.single.arguments, <String, String>{'file': 'complete', 'pack': 'soft'});
  });

  test('sounds stay silent while disabled and force previews them', () async {
    final container = containerWith(const AppSettings());
    final sounds = container.read(soundControllerProvider);

    sounds.play(UiSound.tap);
    await pumpEventQueue();
    expect(calls, isEmpty);

    sounds.play(UiSound.tap, force: true);
    await pumpEventQueue();
    expect(calls, hasLength(1));
    expect(calls.single.arguments, <String, String>{'file': 'tap', 'pack': 'aero'});
  });

  test('repeated identical cues are coalesced', () async {
    final container = containerWith(const AppSettings(soundsEnabled: true));
    final sounds = container.read(soundControllerProvider);

    sounds.play(UiSound.check);
    sounds.play(UiSound.check);
    await pumpEventQueue();
    expect(calls, hasLength(1));

    await Future<void>.delayed(const Duration(milliseconds: 50));
    sounds.play(UiSound.check);
    await pumpEventQueue();
    expect(calls, hasLength(2));
  });

  test('preload sends every cue in the selected pack', () async {
    final container = containerWith(const AppSettings(soundsEnabled: true, soundPack: SundialSoundPack.soft));
    container.read(soundControllerProvider).preload();
    await pumpEventQueue();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'preload');
    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments['pack'], 'soft');
    expect((arguments['files']! as List<Object?>).length, UiSound.values.length);
  });
}

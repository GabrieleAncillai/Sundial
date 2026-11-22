import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/window/window_chrome.dart';
import 'package:sundial/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps the resolved palette and brightness for the runner', () {
    final payload = WindowChrome.payloadFor(SundialColors.dark, Brightness.dark);

    expect(payload['dark'], isTrue);
    expect(payload['pageBg'], SundialColors.dark.pageBg.toARGB32());
    expect(payload['surfaceHigh'], SundialColors.dark.surfaceHigh.toARGB32());
    expect(payload['border'], SundialColors.dark.border.toARGB32());
    expect(payload['text'], SundialColors.dark.text.toARGB32());
    expect(payload['textSecondary'], SundialColors.dark.textSecondary.toARGB32());
    expect(payload['danger'], SundialColors.dark.danger.toARGB32());
    expect(payload['dangerSoft'], SundialColors.dark.dangerSoft.toARGB32());
  });

  testWidgets('sends the palette once and again when the theme changes', (tester) async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel(WindowChrome.channelName);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    WindowChrome.debugResetCache();

    try {
      await tester.pumpWidget(
        const WindowChromeSync(colors: SundialColors.dark, brightness: Brightness.dark, child: SizedBox()),
      );
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'apply');
      final darkArgs = calls.single.arguments as Map<Object?, Object?>;
      expect(darkArgs['dark'], isTrue);
      expect(darkArgs['pageBg'], SundialColors.dark.pageBg.toARGB32());

      await tester.pumpWidget(
        const WindowChromeSync(colors: SundialColors.light, brightness: Brightness.light, child: SizedBox()),
      );
      await tester.pump();

      expect(calls, hasLength(2));
      final lightArgs = calls.last.arguments as Map<Object?, Object?>;
      expect(lightArgs['dark'], isFalse);
      expect(lightArgs['pageBg'], SundialColors.light.pageBg.toARGB32());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

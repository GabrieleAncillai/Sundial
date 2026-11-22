import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Keeps the Linux window frame in step with the app theme.
///
/// GTK draws the title bar outside the Flutter canvas, so the palette crosses
/// the platform channel. The runner also applies the brightness to
/// `gtk-application-prefer-dark-theme`, which fixes GTK-native dialogs.
class WindowChrome {
  WindowChrome._();

  @visibleForTesting
  static const channelName = 'io.github.sundial/window';

  static const _channel = MethodChannel(channelName);

  static String? _lastPayload;

  @visibleForTesting
  static Map<String, Object> payloadFor(SundialColors colors, Brightness brightness) => <String, Object>{
    'dark': brightness == Brightness.dark,
    'pageBg': colors.pageBg.toARGB32(),
    'surfaceHigh': colors.surfaceHigh.toARGB32(),
    'border': colors.border.toARGB32(),
    'text': colors.text.toARGB32(),
    'textSecondary': colors.textSecondary.toARGB32(),
    'danger': colors.danger.toARGB32(),
    'dangerSoft': colors.dangerSoft.toARGB32(),
  };

  static Future<void> apply(SundialColors colors, Brightness brightness) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) return;
    final payload = payloadFor(colors, brightness);
    final key = payload.toString();
    if (key == _lastPayload) return;
    try {
      await _channel.invokeMethod<void>('apply', payload);
      _lastPayload = key;
    } on MissingPluginException {
      // Widget tests and desktop builds without the runner handler.
    } on PlatformException {
      // Window chrome is cosmetic; never fail the app for it.
    }
  }

  @visibleForTesting
  static void debugResetCache() => _lastPayload = null;
}

/// Applies the resolved theme to the OS window chrome whenever it changes.
class WindowChromeSync extends StatefulWidget {
  const WindowChromeSync({super.key, required this.colors, required this.brightness, required this.child});

  final SundialColors colors;
  final Brightness brightness;
  final Widget child;

  @override
  State<WindowChromeSync> createState() => _WindowChromeSyncState();
}

class _WindowChromeSyncState extends State<WindowChromeSync> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant WindowChromeSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  void _apply() => unawaited(WindowChrome.apply(widget.colors, widget.brightness));

  @override
  Widget build(BuildContext context) => widget.child;
}

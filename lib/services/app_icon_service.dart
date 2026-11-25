import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_icon_style.dart';

/// Applies the selected launcher icon per platform.
///
/// Android switches activity aliases. Linux desktops resolve the icon from the
/// `.desktop` entry's `Icon=` name, so the app writes the selected hicolor set
/// to a user-local override while keeping the name `io.github.sundial`. Desktop
/// shells may cache icons until the next session, which the settings UI states.
class AppIconService {
  const AppIconService({String? linuxDataHome, TargetPlatform? platform})
    : _linuxDataHome = linuxDataHome,
      _platform = platform;

  static const _channel = MethodChannel('sundial/app_icon');
  static const _linuxSizes = [16, 24, 32, 48, 64, 128, 256, 512];
  static const _linuxAssetNames = {
    AppIconStyle.classic: 'io.github.sundial',
    AppIconStyle.aero: 'io.github.sundial.aero',
  };

  /// Test seams for the XDG data home and the target platform. Production
  /// reads the environment and `defaultTargetPlatform`.
  final String? _linuxDataHome;
  final TargetPlatform? _platform;

  TargetPlatform get _targetPlatform => _platform ?? defaultTargetPlatform;

  bool get isSupported =>
      !kIsWeb && (_targetPlatform == TargetPlatform.android || _targetPlatform == TargetPlatform.linux);

  bool get isLinux => !kIsWeb && _targetPlatform == TargetPlatform.linux;

  Future<bool> apply(AppIconStyle style) async {
    if (!isSupported) return false;
    if (isLinux) return _applyLinux(style);
    try {
      return await _channel.invokeMethod<bool>('setAppIcon', {'style': style.name}) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _applyLinux(AppIconStyle style) async {
    final dataHome = _linuxDataHome ?? _xdgDataHome();
    if (dataHome == null) return false;
    var changed = false;
    try {
      for (final size in _linuxSizes) {
        final asset = 'assets/icons/linux/hicolor/${size}x$size/apps/${_linuxAssetNames[style]}.png';
        final target = File('$dataHome/icons/hicolor/${size}x$size/apps/io.github.sundial.png');
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        if (await target.exists() && listEquals(await target.readAsBytes(), bytes)) continue;
        await target.parent.create(recursive: true);
        // Write beside the target and rename so a symlink or a partial write
        // cannot leave a corrupt icon behind.
        final temp = File('${target.path}.sundial.tmp');
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(target.path);
        changed = true;
      }
      if (changed) {
        // A stale user icon-theme cache can hide the new files until the next
        // logout anyway; drop it so the shell can rescan at login.
        final cache = File('$dataHome/icons/hicolor/icon-theme.cache');
        if (await cache.exists()) {
          try {
            await cache.delete();
          } on FileSystemException {
            // The cache is optional; the written files remain valid.
          }
        }
      }
      return true;
    } on FileSystemException {
      return false;
    } on FlutterError {
      // A stripped build without the icon assets.
      return false;
    }
  }

  static String? _xdgDataHome() {
    final env = Platform.environment;
    final xdg = env['XDG_DATA_HOME']?.trim();
    if (xdg != null && xdg.isNotEmpty && xdg.startsWith('/')) return xdg;
    final home = env['HOME']?.trim();
    if (home == null || home.isEmpty) return null;
    return '$home/.local/share';
  }
}

final appIconServiceProvider = Provider<AppIconService>((ref) => const AppIconService());

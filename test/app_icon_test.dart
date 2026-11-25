import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/settings/pages/settings_detail_page.dart';
import 'package:sundial/features/settings/widgets/app_icon_row.dart';
import 'package:sundial/models/app_icon_style.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/app_icon_service.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial/state/settings_controller.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
  const channel = MethodChannel('sundial/app_icon');

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: SundialTheme.light,
    home: Scaffold(body: child),
  );

  void mockChannel(List<MethodCall> calls) {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  test('parses the launcher choice with a Classic fallback', () {
    expect(AppIconStyle.fromName('aero'), AppIconStyle.aero);
    expect(AppIconStyle.fromName('classic'), AppIconStyle.classic);
    expect(AppIconStyle.fromName('neon'), AppIconStyle.classic);
    expect(AppIconStyle.fromName(null), AppIconStyle.classic);
  });

  testWidgets('apply sends the selected style to the platform channel', (tester) async {
    final calls = <MethodCall>[];
    mockChannel(calls);

    expect(await const AppIconService(platform: TargetPlatform.android).apply(AppIconStyle.aero), isTrue);
    expect(calls.single.method, 'setAppIcon');
    expect(calls.single.arguments, {'style': 'aero'});
  });

  testWidgets('linux apply installs the selected hicolor set in the user data home', (tester) async {
    final dataHome = Directory.systemTemp.createTempSync('sundial-icons-');
    addTearDown(() => dataHome.deleteSync(recursive: true));

    await tester.runAsync(() async {
      final service = AppIconService(linuxDataHome: dataHome.path, platform: TargetPlatform.linux);
      expect(service.isSupported, isTrue);
      expect(await service.apply(AppIconStyle.aero), isTrue);

      for (final size in [16, 24, 32, 48, 64, 128, 256, 512]) {
        final target = File('${dataHome.path}/icons/hicolor/${size}x$size/apps/io.github.sundial.png');
        final source = File('assets/icons/linux/hicolor/${size}x$size/apps/io.github.sundial.aero.png');
        expect(target.existsSync(), isTrue, reason: target.path);
        expect(target.readAsBytesSync(), source.readAsBytesSync(), reason: target.path);
      }

      final cache = File('${dataHome.path}/icons/hicolor/icon-theme.cache');
      cache.writeAsStringSync('stale');
      expect(await service.apply(AppIconStyle.classic), isTrue);
      expect(cache.existsSync(), isFalse);
      final classic = File('${dataHome.path}/icons/hicolor/256x256/apps/io.github.sundial.png');
      final classicSource = File('assets/icons/linux/hicolor/256x256/apps/io.github.sundial.png');
      expect(classic.readAsBytesSync(), classicSource.readAsBytesSync());
    });
  });

  test('apply is a no-op outside Android and Linux', () async {
    expect(await const AppIconService(platform: TargetPlatform.windows).apply(AppIconStyle.aero), isFalse);
  });

  testWidgets('the icon row reports the tapped style', (tester) async {
    AppIconStyle? picked;
    await tester.pumpWidget(
      host(
        SettingsAppIconRow(
          title: 'App icon',
          subtitle: 'Choose the launcher icon for this device.',
          hint: 'Some launchers need a restart.',
          classicLabel: 'Classic',
          aeroLabel: 'Aero',
          selected: AppIconStyle.classic,
          onChanged: (value) => picked = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('appIconChoice-aero')));
    await tester.pumpAndSettle();
    expect(picked, AppIconStyle.aero);
  });

  testWidgets('the appearance section persists and applies the launcher choice', (tester) async {
    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();
    final calls = <MethodCall>[];
    mockChannel(calls);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: host(const SettingsDetailPage(section: SettingsDetailSection.appearance)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App icon'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('appIconChoice-aero')));
    await tester.pumpAndSettle();

    expect((await database.readSettings())[SettingsKeys.appIconStyle], 'aero');
    expect(calls.single.arguments, {'style': 'aero'});
  });

  testWidgets('linux shows the session-restart hint and persists the choice', (tester) async {
    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
          appIconServiceProvider.overrideWithValue(const _FakeLinuxIconService()),
        ],
        child: host(const SettingsDetailPage(section: SettingsDetailSection.appearance)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log out and back in to refresh the desktop icon.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('appIconChoice-aero')));
    await tester.pumpAndSettle();

    expect((await database.readSettings())[SettingsKeys.appIconStyle], 'aero');
  });

  test('ships every Android density, adaptive layer and Linux icon size', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/icons/'));
    for (final style in AppIconStyle.values) {
      final preview = File('assets/icons/icon_${style.name}.png');
      expect(preview.existsSync(), isTrue, reason: preview.path);
      expect(_isPng(preview), isTrue, reason: preview.path);

      for (final density in densities) {
        for (final name in ['ic_launcher_${style.name}.png', 'ic_launcher_${style.name}_round.png']) {
          final file = File('android/app/src/main/res/mipmap-$density/$name');
          expect(file.existsSync(), isTrue, reason: file.path);
          expect(_isPng(file), isTrue, reason: file.path);
        }
        for (final name in [
          'ic_launcher_${style.name}_background.png',
          'ic_launcher_${style.name}_foreground.png',
        ]) {
          final file = File('android/app/src/main/res/drawable-$density/$name');
          expect(file.existsSync(), isTrue, reason: file.path);
          expect(_isPng(file), isTrue, reason: file.path);
        }
        final monochrome = File('android/app/src/main/res/drawable-$density/ic_launcher_monochrome.png');
        expect(monochrome.existsSync(), isTrue, reason: monochrome.path);
        expect(_isPng(monochrome), isTrue, reason: monochrome.path);
      }

      for (final version in [26, 33]) {
        final file = File('android/app/src/main/res/mipmap-anydpi-v$version/ic_launcher_${style.name}.xml');
        final xml = file.readAsStringSync();
        expect(xml, contains('@drawable/ic_launcher_${style.name}_background'));
        expect(xml, contains('@drawable/ic_launcher_${style.name}_foreground'));
        expect(xml.contains('<monochrome'), version >= 33);
      }
    }

    for (final size in [16, 24, 32, 48, 64, 128, 256, 512]) {
      for (final name in ['io.github.sundial', 'io.github.sundial.aero']) {
        final file = File('assets/icons/linux/hicolor/${size}x$size/apps/$name.png');
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(_isPng(file), isTrue, reason: file.path);
      }
    }
    expect(File('linux/packaging/io.github.sundial.desktop').existsSync(), isTrue);
  });

  test('the manifest exposes exactly one enabled alias per icon and no duplicate launcher', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(RegExp(r'<activity-alias').allMatches(manifest), hasLength(2));
    expect(manifest, contains('android:name=".ClassicIcon"'));
    expect(manifest, contains('android:name=".AeroIcon"'));
    expect(manifest, contains('android:enabled="true"'));
    expect(manifest, contains('android:enabled="false"'));
    expect(manifest, contains('@mipmap/ic_launcher_classic'));
    expect(manifest, contains('@mipmap/ic_launcher_aero'));
    expect(
      RegExp(r'android\.intent\.category\.LAUNCHER').allMatches(manifest),
      hasLength(2),
      reason: 'MainActivity must not keep its own launcher entry',
    );
  });
}

bool _isPng(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 8) return false;
  return bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}

class _FakeLinuxIconService extends AppIconService {
  const _FakeLinuxIconService();

  @override
  bool get isSupported => true;

  @override
  bool get isLinux => true;

  @override
  Future<bool> apply(AppIconStyle style) async => true;
}

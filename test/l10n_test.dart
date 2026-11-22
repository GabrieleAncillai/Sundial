import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/l10n/app_localizations_en.dart';
import 'package:sundial/l10n/app_localizations_es.dart';

void main() {
  Map<String, dynamic> readArb(String path) =>
      Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

  test('widgets do not contain user-facing string literals', () {
    final literalPatterns = <RegExp>[
      RegExp(r"Text\(\s*'([^$']*)'"),
      RegExp(r"(?:labelText|hintText|helperText|tooltip|semanticLabel):\s*'([^$']*)'"),
    ];
    const allowed = {'Europe/Madrid'};
    final failures = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('app_localizations') || entity.path.endsWith('.g.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        for (final pattern in literalPatterns) {
          final match = pattern.firstMatch(lines[index]);
          if (match == null) continue;
          final value = match.group(1)!.trim();
          if (value.isEmpty || !RegExp('[A-Za-z]').hasMatch(value)) continue;
          if (allowed.contains(value)) continue;
          failures.add('${entity.path}:${index + 1}: "$value"');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Move these strings into app_en.arb and app_es.arb:\n${failures.join('\n')}',
    );
  });

  test('reminder lead times use the singular for one unit', () {
    final english = AppLocalizationsEn();
    final spanish = AppLocalizationsEs();

    expect(english.reminderMinutesBefore(1), '1 minute before');
    expect(english.reminderHoursBefore(1), '1 hour before');
    expect(english.reminderDaysBefore(1), '1 day before');
    expect(english.reminderMinutesBefore(10), '10 minutes before');
    expect(english.reminderHoursBefore(2), '2 hours before');

    expect(spanish.reminderMinutesBefore(1), '1 minuto antes');
    expect(spanish.reminderHoursBefore(1), '1 hora antes');
    expect(spanish.reminderDaysBefore(1), '1 día antes');
    expect(spanish.reminderHoursBefore(3), '3 horas antes');
  });

  test('the search hint stays short enough for a phone field', () {
    expect(AppLocalizationsEn().searchHint, 'Search entries, tags, items');
    expect(AppLocalizationsEs().searchHint, 'Busca entradas, etiquetas');
  });

  test('English and Spanish ARB files have the same keys and placeholders', () {
    final english = readArb('lib/l10n/app_en.arb');
    final spanish = readArb('lib/l10n/app_es.arb');

    Set<String> messages(Map<String, dynamic> arb) => arb.keys.where((key) => !key.startsWith('@')).toSet();

    expect(messages(spanish), messages(english));

    for (final key in messages(english)) {
      expect(english[key], isA<String>());
      expect((english[key] as String).trim(), isNotEmpty, reason: '$key is empty in English');
      expect((spanish[key] as String).trim(), isNotEmpty, reason: '$key is empty in Spanish');

      final englishMeta = english['@$key'];
      final spanishMeta = spanish['@$key'];
      final englishPlaceholders = englishMeta is Map
          ? (englishMeta['placeholders'] as Map?)?.keys.toSet() ?? <String>{}
          : <String>{};
      final spanishPlaceholders = spanishMeta is Map
          ? (spanishMeta['placeholders'] as Map?)?.keys.toSet() ?? <String>{}
          : <String>{};
      expect(spanishPlaceholders, englishPlaceholders, reason: 'Placeholders differ for $key');
    }
  });
}

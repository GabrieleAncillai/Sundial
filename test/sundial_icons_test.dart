import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/icons/sundial_icons.dart';

void main() {
  test('catalog keeps unique keys and at least 110 distinct icons', () {
    expect(SundialIcons.all.length, greaterThanOrEqualTo(110));
    expect(SundialIcons.all.values.toSet().length, greaterThanOrEqualTo(110));
    expect(SundialIcons.names.length, SundialIcons.all.length);
    expect(SundialIcons.names.toSet().length, SundialIcons.all.length);
  });

  test('recommended lists are valid and start with sensible defaults', () {
    const recommendations = [
      SundialIcons.workRecommended,
      SundialIcons.homeRecommended,
      SundialIcons.personalRecommended,
    ];

    for (final keys in recommendations) {
      expect(keys.length, inInclusiveRange(18, 24));
      for (final key in keys) {
        expect(SundialIcons.all.containsKey(key), isTrue, reason: key);
      }
    }

    expect(SundialIcons.workRecommended.first, 'briefcase');
    expect(SundialIcons.homeRecommended.first, 'house');
    expect(SundialIcons.personalRecommended.first, 'folder');
  });

  test('resolve returns a mapped icon and falls back for unknown names', () {
    expect(SundialIcons.resolve('briefcase'), Icons.work);
    expect(SundialIcons.resolve('missing'), Icons.folder_outlined);
    expect(SundialIcons.resolve('missing', fallback: Icons.star), Icons.star);
  });

  test('search matches keys and friendly synonyms', () {
    expect(SundialIcons.search('job'), contains('briefcase'));
    expect(SundialIcons.search('house'), containsAll(['house', 'villa', 'cottage']));
    expect(SundialIcons.search('air conditioner'), contains('ac_unit'));
    expect(SundialIcons.search('money'), containsAll(['payments', 'wallet']));
    expect(SundialIcons.search(''), SundialIcons.names);
  });
}

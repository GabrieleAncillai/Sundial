import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/icons/mane_icons.dart';

void main() {
  test('catalog keeps unique keys and at least 110 distinct icons', () {
    expect(ManeIcons.all.length, greaterThanOrEqualTo(110));
    expect(ManeIcons.all.values.toSet().length, greaterThanOrEqualTo(110));
    expect(ManeIcons.names.length, ManeIcons.all.length);
    expect(ManeIcons.names.toSet().length, ManeIcons.all.length);
  });

  test('recommended lists are valid and start with sensible defaults', () {
    const recommendations = [
      ManeIcons.workRecommended,
      ManeIcons.homeRecommended,
      ManeIcons.personalRecommended,
    ];

    for (final keys in recommendations) {
      expect(keys.length, inInclusiveRange(18, 24));
      for (final key in keys) {
        expect(ManeIcons.all.containsKey(key), isTrue, reason: key);
      }
    }

    expect(ManeIcons.workRecommended.first, 'briefcase');
    expect(ManeIcons.homeRecommended.first, 'house');
    expect(ManeIcons.personalRecommended.first, 'folder');
  });

  test('resolve returns a mapped icon and falls back for unknown names', () {
    expect(ManeIcons.resolve('briefcase'), Icons.work);
    expect(ManeIcons.resolve('missing'), Icons.folder_outlined);
    expect(ManeIcons.resolve('missing', fallback: Icons.star), Icons.star);
  });

  test('search matches keys and friendly synonyms', () {
    expect(ManeIcons.search('job'), contains('briefcase'));
    expect(ManeIcons.search('house'), containsAll(['house', 'villa', 'cottage']));
    expect(ManeIcons.search('air conditioner'), contains('ac_unit'));
    expect(ManeIcons.search('money'), containsAll(['payments', 'wallet']));
    expect(ManeIcons.search(''), ManeIcons.names);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../core/i18n/l10n.dart';
import '../../core/widgets/ui_kit.dart';
import '../../state/providers.dart';

/// Resolves the home a global inventory, shopping or gadget action belongs to.
///
/// Per-home screens already know their scope. The aggregate screens opened from
/// Settings ask once when more than one home exists, so no row is created
/// without a home.
Future<String?> chooseHomeScope(BuildContext context, WidgetRef ref, {required String? contextId}) async {
  if (contextId != null) return contextId;
  final homes = ref.read(contextsProvider('home')).value ?? const <PlannerContext>[];
  if (homes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.noHomesHint)));
    return null;
  }
  if (homes.length == 1) return homes.single.id;
  return showSundialSelectSheet<String>(
    context: context,
    title: context.l10n.chooseHome,
    selected: homes.first.id,
    options: [
      for (final home in homes)
        SundialSelectOption(
          value: home.id,
          label: home.name,
          leading: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: Color(home.colorValue), shape: BoxShape.circle),
          ),
        ),
    ],
  );
}

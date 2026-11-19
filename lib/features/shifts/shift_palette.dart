import 'package:flutter/material.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../theme/app_colors.dart';

/// A shift wears the colour of the job it belongs to. A pattern without a
/// saved context falls back to its space colour.
Color shiftColor(BuildContext context, ShiftPattern pattern, Iterable<PlannerContext> contexts) {
  final job = _contextFor(pattern, contexts);
  if (job != null) return Color(job.colorValue);
  return context.mc.forSpace(pattern.spaceId);
}

/// The translucent fill behind [shiftColor].
Color shiftSoftColor(BuildContext context, ShiftPattern pattern, Iterable<PlannerContext> contexts) {
  final job = _contextFor(pattern, contexts);
  if (job != null) {
    final alpha = Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.16;
    return Color(job.colorValue).withValues(alpha: alpha);
  }
  return context.mc.softForSpace(pattern.spaceId);
}

PlannerContext? _contextFor(ShiftPattern pattern, Iterable<PlannerContext> contexts) {
  final id = pattern.contextId;
  if (id == null) return null;
  for (final item in contexts) {
    if (item.id == id) return item;
  }
  return null;
}

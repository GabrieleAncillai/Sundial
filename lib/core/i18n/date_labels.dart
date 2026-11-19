import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../models/app_settings.dart';
import '../settings_scope.dart';

/// ISO weekdays in display order, starting from [weekStart] (1 = Monday).
List<int> weekdaysFrom(int weekStart) {
  final start = weekStart >= 1 && weekStart <= 7 ? weekStart : DateTime.monday;
  return [for (var offset = 0; offset < 7; offset++) ((start - 1 + offset) % 7) + 1];
}

/// A short weekday label in the current locale.
///
/// 2024-01-01 is a Monday, which keeps the arithmetic independent of the
/// current date.
String shortWeekday(BuildContext context, int weekday) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final date = DateTime.utc(2024, 1, 1).add(Duration(days: weekday - 1));
  return DateFormat.E(locale).format(date);
}

String shortWeekdayList(BuildContext context, Iterable<int> weekdays) =>
    (weekdays.toList()..sort()).map((day) => shortWeekday(context, day)).join(', ');

/// Formats a full date according to the user's date-format preference.
String formatFullDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return switch (AppSettingsScope.maybeOf(context)?.dateFormat ?? SundialDateFormat.system) {
    SundialDateFormat.dmy => DateFormat('dd/MM/yyyy', locale).format(date),
    SundialDateFormat.mdy => DateFormat('MM/dd/yyyy', locale).format(date),
    SundialDateFormat.ymd => DateFormat('yyyy/MM/dd', locale).format(date),
    SundialDateFormat.system => DateFormat.yMMMMd(locale).format(date),
  };
}

/// A compact date for ranges and chips. The order still follows the user's
/// date-format preference.
String formatShortDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return switch (AppSettingsScope.maybeOf(context)?.dateFormat ?? SundialDateFormat.system) {
    SundialDateFormat.dmy => DateFormat('dd/MM', locale).format(date),
    SundialDateFormat.mdy => DateFormat('MM/dd', locale).format(date),
    SundialDateFormat.ymd => DateFormat('yyyy/MM/dd', locale).format(date),
    SundialDateFormat.system => DateFormat.MMMd(locale).format(date),
  };
}

/// Formats a month and year according to the date-format preference.
String formatMonthYear(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return switch (AppSettingsScope.maybeOf(context)?.dateFormat ?? SundialDateFormat.system) {
    SundialDateFormat.ymd => DateFormat('yyyy/MM', locale).format(date),
    _ => DateFormat.yMMMM(locale).format(date),
  };
}

import 'package:sundial_core/sundial_core.dart';
import 'package:timezone/timezone.dart' as tz;

/// The date a gadget was last serviced, read in the zone the service was
/// recorded in.
///
/// Repository writes store noon UTC for all-day gadgets and noon in the entry
/// zone for timed ones. Reading with [DateTime.toLocal] would shift the date in
/// far-east or far-west device zones, so all-day rows stay in UTC and timed rows
/// use their stored IANA zone.
LocalDate? maintenanceServiceDate(Entry entry) {
  final instant = entry.lastCompletedAt;
  if (instant == null) return null;
  if (entry.allDay) return LocalDate.fromDateTime(instant.toUtc());
  final zone = entry.timeZone;
  if (zone == null) return LocalDate.fromDateTime(instant.toUtc());
  final location = tz.timeZoneDatabase.locations[zone];
  return LocalDate.fromDateTime(tz.TZDateTime.from(instant, location ?? tz.UTC));
}

import 'package:sundial_core/sundial_core.dart';

/// One recorded service for a home gadget.
class MaintenanceLog {
  const MaintenanceLog({
    required this.id,
    required this.entryId,
    required this.performedOn,
    required this.nextDue,
    this.note = '',
    this.durationMinutes,
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final LocalDate performedOn;
  final LocalDate nextDue;
  final String note;
  final int? durationMinutes;
  final DateTime createdAt;
}

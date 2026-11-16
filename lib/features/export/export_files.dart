import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Writes a comma-separated file through the platform save dialog.
Future<String?> saveCsvFile(String content, {required String dialogTitle, required String fileName}) async {
  try {
    return await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  } catch (_) {
    return null;
  }
}

/// Writes a PDF through the platform save dialog.
Future<String?> savePdfFile(Uint8List bytes, {required String dialogTitle, required String fileName}) async {
  try {
    return await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
  } catch (_) {
    return null;
  }
}

/// Writes an iCalendar file through the platform save dialog.
Future<String?> saveIcsFile(String content, {required String dialogTitle}) async {
  final now = DateTime.now().toUtc();
  final name =
      'sundial-calendar-${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}.ics';
  try {
    return await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: name,
      type: FileType.custom,
      allowedExtensions: ['ics'],
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  } catch (_) {
    return null;
  }
}

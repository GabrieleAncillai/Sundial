import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/app_database.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupVersionException implements Exception {
  const BackupVersionException(this.version);

  final int version;

  @override
  String toString() => 'BackupVersionException: $version';
}

/// Versioned JSON export and a transactional, validated import.
///
/// The export is a readable document rather than a database copy: identifiers,
/// timestamps, IANA zones, recurrence rules and soft deletes are preserved so
/// a round trip is lossless.
class BackupService {
  BackupService(this._database, {Directory? mediaDirectory}) : _mediaDirectory = mediaDirectory;

  static const appTag = 'sundial';
  static const currentSchemaVersion = 12;

  /// The oldest payload this build still upgrades. v1 and v2 are excluded on
  /// purpose: they predate timezone-aware entries and cannot be mapped safely.
  static const minimumSchemaVersion = 3;

  /// Secrets belong to this device. A backup must never carry pairing
  /// material to another install. The app-lock keys are legacy: the feature is
  /// gone, but older databases may still hold its hash, so keep stripping it.
  static const deviceLocalSettingKeys = {
    'appLockEnabled',
    'appLockPinSalt',
    'appLockPinHash',
    'appLockMisses',
    'appLockBlockedUntil',
  };

  final AppDatabase _database;
  final Directory? _mediaDirectory;

  Future<Directory> _mediaDir() async {
    final override = _mediaDirectory;
    if (override != null) return override;
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'media'));
  }

  Future<String> exportJson() async {
    final spaces = await _database.select(_database.spaceRecords).get();
    final contexts = await _database.select(_database.contextRecords).get();
    final projects = await _database.select(_database.projectRecords).get();
    final habits = await _database.select(_database.habitRecords).get();
    final habitCompletions = await _database.select(_database.habitCompletionRecords).get();
    final timeEntries = await _database.select(_database.timeEntryRecords).get();
    final tags = await _database.select(_database.tagRecords).get();
    final entries = await _database.select(_database.entryRecords).get();
    final entryTags = await _database.select(_database.entryTagRecords).get();
    final completions = await _database.select(_database.completionRecords).get();
    final reminders = await _database.select(_database.reminderRecords).get();
    final patterns = await _database.select(_database.shiftPatternRecords).get();
    final slots = await _database.select(_database.shiftSlotRecords).get();
    final exceptions = await _database.select(_database.shiftExceptionRecords).get();
    final patternTags = await _database.select(_database.shiftPatternTagRecords).get();
    final checklistItems = await _database.select(_database.shiftChecklistItemRecords).get();
    final checklistCompletions = await _database.select(_database.shiftChecklistCompletionRecords).get();
    final homeItems = await _database.select(_database.homeItemRecords).get();
    final shoppingItems = await _database.select(_database.shoppingItemRecords).get();
    final homePurchases = await _database.select(_database.homePurchaseRecords).get();
    final settings = await _database.select(_database.settingRecords).get();

    spaces.sort((a, b) {
      final byPosition = a.position.compareTo(b.position);
      return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
    });
    contexts.sort((a, b) => a.id.compareTo(b.id));
    projects.sort((a, b) => a.id.compareTo(b.id));
    habits.sort((a, b) => a.id.compareTo(b.id));
    habitCompletions.sort((a, b) {
      final byHabit = a.habitId.compareTo(b.habitId);
      return byHabit != 0 ? byHabit : a.dateKey.compareTo(b.dateKey);
    });
    timeEntries.sort((a, b) => a.id.compareTo(b.id));
    tags.sort((a, b) => a.id.compareTo(b.id));
    entries.sort((a, b) => a.id.compareTo(b.id));
    entryTags.sort((a, b) {
      final byEntry = a.entryId.compareTo(b.entryId);
      return byEntry != 0 ? byEntry : a.tagId.compareTo(b.tagId);
    });
    completions.sort((a, b) {
      final byEntry = a.entryId.compareTo(b.entryId);
      return byEntry != 0 ? byEntry : a.dateKey.compareTo(b.dateKey);
    });
    reminders.sort((a, b) => a.id.compareTo(b.id));
    patterns.sort((a, b) => a.id.compareTo(b.id));
    slots.sort((a, b) => a.id.compareTo(b.id));
    exceptions.sort((a, b) => a.id.compareTo(b.id));
    patternTags.sort((a, b) {
      final byPattern = a.patternId.compareTo(b.patternId);
      return byPattern != 0 ? byPattern : a.tagId.compareTo(b.tagId);
    });
    checklistItems.sort((a, b) {
      final byPattern = a.patternId.compareTo(b.patternId);
      return byPattern != 0 ? byPattern : a.position.compareTo(b.position);
    });
    checklistCompletions.sort((a, b) {
      final byItem = a.itemId.compareTo(b.itemId);
      return byItem != 0 ? byItem : a.dateKey.compareTo(b.dateKey);
    });
    homeItems.sort((a, b) => a.id.compareTo(b.id));
    shoppingItems.sort((a, b) => a.id.compareTo(b.id));
    homePurchases.sort((a, b) => a.id.compareTo(b.id));
    settings.sort((a, b) => a.key.compareTo(b.key));

    final media = <String, String>{};
    for (final path in [
      for (final row in contexts) row.imagePath,
      for (final row in projects) row.imagePath,
    ]) {
      if (path == null || path.isEmpty || media.containsKey(path)) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      media[path] = base64Encode(await file.readAsBytes());
    }

    final payload = <String, Object?>{
      'app': appTag,
      'schemaVersion': currentSchemaVersion,
      'media': media,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'spaces': [
        for (final row in spaces)
          {
            'id': row.id,
            'name': row.name,
            'color': row.color,
            'position': row.position,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'tags': [
        for (final row in tags)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'name': row.name,
            'color': row.color,
            'icon': row.icon,
            'position': row.position,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'contexts': [
        for (final row in contexts)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'name': row.name,
            'description': row.description,
            'color': row.color,
            'icon': row.icon,
            'imagePath': row.imagePath,
            'position': row.position,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'projects': [
        for (final row in projects)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'contextId': row.contextId,
            'name': row.name,
            'description': row.description,
            'color': row.color,
            'icon': row.icon,
            'imagePath': row.imagePath,
            'position': row.position,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'habits': [
        for (final row in habits)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'contextId': row.contextId,
            'name': row.name,
            'description': row.description,
            'color': row.color,
            'icon': row.icon,
            'targetPerWeek': row.targetPerWeek,
            'weekdays': row.weekdays,
            'position': row.position,
            'archived': row.archived,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'habitCompletions': [
        for (final row in habitCompletions)
          {'habitId': row.habitId, 'dateKey': row.dateKey, 'createdAt': _date(row.createdAt)},
      ],
      'timeEntries': [
        for (final row in timeEntries)
          {
            'id': row.id,
            'entryId': row.entryId,
            'occurrenceDateKey': row.occurrenceDateKey,
            'startedAt': _date(row.startedAt),
            'endedAt': _nullableDate(row.endedAt),
            'note': row.note,
            'createdAt': _date(row.createdAt),
          },
      ],
      'entries': [
        for (final row in entries)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'title': row.title,
            'notes': row.notes,
            'kind': row.kind,
            'dateKey': row.dateKey,
            'endDateKey': row.endDateKey,
            'startMinute': row.startMinute,
            'endMinute': row.endMinute,
            'timeZone': row.timeZone,
            'contextId': row.contextId,
            'projectId': row.projectId,
            'icon': row.icon,
            'priority': row.priority,
            'startAt': _nullableDate(row.startAt),
            'endAt': _nullableDate(row.endAt),
            'allDay': row.allDay,
            'status': row.status,
            'recurrenceJson': row.recurrenceJson,
            'source': row.source,
            'externalId': row.externalId,
            'readOnly': row.readOnly,
            'lastCompletedAt': _nullableDate(row.lastCompletedAt),
            'repeatAfterCompletionDays': row.repeatAfterCompletionDays,
            'completedAt': _nullableDate(row.completedAt),
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'entryTags': [
        for (final row in entryTags) {'entryId': row.entryId, 'tagId': row.tagId},
      ],
      'completions': [
        for (final row in completions)
          {'entryId': row.entryId, 'dateKey': row.dateKey, 'createdAt': _date(row.createdAt)},
      ],
      'reminders': [
        for (final row in reminders)
          {
            'id': row.id,
            'entryId': row.entryId,
            'offsetMinutes': row.offsetMinutes,
            'timeMinute': row.timeMinute,
            'enabled': row.enabled,
          },
      ],
      'shiftPatterns': [
        for (final row in patterns)
          {
            'id': row.id,
            'spaceId': row.spaceId,
            'name': row.name,
            'contextId': row.contextId,
            'timeZone': row.timeZone,
            'cycleDays': row.cycleDays,
            'anchorDateKey': row.anchorDateKey,
            'commuteMinutes': row.commuteMinutes,
            'windDownMinutes': row.windDownMinutes,
            'enabled': row.enabled,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'shiftSlots': [
        for (final row in slots)
          {
            'id': row.id,
            'patternId': row.patternId,
            'dayIndex': row.dayIndex,
            'label': row.label,
            'startMinute': row.startMinute,
            'endMinute': row.endMinute,
          },
      ],
      'shiftExceptions': [
        for (final row in exceptions)
          {
            'id': row.id,
            'patternId': row.patternId,
            'dateKey': row.dateKey,
            'type': row.type,
            'startMinute': row.startMinute,
            'endMinute': row.endMinute,
            'note': row.note,
          },
      ],
      'shiftPatternTags': [
        for (final row in patternTags) {'patternId': row.patternId, 'tagId': row.tagId},
      ],
      'shiftChecklistItems': [
        for (final row in checklistItems)
          {
            'id': row.id,
            'patternId': row.patternId,
            'label': row.label,
            'dayIndex': row.dayIndex,
            'position': row.position,
          },
      ],
      'shiftChecklistCompletions': [
        for (final row in checklistCompletions)
          {
            'itemId': row.itemId,
            'dateKey': row.dateKey,
            'slotKey': row.slotKey,
            'createdAt': _date(row.createdAt),
          },
      ],
      'homeItems': [
        for (final row in homeItems)
          {
            'id': row.id,
            'contextId': row.contextId,
            'name': row.name,
            'category': row.category,
            'location': row.location,
            'quantity': row.quantity,
            'reorderLevel': row.reorderLevel,
            'unit': row.unit,
            'notes': row.notes,
            'lastPurchasedAt': _nullableDate(row.lastPurchasedAt),
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'shoppingItems': [
        for (final row in shoppingItems)
          {
            'id': row.id,
            'contextId': row.contextId,
            'name': row.name,
            'quantity': row.quantity,
            'unit': row.unit,
            'checked': row.checked,
            'note': row.note,
            'homeItemId': row.homeItemId,
            'position': row.position,
            'createdAt': _date(row.createdAt),
            'updatedAt': _date(row.updatedAt),
            'deletedAt': _nullableDate(row.deletedAt),
          },
      ],
      'homePurchases': [
        for (final row in homePurchases)
          {
            'id': row.id,
            'homeItemId': row.homeItemId,
            'shoppingItemId': row.shoppingItemId,
            'quantity': row.quantity,
            'note': row.note,
            'purchasedAt': _date(row.purchasedAt),
          },
      ],
      'settings': {
        for (final row in settings)
          if (!deviceLocalSettingKeys.contains(row.key)) row.key: row.value,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importJson(String source) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('Not valid JSON');
    }
    if (decoded is! Map) throw const BackupFormatException('Root is not an object');
    final payload = Map<String, Object?>.from(decoded);

    if (payload['app'] != appTag) throw const BackupFormatException('Not a Sundial backup');
    final version = payload['schemaVersion'];
    if (version is! int) throw const BackupFormatException('Missing schema version');
    if (version > currentSchemaVersion) throw BackupVersionException(version);
    if (version < minimumSchemaVersion) {
      throw BackupFormatException('Unsupported schema version $version');
    }

    final spaces = _requiredMaps(payload, 'spaces');
    final contexts = _maps(payload, 'contexts');
    final projects = _maps(payload, 'projects');
    final habits = _maps(payload, 'habits');
    final habitCompletions = _maps(payload, 'habitCompletions');
    final timeEntries = _maps(payload, 'timeEntries');
    final tags = _maps(payload, 'tags');
    final entries = _requiredMaps(payload, 'entries');
    final entryTags = _maps(payload, 'entryTags');
    final completions = _maps(payload, 'completions');
    final reminders = _maps(payload, 'reminders');
    final patterns = _maps(payload, 'shiftPatterns');
    final slots = _maps(payload, 'shiftSlots');
    final exceptions = _maps(payload, 'shiftExceptions');
    final patternTags = _maps(payload, 'shiftPatternTags');
    final checklistItems = _maps(payload, 'shiftChecklistItems');
    final checklistCompletions = _maps(payload, 'shiftChecklistCompletions');
    final homeItems = _maps(payload, 'homeItems');
    final shoppingItems = _maps(payload, 'shoppingItems');
    final homePurchases = _maps(payload, 'homePurchases');
    final settings = _map(payload, 'settings');
    final media = _map(payload, 'media');

    // Semantic validation runs before any write. Enum names and recurrence
    // JSON are read with `byName`/`fromJson` later, so a crafted or stale value
    // must be rejected here instead of corrupting a readable database.
    _validateEntries(entries);
    final mediaTargets = <String, String>{};
    final mediaBytes = <String, Uint8List>{};
    var mediaIndex = 0;
    for (final entry in media.entries) {
      final encoded = entry.value;
      if (encoded is! String || encoded.isEmpty) continue;
      final Uint8List bytes;
      try {
        bytes = base64Decode(encoded);
      } on FormatException {
        throw BackupFormatException('media contains invalid base64');
      }
      final name = p.basename(entry.key).isEmpty
          ? 'sticker-${mediaIndex++}.png'
          : 'backup-${mediaIndex++}-${p.basename(entry.key)}';
      final target = p.join((await _mediaDir()).path, name);
      mediaTargets[entry.key] = target;
      mediaBytes[target] = bytes;
    }

    // Write media before the database transaction. A write failure then leaves
    // the existing plan untouched, and a later transaction failure only leaves
    // unreferenced files behind for the prune below.
    if (mediaBytes.isNotEmpty) {
      final directory = await _mediaDir();
      if (!directory.existsSync()) await directory.create(recursive: true);
      for (final entry in mediaBytes.entries) {
        await File(entry.key).writeAsBytes(entry.value, flush: true);
      }
    }

    // Media the outgoing plan referenced is the only set the restore may
    // remove. A backup without media must never wipe unrelated local files.
    final previousMedia = await _referencedMediaPaths();

    await _database.transaction(() async {
      await _database.delete(_database.habitCompletionRecords).go();
      await _database.delete(_database.timeEntryRecords).go();
      await _database.delete(_database.shiftChecklistCompletionRecords).go();
      await _database.delete(_database.shiftChecklistItemRecords).go();
      await _database.delete(_database.homePurchaseRecords).go();
      await _database.delete(_database.shoppingItemRecords).go();
      await _database.delete(_database.homeItemRecords).go();
      await _database.delete(_database.entryTagRecords).go();
      await _database.delete(_database.completionRecords).go();
      await _database.delete(_database.reminderRecords).go();
      await _database.delete(_database.shiftSlotRecords).go();
      await _database.delete(_database.shiftPatternTagRecords).go();
      await _database.delete(_database.shiftExceptionRecords).go();
      await _database.delete(_database.entryRecords).go();
      await _database.delete(_database.shiftPatternRecords).go();
      await _database.delete(_database.habitRecords).go();
      await _database.delete(_database.projectRecords).go();
      await _database.delete(_database.contextRecords).go();
      await _database.delete(_database.tagRecords).go();
      await _database.delete(_database.spaceRecords).go();
      await _database.delete(_database.settingRecords).go();

      for (final row in spaces) {
        await _database
            .into(_database.spaceRecords)
            .insert(
              SpaceRecordsCompanion(
                id: Value(_string(row, 'id')),
                name: Value(_string(row, 'name')),
                color: Value(_integer(row, 'color')),
                position: Value(_integer(row, 'position')),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in contexts) {
        await _database
            .into(_database.contextRecords)
            .insert(
              ContextRecordsCompanion(
                id: Value(_string(row, 'id')),
                spaceId: Value(_string(row, 'spaceId')),
                name: Value(_string(row, 'name')),
                description: Value(_optionalString(row, 'description') ?? ''),
                color: Value(_integer(row, 'color')),
                icon: Value(_optionalString(row, 'icon') ?? 'folder'),
                imagePath: Value(_backupMediaPath(_optionalString(row, 'imagePath'), mediaTargets)),
                position: Value(_optionalInteger(row, 'position') ?? 0),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in projects) {
        await _database
            .into(_database.projectRecords)
            .insert(
              ProjectRecordsCompanion(
                id: Value(_string(row, 'id')),
                spaceId: Value(_string(row, 'spaceId')),
                contextId: Value(_optionalString(row, 'contextId')),
                name: Value(_string(row, 'name')),
                description: Value(_optionalString(row, 'description') ?? ''),
                color: Value(_integer(row, 'color')),
                icon: Value(_optionalString(row, 'icon') ?? 'folder'),
                imagePath: Value(_backupMediaPath(_optionalString(row, 'imagePath'), mediaTargets)),
                position: Value(_optionalInteger(row, 'position') ?? 0),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in habits) {
        await _database
            .into(_database.habitRecords)
            .insert(
              HabitRecordsCompanion(
                id: Value(_string(row, 'id')),
                spaceId: Value(_string(row, 'spaceId')),
                contextId: Value(_optionalString(row, 'contextId')),
                name: Value(_string(row, 'name')),
                description: Value(_optionalString(row, 'description') ?? ''),
                color: Value(_integer(row, 'color')),
                icon: Value(_optionalString(row, 'icon') ?? 'star'),
                targetPerWeek: Value(_optionalInteger(row, 'targetPerWeek') ?? 7),
                weekdays: Value(_optionalString(row, 'weekdays') ?? '1,2,3,4,5,6,7'),
                position: Value(_optionalInteger(row, 'position') ?? 0),
                archived: Value(_optionalBoolean(row, 'archived') ?? false),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in tags) {
        await _database
            .into(_database.tagRecords)
            .insert(
              TagRecordsCompanion(
                id: Value(_string(row, 'id')),
                spaceId: Value(_optionalString(row, 'spaceId')),
                name: Value(_string(row, 'name')),
                color: Value(_integer(row, 'color')),
                icon: Value(_optionalString(row, 'icon') ?? 'folder'),
                position: Value(_integer(row, 'position')),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in homeItems) {
        await _database
            .into(_database.homeItemRecords)
            .insert(
              HomeItemRecordsCompanion(
                id: Value(_string(row, 'id')),
                contextId: Value(_optionalString(row, 'contextId')),
                name: Value(_string(row, 'name')),
                category: Value(_string(row, 'category')),
                location: Value(_string(row, 'location')),
                quantity: Value(_number(row, 'quantity')),
                reorderLevel: Value(_optionalNumber(row, 'reorderLevel')),
                unit: Value(_string(row, 'unit')),
                notes: Value(_string(row, 'notes')),
                lastPurchasedAt: Value(_optionalDateTime(row, 'lastPurchasedAt')),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in shoppingItems) {
        await _database
            .into(_database.shoppingItemRecords)
            .insert(
              ShoppingItemRecordsCompanion(
                id: Value(_string(row, 'id')),
                contextId: Value(_optionalString(row, 'contextId')),
                name: Value(_string(row, 'name')),
                quantity: Value(_number(row, 'quantity')),
                unit: Value(_string(row, 'unit')),
                checked: Value(_boolean(row, 'checked')),
                note: Value(_string(row, 'note')),
                homeItemId: Value(_optionalString(row, 'homeItemId')),
                position: Value(_optionalInteger(row, 'position') ?? 0),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in homePurchases) {
        await _database
            .into(_database.homePurchaseRecords)
            .insert(
              HomePurchaseRecordsCompanion.insert(
                id: _string(row, 'id'),
                homeItemId: _string(row, 'homeItemId'),
                shoppingItemId: Value(_optionalString(row, 'shoppingItemId')),
                quantity: _number(row, 'quantity'),
                note: Value(_optionalString(row, 'note') ?? ''),
                purchasedAt: _dateTime(row, 'purchasedAt'),
              ),
            );
      }

      for (final row in entries) {
        await _database
            .into(_database.entryRecords)
            .insert(
              EntryRecordsCompanion(
                id: Value(_string(row, 'id')),
                spaceId: Value(_string(row, 'spaceId')),
                title: Value(_string(row, 'title')),
                notes: Value(_string(row, 'notes')),
                kind: Value(_string(row, 'kind')),
                dateKey: Value(_optionalInteger(row, 'dateKey')),
                endDateKey: Value(_optionalInteger(row, 'endDateKey')),
                startMinute: Value(_optionalInteger(row, 'startMinute')),
                endMinute: Value(_optionalInteger(row, 'endMinute')),
                timeZone: Value(_optionalString(row, 'timeZone')),
                contextId: Value(_optionalString(row, 'contextId')),
                projectId: Value(_optionalString(row, 'projectId')),
                icon: Value(_optionalString(row, 'icon') ?? ''),
                priority: Value(_optionalString(row, 'priority') ?? 'none'),
                startAt: Value(_optionalDateTime(row, 'startAt')),
                endAt: Value(_optionalDateTime(row, 'endAt')),
                allDay: Value(_boolean(row, 'allDay')),
                status: Value(_string(row, 'status')),
                recurrenceJson: Value(_optionalString(row, 'recurrenceJson')),
                source: Value(_optionalString(row, 'source')),
                externalId: Value(_optionalString(row, 'externalId')),
                readOnly: Value(_optionalBoolean(row, 'readOnly') ?? false),
                lastCompletedAt: Value(_optionalDateTime(row, 'lastCompletedAt')),
                repeatAfterCompletionDays: Value(_optionalInteger(row, 'repeatAfterCompletionDays')),
                completedAt: Value(_optionalDateTime(row, 'completedAt')),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in entryTags) {
        await _database
            .into(_database.entryTagRecords)
            .insert(
              EntryTagRecordsCompanion.insert(entryId: _string(row, 'entryId'), tagId: _string(row, 'tagId')),
              mode: InsertMode.insertOrIgnore,
            );
      }

      for (final row in completions) {
        await _database
            .into(_database.completionRecords)
            .insert(
              CompletionRecordsCompanion.insert(
                entryId: _string(row, 'entryId'),
                dateKey: _integer(row, 'dateKey'),
                createdAt: _dateTime(row, 'createdAt'),
              ),
            );
      }

      for (final row in habitCompletions) {
        await _database
            .into(_database.habitCompletionRecords)
            .insert(
              HabitCompletionRecordsCompanion.insert(
                habitId: _string(row, 'habitId'),
                dateKey: _integer(row, 'dateKey'),
                createdAt: _dateTime(row, 'createdAt'),
              ),
            );
      }

      for (final row in timeEntries) {
        await _database
            .into(_database.timeEntryRecords)
            .insert(
              TimeEntryRecordsCompanion.insert(
                id: _string(row, 'id'),
                entryId: _string(row, 'entryId'),
                occurrenceDateKey: Value(_optionalInteger(row, 'occurrenceDateKey')),
                startedAt: _dateTime(row, 'startedAt'),
                endedAt: Value(_optionalDateTime(row, 'endedAt')),
                note: Value(_optionalString(row, 'note') ?? ''),
                createdAt: _dateTime(row, 'createdAt'),
              ),
            );
      }

      for (final row in reminders) {
        await _database
            .into(_database.reminderRecords)
            .insert(
              ReminderRecordsCompanion.insert(
                id: _string(row, 'id'),
                entryId: _string(row, 'entryId'),
                offsetMinutes: _integer(row, 'offsetMinutes'),
                timeMinute: Value(_optionalInteger(row, 'timeMinute')),
                enabled: Value(_boolean(row, 'enabled')),
              ),
            );
      }

      for (final row in patterns) {
        await _database
            .into(_database.shiftPatternRecords)
            .insert(
              ShiftPatternRecordsCompanion(
                id: Value(_string(row, 'id')),
                // Shifts are Work-only; a restored legacy row is repaired here
                // instead of being stored invisible to every query.
                spaceId: const Value('work'),
                name: Value(_string(row, 'name')),
                contextId: Value(_optionalString(row, 'contextId')),
                timeZone: Value(_string(row, 'timeZone')),
                cycleDays: Value(_integer(row, 'cycleDays')),
                anchorDateKey: Value(_integer(row, 'anchorDateKey')),
                commuteMinutes: Value(_optionalInteger(row, 'commuteMinutes')),
                windDownMinutes: Value(_optionalInteger(row, 'windDownMinutes')),
                enabled: Value(_boolean(row, 'enabled')),
                createdAt: Value(_dateTime(row, 'createdAt')),
                updatedAt: Value(_dateTime(row, 'updatedAt')),
                deletedAt: Value(_optionalDateTime(row, 'deletedAt')),
              ),
            );
      }

      for (final row in slots) {
        await _database
            .into(_database.shiftSlotRecords)
            .insert(
              ShiftSlotRecordsCompanion(
                id: Value(_integer(row, 'id')),
                patternId: Value(_string(row, 'patternId')),
                dayIndex: Value(_integer(row, 'dayIndex')),
                label: Value(_string(row, 'label')),
                startMinute: Value(_integer(row, 'startMinute')),
                endMinute: Value(_integer(row, 'endMinute')),
              ),
            );
      }

      for (final row in exceptions) {
        await _database
            .into(_database.shiftExceptionRecords)
            .insert(
              ShiftExceptionRecordsCompanion(
                id: Value(_integer(row, 'id')),
                patternId: Value(_string(row, 'patternId')),
                dateKey: Value(_integer(row, 'dateKey')),
                type: Value(_string(row, 'type')),
                startMinute: Value(_optionalInteger(row, 'startMinute')),
                endMinute: Value(_optionalInteger(row, 'endMinute')),
                note: Value(_string(row, 'note')),
              ),
            );
      }

      for (final row in patternTags) {
        await _database
            .into(_database.shiftPatternTagRecords)
            .insert(
              ShiftPatternTagRecordsCompanion.insert(
                patternId: _string(row, 'patternId'),
                tagId: _string(row, 'tagId'),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      for (final row in checklistItems) {
        await _database
            .into(_database.shiftChecklistItemRecords)
            .insert(
              ShiftChecklistItemRecordsCompanion(
                id: Value(_string(row, 'id')),
                patternId: Value(_string(row, 'patternId')),
                label: Value(_string(row, 'label')),
                dayIndex: Value(_optionalInteger(row, 'dayIndex')),
                position: Value(_integer(row, 'position')),
              ),
            );
      }

      for (final row in checklistCompletions) {
        await _database
            .into(_database.shiftChecklistCompletionRecords)
            .insert(
              ShiftChecklistCompletionRecordsCompanion.insert(
                itemId: _string(row, 'itemId'),
                dateKey: _integer(row, 'dateKey'),
                slotKey: Value(_optionalString(row, 'slotKey') ?? ''),
                createdAt: _dateTime(row, 'createdAt'),
              ),
            );
      }

      for (final entry in settings.entries) {
        // A crafted or stale backup must not be able to install a lock hash.
        if (deviceLocalSettingKeys.contains(entry.key)) continue;
        await _database
            .into(_database.settingRecords)
            .insert(SettingRecordsCompanion.insert(key: entry.key, value: '${entry.value}'));
      }
    });

    // The restore replaced the plan, so media that belonged to the old one is
    // no longer reachable. Best effort: a failure here only leaves unused files.
    await _pruneMedia(previousMedia, keep: mediaBytes.keys.toSet());
  }

  Future<Set<String>> _referencedMediaPaths() async {
    final paths = <String>{};
    for (final row in await _database.select(_database.contextRecords).get()) {
      final path = row.imagePath;
      if (path != null && path.isNotEmpty) paths.add(path);
    }
    for (final row in await _database.select(_database.projectRecords).get()) {
      final path = row.imagePath;
      if (path != null && path.isNotEmpty) paths.add(path);
    }
    return paths;
  }

  Future<void> _pruneMedia(Set<String> previous, {required Set<String> keep}) async {
    try {
      final directory = await _mediaDir();
      final root = p.normalize(directory.absolute.path);
      for (final path in previous) {
        if (keep.contains(path)) continue;
        final normalized = p.normalize(File(path).absolute.path);
        // Never delete outside the managed media folder.
        if (!p.isWithin(root, normalized)) continue;
        final file = File(normalized);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Orphaned media is harmless; the restore already succeeded.
    }
  }

  static void _validateEntries(List<Map<String, Object?>> entries) {
    for (final row in entries) {
      for (final field in const ['id', 'spaceId', 'title']) {
        final value = _optionalString(row, field);
        if (value == null || value.isEmpty) {
          throw BackupFormatException('entry is missing $field');
        }
      }
      final kind = row['kind'];
      if (kind is! String || !EntryKind.values.any((value) => value.name == kind)) {
        throw BackupFormatException('entry has an unknown kind');
      }
      final status = row['status'];
      if (status is! String || !EntryStatus.values.any((value) => value.name == status)) {
        throw BackupFormatException('entry has an unknown status');
      }
      final priority = row['priority'];
      if (priority != null &&
          (priority is! String || !EntryPriority.values.any((value) => value.name == priority))) {
        throw BackupFormatException('entry has an unknown priority');
      }
      final zone = _optionalString(row, 'timeZone');
      if (zone != null && zone.isNotEmpty && !isKnownTimeZone(zone)) {
        throw BackupFormatException('entry has an unknown timezone');
      }
      final rawRecurrence = row['recurrenceJson'];
      if (rawRecurrence != null) {
        if (rawRecurrence is! String) throw BackupFormatException('entry recurrence is invalid');
        try {
          final decoded = jsonDecode(rawRecurrence);
          if (decoded is! Map) throw const FormatException('not an object');
          RecurrenceRule.fromJson(Map<String, Object?>.from(decoded));
        } on Object {
          throw BackupFormatException('entry recurrence is invalid');
        }
      }
    }
  }

  static String? _backupMediaPath(String? path, Map<String, String> targets) {
    if (path == null || path.isEmpty) return null;
    // Only paths carried by the backup may survive import. Keeping an arbitrary
    // stored path would let a crafted backup point at a local file that the
    // next export then reads.
    return targets[path];
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _nullableDate(DateTime? value) => value?.toUtc().toIso8601String();

  static List<Map<String, Object?>> _requiredMaps(Map<String, Object?> payload, String key) {
    if (!payload.containsKey(key)) throw BackupFormatException('$key is missing');
    return _maps(payload, key);
  }

  static List<Map<String, Object?>> _maps(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value == null) return const [];
    if (value is! List) throw BackupFormatException('$key is not a list');
    return [
      for (final row in value)
        if (row is Map)
          Map<String, Object?>.from(row)
        else
          throw BackupFormatException('$key contains a non-object'),
    ];
  }

  static Map<String, Object?> _map(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value == null) return const {};
    if (value is! Map) throw BackupFormatException('$key is not an object');
    return Map<String, Object?>.from(value);
  }

  static String _string(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is String) return value;
    throw BackupFormatException('$key is not a string');
  }

  static String? _optionalString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is String) return value;
    throw BackupFormatException('$key is not a string');
  }

  static int _integer(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    throw BackupFormatException('$key is not an integer');
  }

  static int? _optionalInteger(Map<String, Object?> row, String key) {
    if (row[key] == null) return null;
    return _integer(row, key);
  }

  static double _number(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is num) return value.toDouble();
    throw BackupFormatException('$key is not a number');
  }

  static double? _optionalNumber(Map<String, Object?> row, String key) {
    if (row[key] == null) return null;
    return _number(row, key);
  }

  static bool _boolean(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is bool) return value;
    throw BackupFormatException('$key is not a boolean');
  }

  static bool? _optionalBoolean(Map<String, Object?> row, String key) {
    if (row[key] == null) return null;
    return _boolean(row, key);
  }

  static DateTime _dateTime(Map<String, Object?> row, String key) {
    final value = _string(row, key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw BackupFormatException('$key is not a date');
    return parsed.toUtc();
  }

  static DateTime? _optionalDateTime(Map<String, Object?> row, String key) {
    if (row[key] == null) return null;
    return _dateTime(row, key);
  }
}

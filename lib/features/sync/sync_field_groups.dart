import 'dart:convert';

import 'package:drift/drift.dart';

/// A group of columns that must move together during a merge.
///
/// Column names are the SQL names from the Drift table, because the row
/// payload is stored in that form.
class SyncFieldGroup {
  const SyncFieldGroup(this.name, this.columns);

  final String name;
  final List<String> columns;
}

/// One synced entity: its table, canonical key, merge fields and dependency
/// rank. Specs are built once in `app_database_sync.dart`.
class SyncEntitySpec {
  SyncEntitySpec({
    required this.name,
    required this.table,
    required this.keyColumns,
    required this.fields,
    required this.rank,
    required this.softDelete,
    this.autoIncrementColumn,
    this.stripColumns = const <String>{},
    this.immutableColumns = const <String>{},
    this.includeRow,
  });

  final String name;
  final TableInfo table;
  final List<String> keyColumns;
  final List<SyncFieldGroup> fields;
  final int rank;
  final bool softDelete;

  /// Local auto-increment column that never travels. Null for tables whose id
  /// is a stable UUID.
  final String? autoIncrementColumn;

  /// Columns omitted from row payloads, for example context image paths.
  final Set<String> stripColumns;

  /// Columns that are neither keys nor merge fields: timestamps and fields
  /// that never change after creation.
  final Set<String> immutableColumns;

  /// Optional row filter, used to sync only `weekStart` from settings.
  final bool Function(Map<String, Object?> row)? includeRow;

  Map<String, GeneratedColumn> get columns => table.columnsByName;

  bool get isMembership => fields.length == 1 && fields.single.name == 'present';

  Set<String> get mergeColumns => {for (final field in fields) ...field.columns};

  /// Every column a row payload may contain. Auto-increment and stripped
  /// columns are excluded.
  List<String> get payloadColumns => [
    for (final column in table.$columns)
      if (column.$name != autoIncrementColumn && !stripColumns.contains(column.$name)) column.$name,
  ];

  /// Columns that are neither payload fields nor explicitly excluded. Used by
  /// the coverage test.
  List<String> get unmappedColumns {
    final covered = {...mergeColumns, ...keyColumns, ...immutableColumns};
    return [
      for (final column in payloadColumns)
        if (!covered.contains(column)) column,
    ];
  }

  Map<String, Object?> serialize(DataClass row) {
    final raw = (row as Insertable).toColumns(false);
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      if (entry.key == autoIncrementColumn) continue;
      if (stripColumns.contains(entry.key)) continue;
      final value = entry.value;
      if (value is! Variable) {
        throw StateError('Sync row ${table.actualTableName} has a non-variable column ${entry.key}');
      }
      final column = columns[entry.key];
      if (column == null) continue;
      result[entry.key] = encodeValue(column, value.value);
    }
    return result;
  }

  String rowKey(Map<String, Object?> row) {
    if (keyColumns.length == 1) {
      final value = row[keyColumns.single];
      if (value is! String || value.isEmpty) {
        throw StateError('Entity $name has an invalid row key: $value');
      }
      return value;
    }
    return jsonEncode([for (final column in keyColumns) row[column]]);
  }

  List<Object?> keyValues(String rowKey) {
    if (keyColumns.length == 1) return [rowKey];
    final decoded = jsonDecode(rowKey);
    if (decoded is! List || decoded.length != keyColumns.length) {
      throw FormatException('Invalid $name row key', rowKey);
    }
    return decoded;
  }

  Expression<bool> keyPredicate(String rowKey) {
    final values = keyValues(rowKey);
    Expression<bool>? result;
    for (var index = 0; index < keyColumns.length; index++) {
      final column = columns[keyColumns[index]];
      if (column == null) throw StateError('Missing key column ${keyColumns[index]} on $name');
      final comparison = syncEquals(column, decodeValue(column, values[index]));
      result = result == null ? comparison : result & comparison;
    }
    return result!;
  }

  /// Merge-field names whose columns differ. A new row (before == null) has
  /// every group, so its field versions are complete.
  List<String> changedFields(Map<String, Object?>? before, Map<String, Object?>? after) {
    if (after == null) return const [];
    if (before == null) return [for (final field in fields) field.name];
    final changed = <String>[];
    for (final field in fields) {
      for (final column in field.columns) {
        if (!_same(before[column], after[column])) {
          changed.add(field.name);
          break;
        }
      }
    }
    return changed;
  }

  bool includes(Map<String, Object?> row) => includeRow?.call(row) ?? true;

  static bool _same(Object? first, Object? second) {
    if (first is num && second is num) return first.toDouble() == second.toDouble();
    return first == second;
  }
}

/// Compares a dynamically-typed [GeneratedColumn] with a Dart value.
Expression<bool> syncEquals(GeneratedColumn column, Object? value) {
  if (value == null) return (column as GeneratedColumn<Object?>).isNull();
  return column.equals(value);
}

/// JSON-safe representation of a Drift value. Dates become epoch millis and
/// blobs become base64; the rest already fit in JSON.
Object? encodeValue(GeneratedColumn column, Object? value) {
  if (value == null) return null;
  final type = column.type;
  if (type is! DriftSqlType) {
    throw StateError('Unsupported sync column type: $type');
  }
  return switch (type) {
    DriftSqlType.bool => value as bool,
    DriftSqlType.string => value as String,
    DriftSqlType.bigInt => (value as BigInt).toString(),
    DriftSqlType.int => (value as num).toInt(),
    DriftSqlType.dateTime => (value as DateTime).toUtc().millisecondsSinceEpoch,
    DriftSqlType.blob => base64Encode(value as List<int>),
    DriftSqlType.double => (value as num).toDouble(),
    DriftSqlType.any => value,
  };
}

/// Converts a payload value back to the Dart value a [Variable] expects.
Object? decodeValue(GeneratedColumn column, Object? value) {
  if (value == null) return null;
  final type = column.type;
  if (type is! DriftSqlType) {
    throw StateError('Unsupported sync column type: $type');
  }
  return switch (type) {
    DriftSqlType.bool => value == true,
    DriftSqlType.string => '$value',
    DriftSqlType.bigInt => BigInt.parse('$value'),
    DriftSqlType.int => value is num ? value.toInt() : int.parse('$value'),
    DriftSqlType.dateTime => DateTime.fromMillisecondsSinceEpoch(
      value is num ? value.toInt() : int.parse('$value'),
      isUtc: true,
    ),
    DriftSqlType.blob => base64Decode('$value'),
    DriftSqlType.double => value is num ? value.toDouble() : double.parse('$value'),
    DriftSqlType.any => value,
  };
}

/// The synthetic field used by membership/link tables. It has no data columns
/// of its own; the row's existence is the value.
const presentField = 'present';

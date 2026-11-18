/// Household category shown on inventory and shopping items.
class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.icon = 'category',
    this.position = 0,
  });

  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final int position;

  HomeCategory copyWith({String? name, String? icon, int? colorValue, int? position}) => HomeCategory(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    position: position ?? this.position,
  );
}

/// A place in or around the house where stock can live.
class HomeLocation {
  const HomeLocation({
    required this.id,
    required this.name,
    required this.colorValue,
    this.icon = 'place',
    this.position = 0,
  });

  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final int position;

  HomeLocation copyWith({String? name, String? icon, int? colorValue, int? position}) => HomeLocation(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    position: position ?? this.position,
  );
}

/// How a unit behaves when the app rounds a suggested purchase.
enum HomeUnitKind { count, weight, volume, length, other }

/// A unit of measure for an inventory variant.
class HomeUnit {
  const HomeUnit({
    required this.id,
    required this.name,
    this.symbol = '',
    this.kind = HomeUnitKind.count,
    this.position = 0,
  });

  final String id;
  final String name;

  /// Short form used in dense rows, for example `kg` or `btl`.
  final String symbol;
  final HomeUnitKind kind;
  final int position;

  String get displayLabel => symbol.isEmpty ? name : symbol;

  HomeUnit copyWith({String? name, String? symbol, HomeUnitKind? kind, int? position}) => HomeUnit(
    id: id,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    kind: kind ?? this.kind,
    position: position ?? this.position,
  );
}

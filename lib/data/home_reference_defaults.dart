import 'package:flutter/widgets.dart';

import '../models/home_reference.dart';

/// Seeded household categories. Users can rename, recolor or delete them; the
/// stable ids also anchor the catalog defaults.
const defaultHomeCategories = <HomeCategory>[
  HomeCategory(
    id: 'home-food',
    name: 'Food & pantry',
    icon: 'restaurant',
    colorValue: 0xFFE07B39,
    position: 0,
  ),
  HomeCategory(
    id: 'home-spices',
    name: 'Spices & condiments',
    icon: 'local_florist',
    colorValue: 0xFFD39A2E,
    position: 1,
  ),
  HomeCategory(
    id: 'home-consumables',
    name: 'Household consumables',
    icon: 'shopping_bag',
    colorValue: 0xFF2FA98F,
    position: 2,
  ),
  HomeCategory(
    id: 'home-cleaning',
    name: 'Cleaning & laundry',
    icon: 'cleaning_services',
    colorValue: 0xFF0A8FCF,
    position: 3,
  ),
  HomeCategory(
    id: 'home-personal',
    name: 'Personal care & hygiene',
    icon: 'spa',
    colorValue: 0xFFC2456B,
    position: 4,
  ),
  HomeCategory(
    id: 'home-medicine',
    name: 'Medicine & first aid',
    icon: 'medical_services',
    colorValue: 0xFFD14B4B,
    position: 5,
  ),
  HomeCategory(
    id: 'home-makeup',
    name: 'Makeup & beauty',
    icon: 'brush',
    colorValue: 0xFF8A63D2,
    position: 6,
  ),
  HomeCategory(
    id: 'home-kitchenware',
    name: 'Kitchenware & goods',
    icon: 'kitchen',
    colorValue: 0xFFB5762E,
    position: 7,
  ),
  HomeCategory(
    id: 'home-textiles',
    name: 'Bedding & textiles',
    icon: 'bed',
    colorValue: 0xFF5B79C9,
    position: 8,
  ),
  HomeCategory(
    id: 'home-tools',
    name: 'Tools & hardware',
    icon: 'handyman',
    colorValue: 0xFF5A6470,
    position: 9,
  ),
  HomeCategory(
    id: 'home-misc',
    name: 'Miscellaneous essentials',
    icon: 'inventory',
    colorValue: 0xFF4F7F7A,
    position: 10,
  ),
  HomeCategory(
    id: 'home-pet-garden',
    name: 'Pet & garden',
    icon: 'pets',
    colorValue: 0xFF6E9E3E,
    position: 11,
  ),
];

const defaultHomeLocations = <HomeLocation>[
  HomeLocation(id: 'home-loc-kitchen', name: 'Kitchen', icon: 'kitchen', colorValue: 0xFFB5762E, position: 0),
  HomeLocation(id: 'home-loc-pantry', name: 'Pantry', icon: 'inventory', colorValue: 0xFFD39A2E, position: 1),
  HomeLocation(
    id: 'home-loc-main-room',
    name: 'Main room',
    icon: 'chair',
    colorValue: 0xFFB07D5C,
    position: 2,
  ),
  HomeLocation(
    id: 'home-loc-secondary-room',
    name: 'Secondary room',
    icon: 'chair',
    colorValue: 0xFF8A6248,
    position: 3,
  ),
  HomeLocation(
    id: 'home-loc-main-bathroom',
    name: 'Main bathroom',
    icon: 'bathroom',
    colorValue: 0xFF0A8FCF,
    position: 4,
  ),
  HomeLocation(
    id: 'home-loc-guest-bathroom',
    name: 'Guest bathroom',
    icon: 'bathroom',
    colorValue: 0xFF2F7ED8,
    position: 5,
  ),
  HomeLocation(id: 'home-loc-bedroom', name: 'Bedroom', icon: 'bed', colorValue: 0xFF5B79C9, position: 6),
  HomeLocation(
    id: 'home-loc-hallway',
    name: 'Hallway',
    icon: 'apartment',
    colorValue: 0xFF8C857A,
    position: 7,
  ),
  HomeLocation(id: 'home-loc-stairs', name: 'Stairs', icon: 'stairs', colorValue: 0xFF5A6470, position: 8),
  HomeLocation(id: 'home-loc-garage', name: 'Garage', icon: 'garage', colorValue: 0xFF5A6470, position: 9),
  HomeLocation(id: 'home-loc-backyard', name: 'Backyard', icon: 'yard', colorValue: 0xFF6E9E3E, position: 10),
  HomeLocation(id: 'home-loc-patio', name: 'Patio', icon: 'deck', colorValue: 0xFF8A6248, position: 11),
  HomeLocation(
    id: 'home-loc-laundry',
    name: 'Laundry room',
    icon: 'laundry',
    colorValue: 0xFF2FA98F,
    position: 12,
  ),
  HomeLocation(
    id: 'home-loc-storage',
    name: 'Storage room',
    icon: 'warehouse',
    colorValue: 0xFF4F7F7A,
    position: 13,
  ),
  HomeLocation(
    id: 'home-loc-basement',
    name: 'Basement',
    icon: 'foundation',
    colorValue: 0xFF5A6470,
    position: 14,
  ),
  HomeLocation(id: 'home-loc-attic', name: 'Attic', icon: 'roof', colorValue: 0xFF8A6248, position: 15),
  HomeLocation(id: 'home-loc-shed', name: 'Garden shed', icon: 'cabin', colorValue: 0xFF6B7F5A, position: 16),
  HomeLocation(id: 'home-loc-car', name: 'Car', icon: 'car', colorValue: 0xFF4A6FA5, position: 17),
  HomeLocation(id: 'home-loc-balcony', name: 'Balcony', icon: 'deck', colorValue: 0xFF2F7ED8, position: 18),
  HomeLocation(id: 'home-loc-office', name: 'Office', icon: 'laptop', colorValue: 0xFF4A6FA5, position: 19),
];

const defaultHomeUnits = <HomeUnit>[
  HomeUnit(id: 'home-unit-piece', name: 'Piece', symbol: 'pcs', position: 0),
  HomeUnit(id: 'home-unit-bottle', name: 'Bottle', symbol: 'btl', kind: HomeUnitKind.count, position: 1),
  HomeUnit(id: 'home-unit-pack', name: 'Pack', symbol: 'pack', position: 2),
  HomeUnit(id: 'home-unit-box', name: 'Box', symbol: 'box', position: 3),
  HomeUnit(id: 'home-unit-can', name: 'Can', symbol: 'can', position: 4),
  HomeUnit(id: 'home-unit-jar', name: 'Jar', symbol: 'jar', position: 5),
  HomeUnit(id: 'home-unit-bag', name: 'Bag', symbol: 'bag', position: 6),
  HomeUnit(id: 'home-unit-roll', name: 'Roll', symbol: 'roll', position: 7),
  HomeUnit(id: 'home-unit-pair', name: 'Pair', symbol: 'pair', position: 8),
  HomeUnit(id: 'home-unit-set', name: 'Set', symbol: 'set', position: 9),
  HomeUnit(id: 'home-unit-tube', name: 'Tube', symbol: 'tube', position: 10),
  HomeUnit(id: 'home-unit-bar', name: 'Bar', symbol: 'bar', position: 11),
  HomeUnit(id: 'home-unit-tablet', name: 'Tablet', symbol: 'tab', position: 12),
  HomeUnit(id: 'home-unit-capsule', name: 'Capsule', symbol: 'cap', position: 13),
  HomeUnit(id: 'home-unit-sheet', name: 'Sheet', symbol: 'sheet', position: 14),
  HomeUnit(id: 'home-unit-load', name: 'Load', symbol: 'load', position: 15),
  HomeUnit(id: 'home-unit-spray', name: 'Spray', symbol: 'spray', position: 16),
  HomeUnit(id: 'home-unit-sachet', name: 'Sachet', symbol: 'sachet', position: 17),
  HomeUnit(id: 'home-unit-kg', name: 'Kilogram', symbol: 'kg', kind: HomeUnitKind.weight, position: 18),
  HomeUnit(id: 'home-unit-g', name: 'Gram', symbol: 'g', kind: HomeUnitKind.weight, position: 19),
  HomeUnit(id: 'home-unit-l', name: 'Litre', symbol: 'L', kind: HomeUnitKind.volume, position: 20),
  HomeUnit(id: 'home-unit-ml', name: 'Millilitre', symbol: 'ml', kind: HomeUnitKind.volume, position: 21),
  HomeUnit(id: 'home-unit-m', name: 'Metre', symbol: 'm', kind: HomeUnitKind.length, position: 22),
  HomeUnit(id: 'home-unit-cm', name: 'Centimetre', symbol: 'cm', kind: HomeUnitKind.length, position: 23),
];

/// Spanish labels for the seeded rows. The database stores the English name;
/// a row that still matches its default displays the current locale's label.
const _categoryNamesEs = <String, String>{
  'home-food': 'Comida y despensa',
  'home-spices': 'Especias y condimentos',
  'home-consumables': 'Consumibles del hogar',
  'home-cleaning': 'Limpieza y colada',
  'home-personal': 'Cuidado personal e higiene',
  'home-medicine': 'Medicina y botiquín',
  'home-makeup': 'Maquillaje y belleza',
  'home-kitchenware': 'Menaje y utensilios',
  'home-textiles': 'Ropa de cama y textiles',
  'home-tools': 'Herramientas y ferretería',
  'home-misc': 'Esenciales varios',
  'home-pet-garden': 'Mascotas y jardín',
};

const _locationNamesEs = <String, String>{
  'home-loc-kitchen': 'Cocina',
  'home-loc-pantry': 'Despensa',
  'home-loc-main-room': 'Salón',
  'home-loc-secondary-room': 'Segunda sala',
  'home-loc-main-bathroom': 'Baño principal',
  'home-loc-guest-bathroom': 'Baño de invitados',
  'home-loc-bedroom': 'Dormitorio',
  'home-loc-hallway': 'Pasillo',
  'home-loc-stairs': 'Escaleras',
  'home-loc-garage': 'Garaje',
  'home-loc-backyard': 'Patio trasero',
  'home-loc-patio': 'Terraza',
  'home-loc-laundry': 'Lavadero',
  'home-loc-storage': 'Trastero',
  'home-loc-basement': 'Sótano',
  'home-loc-attic': 'Ático',
  'home-loc-shed': 'Cobertizo',
  'home-loc-car': 'Coche',
  'home-loc-balcony': 'Balcón',
  'home-loc-office': 'Oficina',
};

const _unitNamesEs = <String, String>{
  'home-unit-piece': 'Pieza',
  'home-unit-bottle': 'Botella',
  'home-unit-pack': 'Paquete',
  'home-unit-box': 'Caja',
  'home-unit-can': 'Lata',
  'home-unit-jar': 'Tarro',
  'home-unit-bag': 'Bolsa',
  'home-unit-roll': 'Rollo',
  'home-unit-pair': 'Par',
  'home-unit-set': 'Juego',
  'home-unit-tube': 'Tubo',
  'home-unit-bar': 'Barra',
  'home-unit-tablet': 'Tableta',
  'home-unit-capsule': 'Cápsula',
  'home-unit-sheet': 'Hoja',
  'home-unit-load': 'Colada',
  'home-unit-spray': 'Spray',
  'home-unit-sachet': 'Sobre',
  'home-unit-kg': 'Kilogramo',
  'home-unit-g': 'Gramo',
  'home-unit-l': 'Litro',
  'home-unit-ml': 'Mililitro',
  'home-unit-m': 'Metro',
  'home-unit-cm': 'Centímetro',
};

HomeCategory? defaultCategoryById(String? id) {
  if (id == null) return null;
  for (final category in defaultHomeCategories) {
    if (category.id == id) return category;
  }
  return null;
}

HomeLocation? defaultLocationById(String? id) {
  if (id == null) return null;
  for (final location in defaultHomeLocations) {
    if (location.id == id) return location;
  }
  return null;
}

HomeUnit? defaultUnitById(String? id) {
  if (id == null) return null;
  for (final unit in defaultHomeUnits) {
    if (unit.id == id) return unit;
  }
  return null;
}

String localizedCategoryName(HomeCategory category, Locale locale) {
  if (locale.languageCode == 'es' && category.name == defaultCategoryById(category.id)?.name) {
    return _categoryNamesEs[category.id] ?? category.name;
  }
  return category.name;
}

String localizedLocationName(HomeLocation location, Locale locale) {
  if (locale.languageCode == 'es' && location.name == defaultLocationById(location.id)?.name) {
    return _locationNamesEs[location.id] ?? location.name;
  }
  return location.name;
}

String localizedUnitName(HomeUnit unit, Locale locale) {
  if (locale.languageCode == 'es' && unit.name == defaultUnitById(unit.id)?.name) {
    return _unitNamesEs[unit.id] ?? unit.name;
  }
  return unit.name;
}

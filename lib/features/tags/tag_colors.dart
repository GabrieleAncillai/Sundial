import 'package:flutter/material.dart';

/// Tag colors offered by the editor. Values are ARGB ints so they can live in
/// the pure domain and the database without Flutter imports.
///
/// The original eight keep their order so the default tag color stays stable.
const tagPalette = <int>[
  0xFFB07D5C,
  0xFF5B7F6B,
  0xFF4A6FA5,
  0xFF9A6B8F,
  0xFFC08A3E,
  0xFF6B7F9A,
  0xFF8A5A5A,
  0xFF4F7F7A,
  0xFF2E6B45,
  0xFF3E8E59,
  0xFF6E9E3E,
  0xFF2FA98F,
  0xFF1E8C7E,
  0xFF2BA8AD,
  0xFF0A8FCF,
  0xFF2F7ED8,
  0xFF1F5FA8,
  0xFF5B79C9,
  0xFF6E52D8,
  0xFF8A63D2,
  0xFF9E5FC4,
  0xFFB04A7A,
  0xFFD2658F,
  0xFFC2456B,
  0xFFC25B3F,
  0xFFD14B4B,
  0xFFA83A3A,
  0xFFE07B39,
  0xFFD39A2E,
  0xFFB5762E,
  0xFF8A6248,
  0xFF5A6470,
];

Color tagColor(int value) => Color(value);

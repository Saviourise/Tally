import 'package:flutter/material.dart';

/// Warm Peach Playful palette.
class TallyColors {
  TallyColors._();

  // Backgrounds
  static const cream = Color(0xFFFCF8F3); // light bg
  static const peach = Color(0xFFFFE2C8); // gradient terminus
  static const inkDark = Color(0xFF1A1410); // dark bg
  static const surfaceDark = Color(0xFF2A2018); // dark surface

  // Accents
  static const honey = Color(0xFFFF7A29); // primary vivid orange
  static const honeyDeep = Color(0xFFE5631A); // pressed / hover
  static const copper = Color(0xFFFFA168); // lighter peach accent

  // Ink
  static const ink = Color(0xFF1A1410);
  static const inkInverse = Color(0xFFFCF8F3);

  // Muted text
  static const muted = Color(0xFF6B5D52);
  static const mutedDark = Color(0xFFB8A89A);

  static Color divider(bool dark) =>
      dark ? const Color(0x14FFFFFF) : const Color(0x141A1410);

  static Color glassFill(bool dark) =>
      dark ? const Color(0x1FFFFFFF) : const Color(0xCCFFFFFF);

  static Color glassBorder(bool dark) =>
      dark ? const Color(0x33FFFFFF) : const Color(0x10000000);
}

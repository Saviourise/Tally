import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tally_colors.dart';

class TallyTheme {
  TallyTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final cs = ColorScheme.fromSeed(
      seedColor: TallyColors.honey,
      brightness: Brightness.light,
      primary: TallyColors.honey,
      onPrimary: Colors.white,
      secondary: TallyColors.copper,
      surface: TallyColors.cream,
      onSurface: TallyColors.ink,
    );
    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: TallyColors.cream,
      canvasColor: TallyColors.cream,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: TallyColors.ink,
        displayColor: TallyColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: TallyColors.ink,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final cs = ColorScheme.fromSeed(
      seedColor: TallyColors.honey,
      brightness: Brightness.dark,
      primary: TallyColors.honey,
      onPrimary: Colors.white,
      secondary: TallyColors.copper,
      surface: TallyColors.inkDark,
      onSurface: TallyColors.cream,
    );
    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: TallyColors.inkDark,
      canvasColor: TallyColors.inkDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: TallyColors.cream,
        displayColor: TallyColors.cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: TallyColors.cream,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

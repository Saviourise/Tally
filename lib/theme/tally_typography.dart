import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tally typography.
///
/// Display: Bricolage Grotesque — playful, variable, modern; pairs friendliness
/// with editorial weight.
/// Body: Plus Jakarta Sans — clean, geometric, very legible at small sizes.
class TallyType {
  TallyType._();

  static TextStyle display(Color color, {double size = 56, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.bricolageGrotesque(
        color: color,
        fontSize: size,
        fontWeight: w,
        height: 1.0,
        letterSpacing: -1.6,
      );

  static TextStyle displayItalic(Color color, {double size = 56}) =>
      GoogleFonts.bricolageGrotesque(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 1.0,
        letterSpacing: -1.4,
      );

  static TextStyle headline(Color color, {double size = 28}) =>
      GoogleFonts.bricolageGrotesque(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.8,
      );

  static TextStyle title(Color color, {double size = 18}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle body(Color color, {double size = 15}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle label(Color color, {double size = 12}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.0,
      );

  static TextStyle mono(Color color, {double size = 14}) =>
      GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w500,
      );
}

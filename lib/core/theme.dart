import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna Sinau (sama dengan prototipe).
class C {
  static const primary = Color(0xFF4338CA);
  static const primary50 = Color(0xFFEEEDFC);
  static const reward = Color(0xFFF2A20C);
  static const reward50 = Color(0xFFFDF1D8);
  static const ink = Color(0xFF171A2B);
  static const ink2 = Color(0xFF4A4E66);
  static const ink3 = Color(0xFF8B8FAE);
  static const bg = Color(0xFFFFFEFA);
  static const bg2 = Color(0xFFF4F2EB);
  static const line = Color(0xFFE7E4DA);
  static const ok = Color(0xFF1F9D6B);
  static const ok50 = Color(0xFFE2F4EC);
  static const err = Color(0xFFC2372B);
  static const err50 = Color(0xFFFBE4E1);
  static const python = Color(0xFF3776AB);
  static const java = Color(0xFFE76F00);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary, surface: C.bg, error: C.err),
    scaffoldBackgroundColor: C.bg,
  );
  final body = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink);
  TextStyle h(double s) => GoogleFonts.rubik(fontSize: s, fontWeight: FontWeight.w600, color: C.ink);
  return base.copyWith(
    textTheme: body.copyWith(
      headlineMedium: h(26), headlineSmall: h(22), titleLarge: h(19), titleMedium: h(16.5), titleSmall: h(14.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg, surfaceTintColor: Colors.transparent, elevation: 0, foregroundColor: C.ink,
      titleTextStyle: h(19),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.primary, minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52), foregroundColor: C.ink, side: const BorderSide(color: C.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.err, width: 1.5)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white, indicatorColor: C.primary50, elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w700)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: C.ink),
  );
}

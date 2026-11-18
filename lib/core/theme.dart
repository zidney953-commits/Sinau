import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu set warna (terang atau gelap).
class Palette {
  final Color primary, primary50, reward, reward50, ink, ink2, ink3, bg, bg2, line, ok, ok50, err, err50, surface, night;
  const Palette({
    required this.primary, required this.primary50, required this.reward, required this.reward50,
    required this.ink, required this.ink2, required this.ink3, required this.bg, required this.bg2, required this.line,
    required this.ok, required this.ok50, required this.err, required this.err50, required this.surface, required this.night,
  });
}

const lightPalette = Palette(
  primary: Color(0xFF4338CA), primary50: Color(0xFFEEEDFC),
  reward: Color(0xFFF2A20C), reward50: Color(0xFFFDF1D8),
  ink: Color(0xFF171A2B), ink2: Color(0xFF4A4E66), ink3: Color(0xFF8B8FAE),
  bg: Color(0xFFFFFEFA), bg2: Color(0xFFF4F2EB), line: Color(0xFFE7E4DA),
  ok: Color(0xFF1F9D6B), ok50: Color(0xFFE2F4EC),
  err: Color(0xFFC2372B), err50: Color(0xFFFBE4E1),
  surface: Colors.white, night: Color(0xFF171A2B),
);

const darkPalette = Palette(
  primary: Color(0xFF6C63F0), primary50: Color(0xFF26254A),
  reward: Color(0xFFF2A20C), reward50: Color(0xFF3A2E14),
  ink: Color(0xFFF1F1F7), ink2: Color(0xFFC3C5D8), ink3: Color(0xFF8D90AA),
  bg: Color(0xFF0F1120), bg2: Color(0xFF1D2036), line: Color(0xFF2B2F48),
  ok: Color(0xFF34C38A), ok50: Color(0xFF13342A),
  err: Color(0xFFEF5A4E), err50: Color(0xFF3B1C1E),
  surface: Color(0xFF171A2B), night: Color(0xFF23273F),
);

/// Palet warna Sinau. Nilainya mengikuti mode tampilan (terang / gelap) yang aktif.
/// Diatur oleh ThemeController; setelah berganti, seluruh layar digambar ulang.
class C {
  static Palette p = lightPalette;
  static bool get dark => identical(p, darkPalette);

  static Color get primary => p.primary;
  static Color get primary50 => p.primary50;
  static Color get reward => p.reward;
  static Color get reward50 => p.reward50;
  static Color get ink => p.ink;
  static Color get ink2 => p.ink2;
  static Color get ink3 => p.ink3;
  static Color get bg => p.bg;
  static Color get bg2 => p.bg2;
  static Color get line => p.line;
  static Color get ok => p.ok;
  static Color get ok50 => p.ok50;
  static Color get err => p.err;
  static Color get err50 => p.err50;

  /// Latar kartu / panel (putih di mode terang).
  static Color get surface => p.surface;

  /// Kartu gelap (target harian, streak, kode) — tetap gelap di kedua mode.
  static Color get night => p.night;

  /// Teks cokelat-kuning di atas reward50 (pin, tips, status "Baru").
  static Color get rewardInk => dark ? const Color(0xFFF5C362) : const Color(0xFF8A5A00);
  static Color get rewardInk2 => dark ? const Color(0xFFF0D9A8) : const Color(0xFF5C3D00);
  static Color get okLine => dark ? const Color(0xFF235C47) : const Color(0xFFBFE6D3);

  /// Teks/ikon di atas warna kuning (reward) — selalu gelap.
  static const onReward = Color(0xFF171A2B);
  static const python = Color(0xFF3776AB);
  static const java = Color(0xFFE76F00);
}

ThemeData buildTheme(Palette p) {
  final isDark = identical(p, darkPalette);
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary, brightness: isDark ? Brightness.dark : Brightness.light,
      primary: p.primary, onPrimary: Colors.white, surface: p.bg, onSurface: p.ink, error: p.err,
    ),
    scaffoldBackgroundColor: p.bg,
    dividerColor: p.line,
  );
  final body = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);
  TextStyle h(double s) => GoogleFonts.rubik(fontSize: s, fontWeight: FontWeight.w600, color: p.ink);
  return base.copyWith(
    textTheme: body.copyWith(
      headlineMedium: h(26), headlineSmall: h(22), titleLarge: h(19), titleMedium: h(16.5), titleSmall: h(14.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg, surfaceTintColor: Colors.transparent, elevation: 0, foregroundColor: p.ink,
      titleTextStyle: h(19),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52), foregroundColor: p.ink, side: BorderSide(color: p.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.primary)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.err, width: 1.5)),
    ),
    cardTheme: CardThemeData(
      color: p.surface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.line)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.bg),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.bg),
    popupMenuTheme: PopupMenuThemeData(color: p.surface),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface, indicatorColor: p.primary50, elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.nunitoSans(fontSize: 12, fontWeight: FontWeight.w700, color: p.ink)),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: p.night),
  );
}

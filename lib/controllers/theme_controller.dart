import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

/// Mode tampilan: Terang, Gelap, atau ikut sistem perangkat. Disimpan di perangkat (shared_preferences).
class ThemeController extends GetxController with WidgetsBindingObserver {
  static const _key = 'theme_mode';
  final mode = ThemeMode.system.obs;

  /// Palet yang sedang dipakai (berubah saat mode / tema perangkat berubah).
  final palette = lightPalette.obs;

  static const labels = {ThemeMode.light: 'Terang', ThemeMode.dark: 'Gelap', ThemeMode.system: 'Sistem'};

  /// Dipanggil sebelum runApp agar layar pertama langsung memakai tema yang benar.
  Future<void> init() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      mode.value = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (_) {}
    _apply(redraw: false);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Tema HP/laptop berubah (mis. mode gelap otomatis malam hari).
  @override
  void didChangePlatformBrightness() {
    if (mode.value == ThemeMode.system) _apply();
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    _apply();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, m.name);
    } catch (_) {}
  }

  void _apply({bool redraw = true}) {
    final sysDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final dark = mode.value == ThemeMode.dark || (mode.value == ThemeMode.system && sysDark);
    final p = dark ? darkPalette : lightPalette;
    if (identical(p, C.p) && identical(p, palette.value)) return;
    C.p = p;
    palette.value = p;
    // Warna C.* dibaca saat build, jadi semua layar digambar ulang.
    if (redraw) Get.forceAppUpdate();
  }
}

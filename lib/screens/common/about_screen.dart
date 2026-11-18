import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

/// Tentang Aplikasi: logo, versi, brand pengembang, tanggal terbit, dan penjelasan Sinau.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PageHeader('Tentang Aplikasi', onBack: Get.back),
                Expanded(
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
                    Center(
                      child: Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: C.line),
                        ),
                        child: const Center(child: LogoMark(size: 58)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(child: Text('Sinau', style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 4),
                    const Center(child: Pill('Versi ${AppConfig.version}')),
                    const SizedBox(height: 14),
                    Center(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Powered by '),
                          TextSpan(text: AppConfig.brand, style: GoogleFonts.rubik(fontWeight: FontWeight.w800, color: C.ink, letterSpacing: 1)),
                        ]),
                        style: const TextStyle(color: C.ink2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('APK Sinau - Terbit ${AppConfig.releaseDate}', style: TextStyle(color: C.ink3, fontSize: 12.5)),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Apa itu SINAU?', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text(
                          'Sinau (bahasa Jawa: “belajar”) adalah aplikasi belajar pemrograman dari dasar untuk siapa saja, '
                          'terutama pemula yang masih bingung harus mulai dari mana. Aplikasi ini dibuat agar belajar '
                          'pemrograman terasa lebih mudah dan konsisten: materi disusun bertahap dalam bahasa Indonesia, '
                          'setiap pembahasan singkat dan langsung diakhiri tugas untuk berlatih, lalu kemajuan belajar '
                          'tercatat lewat XP, streak, dan papan peringkat sehingga pengguna tetap semangat belajar setiap hari.',
                          style: TextStyle(color: C.ink2, height: 1.55),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

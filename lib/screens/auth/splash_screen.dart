import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () => Get.find<AuthController>().boot());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.ink,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: const Center(child: LogoMark(size: 50)),
            ),
            const SizedBox(height: 20),
            Text('Sinau', style: GoogleFonts.rubik(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Belajar pemrograman, satu level setiap hari', style: TextStyle(color: Color(0xFFB9BCD3))),
            const SizedBox(height: 40),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.reward)),
          ]),
        ),
      );
}

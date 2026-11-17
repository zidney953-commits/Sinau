import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controllers.dart';
import '../../core/theme.dart';
import '../../widgets/responsive.dart';
import '../common/feedback_sheet.dart';
import '../common/info_screen.dart';
import '../common/profile_screen.dart';
import 'learn_screen.dart';
import 'rank_screen.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key});
  static const _names = ['Belajar', 'Informasi', 'Peringkat', 'Profil'];

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    // Obx: menu & halaman aktif mengikuti nav.tab (reactive).
    return Obx(() => AppShell(
        index: nav.tab.value,
        onSelect: nav.go,
        items: const [
          NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Belajar'),
          NavItem(Icons.notifications_none_rounded, Icons.notifications_rounded, 'Informasi'),
          NavItem(Icons.leaderboard_outlined, Icons.leaderboard, 'Peringkat'),
          NavItem(Icons.person_outline, Icons.person, 'Profil'),
        ],
        pages: const [LearnScreen(), InfoScreen(), RankScreen(), ProfileScreen()],
        fab: FloatingActionButton.extended(
          heroTag: 'fb',
          backgroundColor: C.ink,
          foregroundColor: Colors.white,
          elevation: 2,
          onPressed: () => Get.bottomSheet(FeedbackSheet(page: _names[nav.tab.value]), isScrollControlled: true),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          label: const Text('Ada saran atau error?', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ));
  }
}

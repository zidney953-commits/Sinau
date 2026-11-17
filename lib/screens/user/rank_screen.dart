import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

/// Peringkat XP per bahasa (seperti prototipe).
class RankScreen extends StatelessWidget {
  const RankScreen({super.key});
  RankController get c => Get.find<RankController>();

  @override
  Widget build(BuildContext context) {
    final me = Get.find<AuthController>().profile.value!;
    // Obx: judul & pilihan bahasa ikut berubah saat c.lang (reactive) berubah.
    return Obx(() => SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader('Peringkat', subtitle: 'Peringkat pengguna ${c.langName}', trailing: Avatar(me.name, url: me.avatarUrl, size: 38)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: C.bg2, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              for (final l in const [('python', 'Python', C.python), ('java', 'Java', C.java)])
                Expanded(
                  child: GestureDetector(
                    onTap: () => c.setLang(l.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: c.lang.value == l.$1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: c.lang.value == l.$1 ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))] : null,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.code_rounded, size: 18, color: l.$3),
                        const SizedBox(width: 6),
                        Text(l.$2, style: TextStyle(fontWeight: FontWeight.w800, color: c.lang.value == l.$1 ? C.primary : C.ink2)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.load,
            child: ObxLoad<List<Map<String, dynamic>>>(
              controller: c,
              builder: (rows) {
                final myIdx = rows.indexWhere((r) => r['user_id'] == me.id);
                return Stack(children: [
                  ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 160), children: [
                    Text('Peringkat ${c.langName} · urut XP ${c.langName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (rows.isEmpty)
                      const StateView(icon: Icons.emoji_events_outlined, color: C.reward, title: 'Belum ada peringkat', body: 'Jadilah yang pertama menyelesaikan pembahasan di bahasa ini.')
                    else
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                        child: Column(children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) const Divider(height: 1, color: C.line),
                            _RankRow(rank: i + 1, row: rows[i], me: rows[i]['user_id'] == me.id),
                          ],
                        ]),
                      ),
                    const SizedBox(height: 12),
                    Text('Hanya pengguna yang sudah menyelesaikan pembahasan ${c.langName}. XP dihitung dari belajar ${c.langName} saja.',
                        textAlign: TextAlign.center, style: const TextStyle(color: C.ink3, fontSize: 12.5)),
                  ]),
                  if (!me.isAdmin)
                    Positioned(
                      left: 20, right: 20, bottom: 84,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Avatar(me.name, url: me.avatarUrl, size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(myIdx < 0 ? 'Belum masuk peringkat ${c.langName}' : 'Posisi kamu di ${c.langName}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              Text(myIdx < 0 ? 'Selesaikan 1 pembahasan' : '#${myIdx + 1} dari ${rows.length} pengguna',
                                  style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          if (myIdx >= 0) Pill('${rows[myIdx]['xp']} XP', bg: C.reward, fg: C.ink),
                        ]),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ),
      ]),
    ));
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> row;
  final bool me;
  const _RankRow({required this.rank, required this.row, required this.me});
  @override
  Widget build(BuildContext context) {
    const medal = [C.reward, Color(0xFFA6A9BC), Color(0xFFC07A3A)];
    return Container(
      color: me ? C.primary50 : null,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: rank <= 3 ? medal[rank - 1] : C.bg2, shape: BoxShape.circle),
          child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: rank <= 3 ? C.ink : C.ink3))),
        ),
        const SizedBox(width: 10),
        Avatar(row['name'], url: row['avatar_url'], size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${row['name']}${me ? ' (kamu)' : ''}', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
            Text('${row['lessons_done']} pembahasan selesai', style: const TextStyle(color: C.ink3, fontSize: 12)),
          ]),
        ),
        Text('${row['xp']} XP', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

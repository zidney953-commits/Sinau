import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/streak.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import 'learn_extras.dart';
import 'lesson_screen.dart';

const unitIcons = [Icons.memory_rounded, Icons.data_object_rounded, Icons.call_split_rounded, Icons.loop_rounded];
const unitColor = Color(0xFF5B4FD6);

/// Tab Belajar: sapaan (foto & nama), target harian, lalu pilih bahasa.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  LearnController get c => Get.find<LearnController>();
  Future<void> _reload() => c.load();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          Get.find<NewsController>().load();
          await _reload();
        },
        child: ObxLoad<LearnData>(
          controller: c,
          builder: (d) {
            final p = auth.profile.value!;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
                Row(children: [
                  Avatar(p.name, url: p.avatarUrl, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Halo,', style: TextStyle(color: C.ink3, fontSize: 12)),
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  _StreakChip(d.streak),
                  const SizedBox(width: 8),
                  _Chip(Icons.star_rounded, '${d.xpTotal}', C.primary),
                ]),
                const SizedBox(height: 16),
                _TargetCard(xp: d.xpToday, lastChance: d.streak.lastChance),
                const SizedBox(height: 22),
                const NewsSection(),
                const SizedBox(height: 24),
                Text('Belajar Bahasa Pemrograman', style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700)),
                Text('Pilih salah satu bahasa di bawah', style: TextStyle(color: C.ink3, fontSize: 12.5)),
                const SizedBox(height: 10),
                Text('Mau belajar dasar pemrograman dengan bahasa apa? Materi dan tugasnya sama, hanya contoh kodenya yang berbeda.',
                    style: TextStyle(color: C.ink2, height: 1.5)),
                const SizedBox(height: 16),
                ResponsiveColumns(children: [
                  for (final l in d.langs)
                    _LangCard(lang: l, units: d.units[l.id]!, prog: d.prog, onTap: () async {
                      await Get.to(() => LangHomeScreen(lang: l));
                      _reload();
                    }),
                ]),
                const SizedBox(height: 24),
                Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: const PromoPost())),
              ]);
          },
        ),
      ),
    );
  }
}

/// Logo resmi tiap bahasa (assets/icon). Bahasa lain memakai singkatan teks.
const langLogos = {'python': 'assets/icon/python.webp', 'java': 'assets/icon/java.png'};

class LangTile extends StatelessWidget {
  final Language lang;
  final double size;
  const LangTile(this.lang, {super.key, this.size = 64});
  @override
  Widget build(BuildContext context) {
    final c = Color(lang.color);
    final logo = langLogos[lang.id];
    return Container(
      width: size, height: size * 1.25,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(color: c.withValues(alpha: .1), borderRadius: BorderRadius.circular(size * .22)),
      child: Center(
        child: logo != null
            ? Image.asset(logo, fit: BoxFit.contain, semanticLabel: 'Logo ${lang.name}', filterQuality: FilterQuality.medium)
            : Text(lang.mono, style: GoogleFonts.jetBrainsMono(color: c, fontWeight: FontWeight.w800, fontSize: size * .3)),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final Language lang;
  final List<Unit> units;
  final Map<int, LessonProgress> prog;
  final VoidCallback onTap;
  const _LangCard({required this.lang, required this.units, required this.prog, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final ls = units.expand((u) => u.lessons).toList();
    final done = ls.where((l) => prog[l.id]?.passed ?? false).length;
    return Material(
      color: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: C.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LangTile(lang),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(lang.name, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right, color: C.ink3),
                ]),
                Text(lang.description, style: TextStyle(color: C.ink2, fontSize: 13, height: 1.45)),
                const SizedBox(height: 8),
                Text('${units.length} tugas · ${ls.length} pembahasan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: ls.isEmpty ? 0 : done / ls.length, minHeight: 6, color: C.primary, backgroundColor: C.bg2),
                ),
                const SizedBox(height: 6),
                Text(done == 0 ? 'Belum dimulai' : '$done dari ${ls.length} pembahasan selesai', style: TextStyle(fontSize: 12, color: C.ink3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Beranda satu bahasa: lanjutkan dan daftar Tugas 1–4.
class LangHomeScreen extends StatelessWidget {
  final Language lang;
  const LangHomeScreen({super.key, required this.lang});
  LearnController get c => Get.find<LearnController>();
  Future<void> _reload() => c.load();

  Future<void> _open(Widget page) async {
    await Get.to(() => page);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ObxLoad<LearnData>(
              controller: c,
              builder: (d) {
                final units = d.units[lang.id]!.where((u) => u.lessons.isNotEmpty).toList();
                Lesson? next;
                int nextUnit = 0;
                for (var i = 0; i < units.length && next == null; i++) {
                  for (final l in units[i].lessons) {
                    if (!(d.prog[l.id]?.passed ?? false)) {
                      next = l;
                      nextUnit = i;
                      break;
                    }
                  }
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
                    Row(children: [
                      IconButton(onPressed: Get.back, icon: const Icon(Icons.chevron_left, size: 28), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      LangTile(lang, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Dasar Pemrograman', style: TextStyle(color: C.ink3, fontSize: 12)),
                          Text(lang.name, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      TextButton(onPressed: Get.back, child: const Text('Ganti bahasa', style: TextStyle(fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 16),
                    if (next != null) ...[
                      _ContinueCard(
                        unitTitle: units[nextUnit].title,
                        lesson: next,
                        onTap: () => _open(LessonScreen(lesson: next!, prev: d.prog[next.id])),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text('${units.length} tugas', style: TextStyle(color: C.ink3, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    ResponsiveColumns(gap: 12, children: [
                      for (var i = 0; i < units.length; i++)
                        _UnitCard(
                          unit: units[i], index: i, prog: d.prog,
                          onTap: () => _open(LessonListScreen(unit: units[i], index: i, lang: lang)),
                        ),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip(this.icon, this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Chip streak di sapaan: warna petir mengikuti level streak.
class _StreakChip extends StatelessWidget {
  final StreakInfo s;
  const _StreakChip(this.s);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          StreakFlame(s.todayDone ? s.level : null, size: 22),
          const SizedBox(width: 6),
          Text('${s.current}', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _TargetCard extends StatelessWidget {
  final int xp;
  final bool lastChance;
  const _TargetCard({required this.xp, this.lastChance = false});
  @override
  Widget build(BuildContext context) {
    final pct = (xp / dailyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.night, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        SizedBox(
          width: 56, height: 56,
          child: CustomPaint(
            painter: _RingPainter(pct),
            child: Center(child: Text('${(pct * 100).round()}%', style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Target harian · ${math.min(xp, dailyGoal)}/$dailyGoal XP', style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 2),
            Text(
                pct >= 1
                    ? 'Target tercapai. Streak hari ini menyala!'
                    : lastChance
                        ? 'Hari terakhir! Capai target hari ini atau streak kembali ke 0.'
                        : 'Kumpulkan ${dailyGoal - xp} XP lagi agar streak hari ini menyala.',
                style: const TextStyle(color: Color(0xFFB9BCD3), fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  _RingPainter(this.pct);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(4, 4, s.width - 8, s.height - 8);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white12;
    c.drawArc(r, 0, math.pi * 2, false, base);
    c.drawArc(r, -math.pi / 2, math.pi * 2 * pct, false, base..color = C.reward..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.pct != pct;
}

class _ContinueCard extends StatelessWidget {
  final String unitTitle;
  final Lesson lesson;
  final VoidCallback onTap;
  const _ContinueCard({required this.unitTitle, required this.lesson, required this.onTap});
  @override
  Widget build(BuildContext context) => SectionCard(
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: C.primary50, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.play_arrow_rounded, color: C.primary, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lanjutkan · $unitTitle', style: TextStyle(color: C.ink3, fontSize: 12)),
              Text(lesson.title, style: GoogleFonts.rubik(fontSize: 16.5, fontWeight: FontWeight.w600)),
              Text('Materi + tugas · ${lesson.durationMin} menit', style: TextStyle(color: C.ink3, fontSize: 12)),
            ]),
          ),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(72, 40)), onPressed: onTap, child: const Text('Mulai')),
        ]),
      );
}

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final int index;
  final Map<int, LessonProgress> prog;
  final VoidCallback onTap;
  const _UnitCard({required this.unit, required this.index, required this.prog, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final done = unit.lessons.where((l) => prog[l.id]?.passed ?? false).length;
    final n = unit.lessons.length;
    final complete = done == n;
    return Material(
      color: complete ? C.ok : unitColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(children: [
          Positioned(right: -8, top: -6, child: Icon(unitIcons[index % unitIcons.length], size: 76, color: Colors.white.withValues(alpha: .14))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TUGAS ${index + 1}', style: GoogleFonts.rubik(color: Colors.white70, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              Text(unit.title, style: GoogleFonts.rubik(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: n == 0 ? 0 : done / n, minHeight: 5, color: C.reward, backgroundColor: Colors.white24),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Text('$done dari $n pembahasan selesai', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text(complete ? 'Ulangi' : (done > 0 ? 'Lanjut' : 'Mulai'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Daftar pembahasan satu Tugas: selesai / aktif / terkunci (berurutan).
class LessonListScreen extends StatelessWidget {
  final Unit unit;
  final int index;
  final Language lang;
  const LessonListScreen({super.key, required this.unit, required this.index, required this.lang});
  LearnController get c => Get.find<LearnController>();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PageHeader('Tugas ${index + 1} · ${lang.name}', onBack: Get.back),
                Expanded(
                  child: ObxLoad<LearnData>(
                    controller: c,
                    builder: (d) {
                      final prog = d.prog;
                      final ls = unit.lessons;
                      final done = ls.where((l) => prog[l.id]?.passed ?? false).length;
                      final activeIdx = ls.indexWhere((l) => !(prog[l.id]?.passed ?? false));
                      return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                        IgnorePointer(child: _UnitCard(unit: unit, index: index, prog: prog, onTap: () {})),
                        const SizedBox(height: 16),
                        Text('Pembahasan · ${ls.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                          child: Column(children: [
                            for (var i = 0; i < ls.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: C.line),
                              _LessonRow(
                                lesson: ls[i], no: i + 1,
                                status: (prog[ls[i].id]?.passed ?? false) ? 'done' : (i == activeIdx ? 'act' : 'lock'),
                                onTap: () async {
                                  await Get.to(() => LessonScreen(lesson: ls[i], prev: prog[ls[i].id]));
                                  c.load(); // progres & XP terbaru
                                },
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          done == ls.length
                              ? 'Semua pembahasan di tugas ini sudah selesai. Kamu bisa mengulang kapan saja.'
                              : 'Setiap pembahasan diakhiri tugas. Pembahasan berikutnya terbuka setelah tugas lulus (minimal 2 benar).',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: C.ink3, fontSize: 12.5),
                        ),
                      ]);
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final int no;
  final String status;
  final VoidCallback onTap;
  const _LessonRow({required this.lesson, required this.no, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final lock = status == 'lock';
    final circle = switch (status) {
      'done' => Container(width: 36, height: 36, decoration: BoxDecoration(color: C.reward, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: C.onReward, size: 20)),
      'act' => Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: C.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.primary.withValues(alpha: .25), spreadRadius: 4)]),
          child: Center(child: Text('$no', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
      _ => Container(width: 36, height: 36, decoration: BoxDecoration(color: C.bg2, shape: BoxShape.circle), child: Icon(Icons.lock_outline, color: C.ink3, size: 18)),
    };
    return InkWell(
      onTap: lock ? () => toast('Selesaikan pembahasan sebelumnya dulu.') : onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          circle,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.title, style: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 15, color: lock ? C.ink3 : C.ink)),
              Text('Materi + tugas 3 soal · ${lesson.durationMin} menit · ${lesson.xp} XP', style: TextStyle(color: C.ink3, fontSize: 12)),
            ]),
          ),
          switch (status) {
            'done' => Pill('Selesai', bg: C.reward50, fg: C.rewardInk),
            'act' => const Pill('Mulai'),
            _ => const Text('Terkunci', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          },
        ]),
      ),
    );
  }
}

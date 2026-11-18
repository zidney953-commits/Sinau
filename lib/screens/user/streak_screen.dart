import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../core/theme.dart';
import '../../data/streak.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

const _bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Detail streak: ringkasan, kalender per bulan/tahun, dan daftar level warna.
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learn = Get.find<LearnController>();
    final cal = Get.find<StreakController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PageHeader('Streak', subtitle: 'Hari menyala berturut-turut', onBack: Get.back),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: learn.load,
                  child: ObxLoad<LearnData>(
                    controller: learn,
                    builder: (d) => ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
                      _Summary(s: d.streak),
                      const SizedBox(height: 16),
                      Obx(() => _Calendar(s: d.streak, c: cal, month: cal.month.value)),
                      const SizedBox(height: 16),
                      _Levels(current: d.streak.level),
                      const SizedBox(height: 14),
                      const Text(
                        'Hari menyala jika target harian $dailyGoal XP tercapai (100%). '
                        'Streak kembali ke 0 jika $streakGraceDays hari berturut-turut tidak menyala.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: C.ink3, fontSize: 12.5, height: 1.45),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final StreakInfo s;
  const _Summary({required this.s});

  @override
  Widget build(BuildContext context) {
    final lv = s.level;
    Widget stat(String v, String l) => Expanded(
          child: Column(children: [
            Text(v, style: GoogleFonts.rubik(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(l, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E91AB), fontSize: 11.5)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        StreakFlame(s.todayDone ? lv : null, size: 76, offColor: const Color(0xFF2B2F48)),
        const SizedBox(height: 12),
        Text('${s.current} hari', style: GoogleFonts.rubik(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        Text(
          lv == null ? 'Streak belum menyala' : 'Level ${lv.level} · ${lv.name}',
          style: TextStyle(color: lv == null || lv.level == 1 ? const Color(0xFFB9BCD3) : lv.color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          s.todayDone
              ? 'Hari ini sudah menyala.'
              : s.lastChance
                  ? 'Hari terakhir! Capai target hari ini atau streak kembali ke 0.'
                  : 'Hari ini ${s.xpToday}/$dailyGoal XP. Capai target untuk menyalakan hari ini.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB9BCD3), fontSize: 13),
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFF2B2F48), height: 1),
        const SizedBox(height: 12),
        Row(children: [
          stat('${s.longest}', 'Streak terpanjang'),
          stat('${s.chain.length}', 'Total hari menyala'),
          stat('${s.xpToday}', 'XP hari ini'),
        ]),
      ]),
    );
  }
}

class _Calendar extends StatelessWidget {
  final StreakInfo s;
  final StreakController c;
  final DateTime month;
  const _Calendar({required this.s, required this.c, required this.month});

  @override
  Widget build(BuildContext context) {
    final today = todayKey();
    final first = DateTime.utc(month.year, month.month);
    final nDays = DateTime.utc(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1; // Senin = kolom pertama
    final firstYear = s.chain.isEmpty ? today.year : s.chain.keys.first.year;
    final years = [for (var y = firstYear < today.year - 1 ? firstYear : today.year - 1; y <= today.year; y++) y];
    final lit = s.chain.keys.where((k) => k.year == month.year && k.month == month.month).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => c.shift(-1), icon: const Icon(Icons.chevron_left), tooltip: 'Bulan sebelumnya'),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Picker(
                label: _bulan[month.month - 1],
                items: [for (var m = 1; m <= 12; m++) (m, _bulan[m - 1], !(month.year == today.year && m > today.month))],
                onSelected: c.setMonth,
              ),
              const SizedBox(width: 6),
              _Picker(label: '${month.year}', items: [for (final y in years) (y, '$y', true)], onSelected: c.setYear),
            ]),
          ),
          IconButton(onPressed: c.canNext ? () => c.shift(1) : null, icon: const Icon(Icons.chevron_right), tooltip: 'Bulan berikutnya'),
        ]),
        Text('$lit hari menyala di bulan ini', style: const TextStyle(color: C.ink3, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          for (final h in _hari)
            Expanded(child: Center(child: Text(h, style: const TextStyle(color: C.ink3, fontSize: 12, fontWeight: FontWeight.w800)))),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (_, box) {
          final cell = box.maxWidth / 7;
          final dot = (cell * .78).clamp(28.0, 46.0);
          final rows = ((lead + nDays) / 7).ceil();
          return Column(children: [
            for (var r = 0; r < rows; r++)
              Row(children: [
                for (var col = 0; col < 7; col++)
                  SizedBox(
                    width: cell, height: dot + 10,
                    child: Center(child: _cellFor(r * 7 + col - lead + 1, nDays, today, dot)),
                  ),
              ]),
          ]);
        }),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
          _Legend(color: (s.level ?? streakLevels.first).color, label: 'Menyala (warna sesuai level)'),
          const _Legend(color: Color(0xFFF6D58E), label: 'Belajar, belum 100%', ring: true),
          const _Legend(color: C.primary, label: 'Hari ini', ring: true),
        ]),
      ]),
    );
  }

  Widget _cellFor(int day, int nDays, DateTime today, double size) {
    if (day < 1 || day > nDays) return const SizedBox();
    final date = DateTime.utc(month.year, month.month, day);
    final lv = s.levelOn(date);
    final isToday = date == today;
    final future = date.isAfter(today);
    final partial = lv == null && s.xpOn(date) > 0;
    final border = isToday
        ? Border.all(color: C.primary, width: 2)
        : partial
            ? Border.all(color: const Color(0xFFF6D58E), width: 2)
            : lv?.level == 5
                ? Border.all(color: const Color(0xFFD9D6E8))
                : null;
    return Tooltip(
      message: lv != null ? 'Hari ke-${s.chain[date]} · ${s.xpOn(date)} XP' : '${s.xpOn(date)} XP',
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: lv?.color ?? (future ? Colors.transparent : C.bg2),
          shape: BoxShape.circle,
          border: border,
          boxShadow: lv != null && lv.glow ? [BoxShadow(color: (lv.level == 5 ? const Color(0xFFFFE9A8) : lv.color).withValues(alpha: .7), blurRadius: size * .35)] : null,
        ),
        child: Center(
          child: Text('$day',
              style: TextStyle(
                fontWeight: lv != null || isToday ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: lv?.onColor ?? (future ? C.ink3.withValues(alpha: .5) : C.ink2),
              )),
        ),
      ),
    );
  }
}

/// Tombol kecil berisi pilihan (bulan / tahun).
class _Picker extends StatelessWidget {
  final String label;
  final List<(int, String, bool)> items;
  final ValueChanged<int> onSelected;
  const _Picker({required this.label, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
        onSelected: onSelected,
        color: Colors.white,
        itemBuilder: (_) => [for (final i in items) PopupMenuItem(value: i.$1, enabled: i.$3, child: Text(i.$2))],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: C.primary50, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 16, color: C.ink)),
            const Icon(Icons.arrow_drop_down, color: C.primary),
          ]),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool ring;
  const _Legend({required this.color, required this.label, this.ring = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: ring ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: ring ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5, color: C.ink2)),
      ]);
}

class _Levels extends StatelessWidget {
  final StreakLevel? current;
  const _Levels({required this.current});

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Level warna streak',
        subtitle: 'Warna api berubah sesuai jumlah hari streak.',
        child: Column(children: [
          for (final l in streakLevels)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: current?.level == l.level ? C.primary50 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                StreakFlame(l, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Level ${l.level} · ${l.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(l.range, style: const TextStyle(color: C.ink3, fontSize: 12)),
                  ]),
                ),
                if (current?.level == l.level) const Pill('Sekarang'),
              ]),
            ),
        ]),
      );
}

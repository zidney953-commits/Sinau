import 'package:flutter/material.dart';

/// Target XP per hari. Hari "menyala" hanya jika target ini tercapai (100%).
const dailyGoal = 30;

/// Streak mati (kembali 0) jika target harian tidak tercapai 3 hari berturut-turut.
const streakGraceDays = 3;

/// Tanggal lokal (tanpa jam) sebagai DateTime UTC, supaya selisih hari selalu tepat.
DateTime dayKey(DateTime t) {
  final l = t.toLocal();
  return DateTime.utc(l.year, l.month, l.day);
}

DateTime todayKey() => dayKey(DateTime.now());

class StreakLevel {
  final int level, min;
  final int? max;
  final String name;
  final Color color;

  /// Ikon di atas warna ini (gelap untuk warna terang).
  final Color onColor;

  /// Level "menyala": diberi cahaya di sekelilingnya.
  final bool glow;
  const StreakLevel(this.level, this.min, this.max, this.name, this.color, this.onColor, {this.glow = false});

  String get range => max == null ? '$min+ hari' : '$min–$max hari';
}

const _ink = Color(0xFF171A2B);

const streakLevels = [
  StreakLevel(1, 1, 3, 'Merah Tua', Color(0xFF8B1E1E), Colors.white),
  StreakLevel(2, 4, 10, 'Merah Terang', Color(0xFFFF3B30), Colors.white),
  StreakLevel(3, 11, 25, 'Oranye Menyala', Color(0xFFFF8A00), Colors.white, glow: true),
  StreakLevel(4, 26, 45, 'Kuning Menyala', Color(0xFFFFD21F), _ink, glow: true),
  StreakLevel(5, 46, 70, 'Putih', Color(0xFFFFFFFF), _ink, glow: true),
  StreakLevel(6, 71, 130, 'Hijau', Color(0xFF1FB86A), Colors.white),
  StreakLevel(7, 131, 200, 'Biru', Color(0xFF2F7BEA), Colors.white),
  StreakLevel(8, 201, null, 'Ungu Menyala', Color(0xFFA040FF), Colors.white, glow: true),
];

/// Level untuk jumlah hari streak; null jika streak 0 (mati).
StreakLevel? levelFor(int days) {
  if (days <= 0) return null;
  return streakLevels.lastWhere((l) => days >= l.min);
}

/// Riwayat streak yang dihitung dari pembahasan yang lulus (lesson_progress).
class StreakInfo {
  /// XP per tanggal lokal.
  final Map<DateTime, int> dailyXp;

  /// Hari yang menyala (target tercapai) → urutan hari ke-berapa dalam rangkaian streak saat itu.
  final Map<DateTime, int> chain;

  /// Streak sekarang (0 = mati).
  final int current;

  /// Streak terpanjang yang pernah dicapai.
  final int longest;

  /// Hari terakhir yang menyala.
  final DateTime? lastActive;

  /// Berapa hari (sebelum hari ini) target terlewat sejak hari terakhir menyala.
  final int missed;

  const StreakInfo(this.dailyXp, this.chain, this.current, this.longest, this.lastActive, this.missed);

  factory StreakInfo.from(List<Map<String, dynamic>> done) {
    final xp = <DateTime, int>{};
    for (final r in done) {
      final t = DateTime.tryParse((r['completed_at'] ?? '').toString());
      if (t == null) continue;
      final k = dayKey(t);
      xp[k] = (xp[k] ?? 0) + ((r['xp_earned'] as num?)?.toInt() ?? 0);
    }
    final active = xp.entries.where((e) => e.value >= dailyGoal).map((e) => e.key).toList()..sort();
    final chain = <DateTime, int>{};
    DateTime? prev;
    var longest = 0;
    for (final d in active) {
      final gap = prev == null ? streakGraceDays : d.difference(prev).inDays - 1;
      final n = gap < streakGraceDays ? (chain[prev] ?? 0) + 1 : 1;
      chain[d] = n;
      if (n > longest) longest = n;
      prev = d;
    }
    final today = todayKey();
    var current = 0, missed = 0;
    if (prev != null) {
      missed = prev == today ? 0 : today.difference(prev).inDays - 1;
      current = missed < streakGraceDays ? chain[prev]! : 0;
    }
    return StreakInfo(xp, chain, current, longest, prev, missed);
  }

  int xpOn(DateTime day) => dailyXp[day] ?? 0;
  int get xpToday => xpOn(todayKey());
  bool get todayDone => chain.containsKey(todayKey());
  StreakLevel? get level => levelFor(current);

  /// Hari ini adalah kesempatan terakhir sebelum streak mati.
  bool get lastChance => current > 0 && !todayDone && missed == streakGraceDays - 1;

  /// Level warna untuk satu tanggal yang menyala (null jika tidak menyala).
  StreakLevel? levelOn(DateTime day) => chain[day] == null ? null : levelFor(chain[day]!);
}

/// Lingkaran berisi ikon petir dengan warna level streak (abu-abu jika mati).
class StreakFlame extends StatelessWidget {
  final StreakLevel? level;
  final double size;
  final Color offColor;
  const StreakFlame(this.level, {super.key, this.size = 30, this.offColor = const Color(0xFFEDEAF6)});

  @override
  Widget build(BuildContext context) {
    final l = level;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: l?.color ?? offColor,
        shape: BoxShape.circle,
        border: l?.level == 5 ? Border.all(color: const Color(0xFFD9D6E8)) : null,
        boxShadow: l != null && l.glow
            ? [BoxShadow(color: (l.level == 5 ? const Color(0xFFFFF4C2) : l.color).withValues(alpha: .75), blurRadius: size * .45, spreadRadius: size * .06)]
            : null,
      ),
      child: Icon(Icons.bolt_rounded, size: size * .62, color: l?.onColor ?? const Color(0xFF9A9CB0)),
    );
  }
}

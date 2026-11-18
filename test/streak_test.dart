import 'package:flutter_test/flutter_test.dart';
import 'package:sinau/data/streak.dart';

/// Satu hari menyala = 2 pembahasan (2 × 15 XP) pada [daysAgo] hari lalu (jam 10 waktu lokal).
List<Map<String, dynamic>> lit(List<int> daysAgo, {int xp = 30}) {
  final now = DateTime.now();
  return [
    for (final d in daysAgo)
      for (var i = 0; i < xp ~/ 15; i++)
        {'xp_earned': 15, 'completed_at': DateTime(now.year, now.month, now.day - d, 10).toUtc().toIso8601String()},
  ];
}

void main() {
  test('hari ini belum 100% → hari ini belum menyala', () {
    final s = StreakInfo.from(lit([0], xp: 15));
    expect(s.todayDone, isFalse);
    expect(s.current, 0);
    expect(s.xpToday, 15);
  });

  test('menyala berturut-turut', () {
    final s = StreakInfo.from(lit([2, 1, 0]));
    expect(s.current, 3);
    expect(s.todayDone, isTrue);
    expect(s.level!.level, 1);
  });

  test('terlewat 2 hari masih tersambung', () {
    final s = StreakInfo.from(lit([3, 0]));
    expect(s.current, 2);
  });

  test('terlewat 3 hari → mulai dari awal', () {
    final s = StreakInfo.from(lit([5, 4, 0]));
    expect(s.current, 1);
    expect(s.longest, 2);
  });

  test('3 hari tidak menyala sampai kemarin → streak 0', () {
    expect(StreakInfo.from(lit([4])).current, 0);
    final s = StreakInfo.from(lit([3]));
    expect(s.current, 1);
    expect(s.lastChance, isTrue);
  });

  test('level warna', () {
    expect(levelFor(0), isNull);
    expect(levelFor(3)!.level, 1);
    expect(levelFor(4)!.level, 2);
    expect(levelFor(25)!.level, 3);
    expect(levelFor(26)!.level, 4);
    expect(levelFor(70)!.level, 5);
    expect(levelFor(71)!.level, 6);
    expect(levelFor(200)!.level, 7);
    expect(levelFor(201)!.level, 8);
    expect(levelFor(999)!.level, 8);
  });
}

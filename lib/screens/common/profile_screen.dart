import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../data/streak.dart';
import '../user/streak_screen.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import 'about_screen.dart';

/// Profil (pengguna & admin). Hanya pengguna biasa yang bisa mengganti foto.
class ProfileScreen extends StatelessWidget {
  final bool showBack;
  const ProfileScreen({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final body = SafeArea(
      child: Obx(() {
        final p = auth.profile.value;
        if (p == null) return const SizedBox();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader('Profil',
              subtitle: 'Informasi akun yang sedang digunakan',
              onBack: showBack ? Get.back : null,
              trailing: IconButton(onPressed: () => _editName(p.name), icon: const Icon(Icons.edit_outlined), tooltip: 'Ubah nama')),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
              Center(
                child: Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: C.primary50),
                    child: Avatar(p.name, url: p.avatarUrl, size: 92),
                  ),
                  if (!p.isAdmin)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Material(
                        color: C.primary,
                        shape: CircleBorder(side: BorderSide(color: C.bg, width: 3)),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _photoSheet(p.avatarUrl != null),
                          child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Center(child: Text(p.name, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700))),
              Center(child: Text(p.email, style: TextStyle(color: C.ink3))),
              const SizedBox(height: 8),
              Center(
                child: Wrap(spacing: 6, children: [
                  Pill(p.isAdmin ? 'Admin' : 'User', icon: p.isAdmin ? Icons.shield_outlined : Icons.school_outlined),
                  if (!p.isAdmin && p.angkatan != null) Pill('Angkatan ${p.angkatan}', bg: C.bg2, fg: C.ink2),
                ]),
              ),
              const SizedBox(height: 18),
              if (!p.isAdmin) const _StreakKebun(),
              const SizedBox(height: 6),
              const Text('Informasi akun', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                child: Column(children: [
                  _InfoRow(Icons.person_outline, 'Nama', p.name),
                  Divider(height: 1, color: C.line),
                  _InfoRow(Icons.mail_outline, 'Email', p.email),
                  if (!p.isAdmin) ...[
                    Divider(height: 1, color: C.line),
                    _InfoRow(Icons.school_outlined, 'Angkatan', p.angkatan?.toString() ?? '-'),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              const _ThemePicker(),
              const SizedBox(height: 12),
              Material(
                color: C.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: C.line)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.to(() => const AboutScreen()),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(children: [
                      _IconBox(Icons.info_outline_rounded),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.w800)),
                          Text('Versi ${AppConfig.version} · Powered by ${AppConfig.brand}', style: TextStyle(color: C.ink3, fontSize: 12)),
                        ]),
                      ),
                      Icon(Icons.chevron_right, color: C.ink3),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: C.err, side: BorderSide(color: C.err50, width: 1.5)),
                onPressed: () async {
                  if (await confirm('Keluar dari Sinau?', 'Kamu perlu masuk lagi untuk melanjutkan belajar. Progres tetap tersimpan.', ok: 'Keluar', danger: true)) {
                    await auth.signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
              const SizedBox(height: 12),
              Center(child: Text('Sinau v${AppConfig.version}', style: TextStyle(color: C.ink3, fontSize: 12))),
            ]),
          ),
        ]);
      }),
    );
    return showBack ? Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: body))) : body;
  }

  void _photoSheet(bool hasPhoto) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(5)))),
          const SizedBox(height: 14),
          Text('Foto profil', style: Get.textTheme.titleLarge),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil foto'), onTap: () => _pick(ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => _pick(ImageSource.gallery)),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: C.err),
              title: Text('Hapus foto', style: TextStyle(color: C.err)),
              onTap: _remove,
            ),
        ]),
      ),
    );
  }

  Future<void> _pick(ImageSource src) async {
    Get.back();
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 640, maxHeight: 640, imageQuality: 85, preferredCameraDevice: CameraDevice.front);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) return toast('Foto terlalu besar (maks 2 MB).', error: true);
      final type = f.mimeType ?? (f.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      final url = await Api.i.uploadAvatar(bytes, type);
      await Get.find<AuthController>().updateProfile({'avatar_url': url});
      toast('Foto profil diperbarui');
    } catch (e) {
      toast('Gagal mengganti foto: $e', error: true);
    }
  }

  Future<void> _remove() async {
    Get.back();
    try {
      await Api.i.deleteAvatar();
      await Get.find<AuthController>().updateProfile({'avatar_url': null});
      toast('Kembali ke inisial nama');
    } catch (e) {
      toast('Gagal menghapus foto: $e', error: true);
    }
  }

  void _editName(String current) {
    final c = TextEditingController(text: current);
    final key = GlobalKey<FormState>();
    Get.dialog(AlertDialog(
      backgroundColor: C.bg,
      title: const Text('Ubah nama'),
      content: Form(
        key: key,
        child: TextFormField(
          controller: c,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nama'),
          validator: (v) => (v ?? '').trim().length < 3 ? 'Nama minimal 3 karakter' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () async {
            if (!key.currentState!.validate()) return;
            try {
              await Get.find<AuthController>().updateProfile({'name': c.text.trim()});
              Get.back();
              toast('Nama diperbarui');
            } catch (e) {
              toast('$e', error: true);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _IconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: C.ink3, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      );
}

/// Pilihan tampilan: Terang / Gelap / Sistem.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();
  static const _icons = {ThemeMode.light: Icons.light_mode_outlined, ThemeMode.dark: Icons.dark_mode_outlined, ThemeMode.system: Icons.settings_suggest_outlined};

  @override
  Widget build(BuildContext context) {
    final t = Get.find<ThemeController>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _IconBox(Icons.palette_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tampilan', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('Terang, gelap, atau ikut sistem perangkat', style: TextStyle(color: C.ink3, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Obx(() => Row(children: [
              for (final m in ThemeController.labels.keys) ...[
                if (m != ThemeMode.light) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: t.mode.value == m ? C.primary : C.bg2,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => t.setMode(m),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(children: [
                          Icon(_icons[m], size: 20, color: t.mode.value == m ? Colors.white : C.ink2),
                          const SizedBox(height: 2),
                          Text(ThemeController.labels[m]!,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: t.mode.value == m ? Colors.white : C.ink2)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ])),
      ]),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox(this.icon);
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: C.primary50, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: C.primary, size: 19),
      );
}

const _kebun = [
  (0, 'Bibit', 'Baru ditanam. Mulai belajar untuk menumbuhkannya.', Icons.grass_rounded),
  (1, 'Tunas', 'Tunas pertama muncul.', Icons.spa_outlined),
  (3, 'Tanaman kecil', 'Daunnya mulai bertambah.', Icons.local_florist_outlined),
  (7, 'Tanaman rimbun', 'Seminggu belajar, daunnya lebat.', Icons.eco_rounded),
  (14, 'Pohon muda', 'Batangnya mulai kokoh.', Icons.park_outlined),
  (30, 'Pohon berbuah', 'Sebulan konsisten, pohonmu berbuah!', Icons.park_rounded),
];

/// Kartu streak (7 hari terakhir) + Kebun Sinau. Data dari LearnController (sama dengan halaman Belajar).
class _StreakKebun extends StatelessWidget {
  const _StreakKebun();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LearnController>();
    return Obx(() {
      final d = c.data.value;
      if (d == null) {
        return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
      }
      final s = d.streak;
      return Column(children: [
        _StreakCard(s: s, onTap: () => Get.to(() => const StreakScreen(), binding: BindingsBuilder(() {
          Get.put(StreakController());
        }))),
        const SizedBox(height: 12),
        _KebunCard(streak: s.current),
        const SizedBox(height: 16),
      ]);
    });
  }
}

class _StreakCard extends StatelessWidget {
  final StreakInfo s;
  final VoidCallback onTap;
  const _StreakCard({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final today = todayKey();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final lv = s.level;
    final status = s.todayDone
        ? 'Streak hari ini sudah menyala!'
        : s.current == 0
            ? 'Capai target harian $dailyGoal XP untuk memulai streak.'
            : s.lastChance
                ? 'Hari terakhir! Capai target hari ini atau streak kembali ke 0.'
                : 'Capai target harian untuk menyalakan hari ini.';
    return Material(
      color: C.night,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              StreakFlame(s.todayDone ? lv : null, size: 52, offColor: const Color(0xFF2B2F48)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.current} hari', style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(status, style: const TextStyle(color: Color(0xFFB9BCD3), fontSize: 13)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB9BCD3)),
            ]),
            if (lv != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: lv.color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20), border: Border.all(color: lv.color.withValues(alpha: .6))),
                child: Text('Level ${lv.level} · ${lv.name}', style: TextStyle(color: lv.level == 1 ? const Color(0xFFFF8A80) : lv.color, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 0; i < 7; i++)
                Column(children: [
                  StreakFlame(s.levelOn(days[i]), size: 30, offColor: const Color(0xFF2B2F48)),
                  const SizedBox(height: 4),
                  Text(i == 6 ? 'Hari ini' : hari[days[i].weekday - 1],
                      style: TextStyle(fontSize: 11, fontWeight: i == 6 ? FontWeight.w800 : FontWeight.w600, color: i == 6 ? Colors.white : const Color(0xFF8E91AB))),
                ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: C.reward),
              SizedBox(width: 6),
              Expanded(child: Text('Ketuk untuk melihat kalender streak & level warna.', style: TextStyle(fontSize: 12.5, color: Color(0xFFB9BCD3)))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _KebunCard extends StatelessWidget {
  final int streak;
  const _KebunCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    var stage = 0;
    for (var i = 0; i < _kebun.length; i++) {
      if (streak >= _kebun[i].$1) stage = i;
    }
    final k = _kebun[stage];
    final nextK = stage + 1 < _kebun.length ? _kebun[stage + 1] : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.ok50, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.okLine)),
      child: Row(children: [
        Container(
          width: 72, height: 80,
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16)),
          child: Icon(k.$4, size: 46, color: C.ok),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KEBUN SINAU', style: TextStyle(color: C.ok, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: .6)),
            Text(k.$2, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(k.$3, style: TextStyle(color: C.ink2, fontSize: 13)),
            if (nextK != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ((streak - k.$1) / (nextK.$1 - k.$1)).clamp(0.0, 1.0),
                  minHeight: 6, color: C.ok, backgroundColor: C.surface,
                ),
              ),
              const SizedBox(height: 4),
              Text('${nextK.$1 - streak} hari lagi menjadi ${nextK.$2}', style: TextStyle(fontSize: 12, color: C.ink2, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ]),
    );
  }
}

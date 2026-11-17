import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

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
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: C.primary50),
                    child: Avatar(p.name, url: p.avatarUrl, size: 92),
                  ),
                  if (!p.isAdmin)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Material(
                        color: C.primary,
                        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
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
              Center(child: Text(p.email, style: const TextStyle(color: C.ink3))),
              const SizedBox(height: 8),
              Center(
                child: Wrap(spacing: 6, children: [
                  Pill(p.isAdmin ? 'Admin' : 'User', icon: p.isAdmin ? Icons.shield_outlined : Icons.school_outlined),
                  if (p.angkatan != null) Pill('Angkatan ${p.angkatan}', bg: C.bg2, fg: C.ink2),
                ]),
              ),
              const SizedBox(height: 18),
              if (!p.isAdmin) _StreakKebun(streak: p.streak),
              const SizedBox(height: 6),
              const Text('Informasi akun', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                child: Column(children: [
                  _InfoRow(Icons.person_outline, 'Nama', p.name),
                  const Divider(height: 1, color: C.line),
                  _InfoRow(Icons.mail_outline, 'Email', p.email),
                  const Divider(height: 1, color: C.line),
                  _InfoRow(Icons.school_outlined, 'Angkatan', p.angkatan?.toString() ?? '-'),
                ]),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: C.err, side: const BorderSide(color: C.err50, width: 1.5)),
                onPressed: () async {
                  if (await confirm('Keluar dari Sinau?', 'Kamu perlu masuk lagi untuk melanjutkan belajar. Progres tetap tersimpan.', ok: 'Keluar', danger: true)) {
                    await auth.signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
              const SizedBox(height: 12),
              const Center(child: Text('Sinau v1.0', style: TextStyle(color: C.ink3, fontSize: 12))),
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
        decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(5)))),
          const SizedBox(height: 14),
          Text('Foto profil', style: Get.textTheme.titleLarge),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil foto'), onTap: () => _pick(ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => _pick(ImageSource.gallery)),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: C.err),
              title: const Text('Hapus foto', style: TextStyle(color: C.err)),
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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: C.primary50, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: C.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: C.ink3, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
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

/// Kartu streak (7 hari terakhir) + Kebun Sinau, seperti prototipe.
class _StreakKebun extends StatefulWidget {
  final int streak;
  const _StreakKebun({required this.streak});
  @override
  State<_StreakKebun> createState() => _StreakKebunState();
}

class _StreakKebunState extends State<_StreakKebun> {
  late final Future<List<Map<String, dynamic>>> _f = Repo.myCompletions();

  @override
  Widget build(BuildContext context) {
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    var stage = 0;
    for (var i = 0; i < _kebun.length; i++) {
      if (widget.streak >= _kebun[i].$1) stage = i;
    }
    final k = _kebun[stage];
    final nextK = stage + 1 < _kebun.length ? _kebun[stage + 1] : null;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _f,
      builder: (_, s) {
        final active = {for (final r in s.data ?? const []) (r['completed_at'] ?? '').toString().substring(0, 10)};
        return Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF6D58E))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: C.reward, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.bolt_rounded, color: C.ink, size: 30),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.streak} hari', style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700)),
                  Text(widget.streak > 0 ? 'Streak hari ini sudah menyala!' : 'Belajar hari ini untuk menyalakan streak', style: const TextStyle(color: C.ink2, fontSize: 13)),
                ]),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 7; i++)
                  Column(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: active.contains(days[i].toIso8601String().substring(0, 10)) ? C.reward : C.bg2, shape: BoxShape.circle),
                      child: Icon(Icons.bolt_rounded, size: 17, color: active.contains(days[i].toIso8601String().substring(0, 10)) ? C.ink : C.ink3),
                    ),
                    const SizedBox(height: 4),
                    Text(i == 6 ? 'Hari ini' : hari[days[i].weekday - 1],
                        style: TextStyle(fontSize: 11, fontWeight: i == 6 ? FontWeight.w800 : FontWeight.w600, color: i == 6 ? C.ink : C.ink3)),
                  ]),
              ]),
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.star_rounded, size: 16, color: C.reward),
                SizedBox(width: 6),
                Expanded(child: Text('Hadiah streak: setiap hari belajar menjaga streak tetap menyala.', style: TextStyle(fontSize: 12.5, color: C.ink2))),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.ok50, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFBFE6D3))),
            child: Row(children: [
              Container(
                width: 72, height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Icon(k.$4, size: 46, color: C.ok),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('KEBUN SINAU', style: TextStyle(color: C.ok, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: .6)),
                  Text(k.$2, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(k.$3, style: const TextStyle(color: C.ink2, fontSize: 13)),
                  if (nextK != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((widget.streak - k.$1) / (nextK.$1 - k.$1)).clamp(0.0, 1.0),
                        minHeight: 6, color: C.ok, backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${nextK.$1 - widget.streak} hari lagi menjadi ${nextK.$2}', style: const TextStyle(fontSize: 12, color: C.ink2, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ]);
      },
    );
  }
}

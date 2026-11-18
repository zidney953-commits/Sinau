import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

Map<String, (String, IconData, Color, Color)> get postCats => {
  'tentang': ('Tentang aplikasi', Icons.info_outline, C.primary, C.primary50),
  'update': ('Pembaruan aplikasi', Icons.refresh, C.ok, C.ok50),
  'umum': ('Pengumuman', Icons.campaign_outlined, C.rewardInk, C.reward50),
};

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
String fmtDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Tab Informasi: dibaca pengguna, dikelola admin (tambah & hapus).
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});
  InfoController get c => Get.find<InfoController>();

  @override
  Widget build(BuildContext context) {
    final p = Get.find<AuthController>().profile.value!;
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader('Informasi',
            subtitle: p.isAdmin ? 'Kelola kabar untuk pengguna' : 'Kabar dan penjelasan dari Sinau',
            trailing: p.isAdmin
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                    onPressed: () => Get.bottomSheet<bool>(const _PostForm(), isScrollControlled: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'))
                : Avatar(p.name, url: p.avatarUrl, size: 38)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.load,
            child: ObxLoad<List<Post>>(
              controller: c,
              builder: (posts) => ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: LogoMark(size: 32)),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sinau', style: GoogleFonts.rubik(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Text('Belajar pemrograman dari dasar', style: TextStyle(color: Colors.white70)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
                if (posts.isEmpty)
                  const StateView(icon: Icons.notifications_none, title: 'Belum ada informasi', body: 'Kabar dari admin akan muncul di sini.'),
                for (final post in posts) ...[_PostCard(post: post, admin: p.isAdmin), const SizedBox(height: 12)],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool admin;
  const _PostCard({required this.post, required this.admin});
  @override
  Widget build(BuildContext context) {
    final c = postCats[post.category]!;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill(c.$1, icon: c.$2, fg: c.$3, bg: c.$4),
          if (post.pinned) ...[const SizedBox(width: 6), Pill('Disematkan', icon: Icons.star_border_rounded, fg: C.rewardInk, bg: C.reward50)],
          const Spacer(),
          if (admin)
            IconButton(
              tooltip: 'Hapus',
              icon: Icon(Icons.delete_outline, color: C.err),
              onPressed: () async {
                if (!await confirm('Hapus informasi?', '“${post.title}” akan hilang dari tab Informasi pengguna.', ok: 'Hapus', danger: true)) return;
                try {
                  await Get.find<InfoController>().remove(post.id); // daftar ikut diperbarui lewat Obx
                  toast('Informasi dihapus');
                } catch (e) {
                  toast('$e', error: true);
                }
              },
            ),
        ]),
        const SizedBox(height: 10),
        Text(post.title, style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(post.body, style: TextStyle(color: C.ink2, height: 1.55)),
        const SizedBox(height: 10),
        Text(fmtDate(post.createdAt), style: TextStyle(color: C.ink3, fontSize: 12)),
      ]),
    );
  }
}

class _PostForm extends StatefulWidget {
  const _PostForm();
  @override
  State<_PostForm> createState() => _PostFormState();
}

class _PostFormState extends State<_PostForm> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController(), _body = TextEditingController();
  String _cat = 'umum';
  bool _pin = false, _busy = false;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 14),
            Text('Tambah informasi', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final e in postCats.entries)
                ChoiceChip(selected: _cat == e.key, onSelected: (_) => setState(() => _cat = e.key), label: Text(e.value.$1), selectedColor: e.value.$4, showCheckmark: false),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Judul'), validator: (v) => (v ?? '').trim().length < 3 ? 'Minimal 3 karakter' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _body, maxLines: 4, decoration: const InputDecoration(labelText: 'Isi'), validator: (v) => (v ?? '').trim().length < 10 ? 'Minimal 10 karakter' : null),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: _pin, onChanged: (v) => setState(() => _pin = v), title: const Text('Sematkan di paling atas')),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (!_key.currentState!.validate()) return;
                      setState(() => _busy = true);
                      try {
                        await Get.find<InfoController>().add(_cat, _title.text.trim(), _body.text.trim(), _pin);
                        Get.back(result: true);
                        toast('Informasi dikirim ke pengguna');
                      } catch (e) {
                        setState(() => _busy = false);
                        toast('$e', error: true);
                      }
                    },
              child: const Text('Kirim'),
            ),
          ]),
        ),
      );
}

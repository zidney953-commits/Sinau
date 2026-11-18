import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/app_controllers.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';
import '../common/feedback_sheet.dart';
import '../common/info_screen.dart';
import '../common/profile_screen.dart';
import 'lesson_editor.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulanPanjang = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
Color get cOk => C.ok;
const cHard = Color(0xFFE39A0A);

/// Tombol profil admin (ikon perisai) di kanan atas setiap halaman admin.
Widget adminProfileButton() => IconButton(
      tooltip: 'Profil',
      onPressed: () => Get.to(() => const ProfileScreen(showBack: true)),
      icon: CircleAvatar(radius: 18, backgroundColor: C.night, child: Icon(Icons.shield_outlined, color: Colors.white, size: 18)),
    );

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    final fb = Get.find<FeedbackController>();
    // Obx: tab aktif & angka badge Masukan reaktif (nav.tab, fb.data).
    return Obx(() => AppShell(
          index: nav.tab.value,
          onSelect: (i) {
            nav.go(i);
            if (i == 3) fb.load();
          },
          items: [
            const NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dasbor'),
            const NavItem(Icons.layers_outlined, Icons.layers, 'Materi'),
            const NavItem(Icons.group_outlined, Icons.group, 'Anggota'),
            NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Masukan', badge: fb.newCount),
            const NavItem(Icons.notifications_none_rounded, Icons.notifications_rounded, 'Informasi'),
          ],
          pages: const [DashboardTab(), ContentTab(), MembersTab(), FeedbackTab(), InfoScreen()],
        ));
  }
}

// ============================ Dasbor ============================
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  DashboardController get c => Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader('Dasbor Admin', subtitle: '${_hari[now.weekday - 1]}, ${now.day} ${_bulan[now.month - 1]} ${now.year}', trailing: adminProfileButton()),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.load,
            child: ObxLoad<DashData>(
              controller: c,
              builder: (d) => ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                ResponsiveColumns(children: [_signups(d), _skills(d)]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ----- Pendaftar baru per bulan -----
  Widget _signups(DashData d) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final counts = [
      for (final m in months) d.members.where((p) => p.createdAt != null && p.createdAt!.year == m.year && p.createdAt!.month == m.month).length,
    ];
    final cur = counts.last, prev = counts[4];
    final up = cur >= prev;
    final pct = prev == 0 ? null : ((cur - prev).abs() * 100 / prev).round();
    final maxV = counts.fold<int>(1, (a, b) => b > a ? b : a);
    return SectionCard(
      title: 'Pendaftar baru per bulan',
      subtitle: 'Jumlah akun baru yang mendaftar setiap bulan · 6 bulan terakhir',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_bulanPanjang[now.month - 1]} ${now.year} (s.d. ${now.day} ${_bulan[now.month - 1]})', style: TextStyle(color: C.ink3, fontSize: 12)),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
          Text('$cur pendaftar baru', style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700)),
          Pill(
            pct == null ? 'Bulan pertama' : '${up ? 'Naik' : 'Turun'} $pct% dari ${_bulan[months[4].month - 1]} ($prev)',
            icon: up ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            bg: up ? C.ok50 : C.err50, fg: up ? C.ok : C.err,
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 6; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${counts[i]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    height: 120 * counts[i] / maxV + 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: i == 5 ? C.primary : const Color(0xFFA9A3EC), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                  ),
                  const SizedBox(height: 6),
                  Text(_bulan[months[i].month - 1], style: TextStyle(fontSize: 12, color: i == 5 ? C.ink : C.ink3, fontWeight: i == 5 ? FontWeight.w800 : FontWeight.w600)),
                ]),
              ),
          ]),
        ),
        _tableToggle(c.showSignupTable.value, c.showSignupTable.toggle),
        if (c.showSignupTable.value)
          _table(['Bulan', 'Pendaftar'], [for (var i = 0; i < 6; i++) ['${_bulanPanjang[months[i].month - 1]} ${months[i].year}', '${counts[i]}']]),
      ]),
    );
  }

  // ----- Kemampuan belajar per tugas -----
  Widget _skills(DashData d) {
    final units = d.units[c.lang.value] ?? [];
    final rows = <(int, Unit, int, int, int)>[];
    for (var i = 0; i < units.length; i++) {
      final ps = d.prog.where((p) => p['lessons']?['unit_id'] == units[i].id).toList();
      final users = ps.map((p) => p['user_id']).toSet().length;
      final hard = ps.where((p) => p['failed_before'] == true).length;
      final ok = ps.where((p) => p['passed'] == true && p['failed_before'] != true).length;
      rows.add((i, units[i], ok, hard, users));
    }
    (int, Unit, int, int, int)? hardest;
    double hardestPct = 0;
    for (final r in rows) {
      final n = r.$3 + r.$4;
      if (n > 0 && r.$4 / n > hardestPct) {
        hardestPct = r.$4 / n;
        hardest = r;
      }
    }
    return SectionCard(
      title: 'Kemampuan belajar per unit',
      subtitle: 'Apakah pengguna banyak yang bisa atau banyak yang kesusahan',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.bg2, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            for (final l in d.langs)
              Expanded(
                child: GestureDetector(
                  onTap: () => c.lang.value = l.id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: c.lang.value == l.id ? C.surface : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.code_rounded, size: 17, color: Color(l.color)),
                      const SizedBox(width: 6),
                      Text(l.name, style: TextStyle(fontWeight: FontWeight.w800, color: c.lang.value == l.id ? C.primary : C.ink2)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _Legend(cOk, 'Bisa · lulus di percobaan pertama'),
          _Legend(cHard, 'Kesusahan · perlu mengulang'),
        ]),
        const SizedBox(height: 12),
        for (final r in rows) _skillBar(r),
        if (hardest != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.reward50, borderRadius: BorderRadius.circular(14)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, color: C.rewardInk, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(TextSpan(style: TextStyle(color: C.rewardInk2), children: [
                  const TextSpan(text: 'Paling banyak kesusahan: '),
                  TextSpan(text: 'Tugas ${hardest.$1 + 1} · ${hardest.$2.title}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' (${(hardestPct * 100).round()}% perlu mengulang). Pertimbangkan memperjelas materinya.'),
                ])),
              ),
            ]),
          ),
        _tableToggle(c.showSkillTable.value, c.showSkillTable.toggle),
        if (c.showSkillTable.value)
          _table(['Tugas', 'Bisa', 'Kesusahan', 'Pengguna'], [
            for (final r in rows) ['Tugas ${r.$1 + 1} · ${r.$2.title}', '${r.$3}', '${r.$4}', '${r.$5}'],
          ]),
      ]),
    );
  }

  Widget _skillBar((int, Unit, int, int, int) r) {
    final n = r.$3 + r.$4;
    final po = n == 0 ? 0 : (r.$3 * 100 / n).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tugas ${r.$1 + 1} · ${r.$2.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 14,
            child: n == 0
                ? Container(color: C.bg2)
                : Row(children: [
                    if (r.$3 > 0) Expanded(flex: r.$3, child: Container(color: cOk)),
                    if (r.$4 > 0) Expanded(flex: r.$4, child: Container(color: cHard)),
                  ]),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          if (n == 0)
            Text('Belum ada yang mencoba', style: TextStyle(color: C.ink3, fontSize: 12))
          else ...[
            _Legend(cOk, '$po% bisa', small: true),
            const SizedBox(width: 10),
            _Legend(cHard, '${100 - po}% kesusahan', small: true),
          ],
          const Spacer(),
          Text('${r.$5} pengguna', style: TextStyle(color: C.ink3, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _tableToggle(bool open, VoidCallback onTap) => TextButton.icon(
        style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: C.primary),
        onPressed: onTap,
        icon: Icon(open ? Icons.arrow_drop_down : Icons.arrow_right),
        label: Text(open ? 'Sembunyikan tabel' : 'Tampilkan tabel', style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _table(List<String> head, List<List<String>> rows) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.all(color: C.line),
          columnWidths: const {0: FlexColumnWidth(2.4)},
          children: [
            TableRow(decoration: BoxDecoration(color: C.bg2), children: [
              for (final h in head) Padding(padding: const EdgeInsets.all(8), child: Text(h, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
            ]),
            for (final r in rows)
              TableRow(children: [for (final c in r) Padding(padding: const EdgeInsets.all(8), child: Text(c, style: const TextStyle(fontSize: 12.5)))]),
          ],
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  final bool small;
  const _Legend(this.color, this.text, {this.small = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: small ? 8 : 12, height: small ? 8 : 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: small ? 12 : 12.5, color: C.ink2)),
      ]);
}

// ============================ Materi ============================
class ContentTab extends StatelessWidget {
  const ContentTab({super.key});
  ContentController get ctl => Get.find<ContentController>();

  Future<String?> _askTitle(String title, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    final key = GlobalKey<FormState>();
    return Get.dialog<String>(AlertDialog(
      backgroundColor: C.bg,
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: c, autofocus: true, maxLength: 60,
          decoration: const InputDecoration(labelText: 'Judul tugas', hintText: 'contoh: Fungsi'),
          validator: (v) => (v ?? '').trim().length < 3 ? 'Minimal 3 karakter' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () => key.currentState!.validate() ? Get.back(result: c.text.trim()) : null,
          child: const Text('Simpan'),
        ),
      ],
    ));
  }

  Future<void> _addUnit(List<Unit> units) async {
    final t = await _askTitle('Tambah tugas');
    if (t == null) return;
    try {
      await ctl.addUnit(t);
      toast('Tugas ${units.length + 1} ditambahkan');
    } catch (e) {
      toast(e.toString().contains('duplicate') ? 'Judul tugas sudah dipakai' : '$e', error: true);
    }
  }

  Future<void> _unitMenu(String action, Unit u, int no) async {
    try {
      if (action == 'rename') {
        final t = await _askTitle('Ubah judul tugas', initial: u.title);
        if (t == null || t == u.title) return;
        await ctl.renameUnit(u.id, t);
        toast('Judul tugas diubah');
      } else {
        if (!await confirm('Hapus Tugas $no?',
            '“${u.title}” beserta ${u.lessons.length} pembahasan, soal, dan progres user di dalamnya akan terhapus. Tindakan ini tidak bisa dibatalkan.',
            ok: 'Hapus', danger: true)) {
          return;
        }
        await ctl.deleteUnit(u.id);
        toast('Tugas dihapus');
      }
    } catch (e) {
      toast('$e', error: true);
    }
  }

  Future<void> _openEditor(Unit u, int no, [Lesson? l]) async {
    if (await Get.to<bool>(() => LessonEditorScreen(unit: u, unitNo: no, lesson: l)) == true) ctl.load();
  }

  Future<void> _deleteLesson(Lesson l) async {
    if (!await confirm('Hapus pembahasan?', '“${l.title}” beserta soal dan progres user di dalamnya akan terhapus.', ok: 'Hapus', danger: true)) return;
    try {
      await ctl.deleteLesson(l.id);
      toast('Pembahasan dihapus');
    } catch (e) {
      toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader('Kelola materi', subtitle: 'Pembahasan draf tidak terlihat oleh user', trailing: adminProfileButton()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'python', label: Text('Python')), ButtonSegment(value: 'java', label: Text('Java'))],
              selected: {ctl.lang.value},
              onSelectionChanged: (s) => ctl.setLang(s.first),
            ),
          ),
          Expanded(
            child: ObxLoad<List<Unit>>(
              controller: ctl,
              builder: (units) => ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                Row(children: [
                  Expanded(child: Text('${units.length} tugas · ${units.fold<int>(0, (a, u) => a + u.lessons.length)} pembahasan', style: const TextStyle(fontWeight: FontWeight.w800))),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => _addUnit(units),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tugas'),
                  ),
                ]),
                const SizedBox(height: 12),
                if (units.isEmpty)
                  const StateView(icon: Icons.layers_outlined, title: 'Belum ada tugas', body: 'Tambahkan tugas pertama, lalu isi pembahasannya.'),
                ResponsiveColumns(children: [for (var i = 0; i < units.length; i++) _unitCard(units[i], i + 1)]),
              ]),
            ),
          ),
        ]),
      ));

  Widget _unitCard(Unit u, int no) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            color: C.bg2,
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('$no', style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tugas $no · ${u.title}', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                  Text('${u.lessons.length} pembahasan · ${u.lessons.where((l) => l.published).length} terbit', style: TextStyle(color: C.ink3, fontSize: 12)),
                ]),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi tugas',
                onSelected: (a) => _unitMenu(a, u, no),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Ubah judul'), contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: C.err), title: Text('Hapus tugas', style: TextStyle(color: C.err)), contentPadding: EdgeInsets.zero)),
                ],
              ),
            ]),
          ),
          for (final l in u.lessons)
            ListTile(
              onTap: () => _openEditor(u, no, l),
              title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${l.published ? 'Terbit' : 'Draf'} · ${l.durationMin} menit · ${l.xp} XP',
                  style: TextStyle(color: l.published ? C.ok : C.ink3, fontWeight: FontWeight.w700, fontSize: 12.5)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(
                  value: l.published,
                  activeThumbColor: C.ok,
                  onChanged: (v) async {
                    try {
                      await ctl.setPublished(l, v); // langsung berubah di layar (data.refresh)
                      toast(v ? '“${l.title}” diterbitkan' : '“${l.title}” dijadikan draf');
                    } catch (e) {
                      toast('$e', error: true);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opsi pembahasan',
                  onSelected: (a) => a == 'edit' ? _openEditor(u, no, l) : _deleteLesson(l),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: C.err))),
                  ],
                ),
              ]),
            ),
          if (u.lessons.isEmpty) Padding(padding: EdgeInsets.all(14), child: Text('Belum ada pembahasan di tugas ini.', style: TextStyle(color: C.ink3))),
          Divider(height: 1, color: C.line),
          TextButton.icon(
            style: TextButton.styleFrom(padding: const EdgeInsets.all(14)),
            onPressed: () => _openEditor(u, no),
            icon: const Icon(Icons.add),
            label: const Text('Tambah pembahasan', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

// ============================ Anggota ============================
class MembersTab extends StatelessWidget {
  const MembersTab({super.key});
  MembersController get c => Get.find<MembersController>();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader('Anggota', subtitle: 'User yang terdaftar di Sinau', trailing: adminProfileButton()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Cari nama', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => c.query.value = v,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ObxLoad<List<Profile>>(
                controller: c,
                builder: (all) {
                  final years = c.years;
                  final xs = c.filtered; // pencarian & filter dari c.query / c.year (reactive)
                  return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                    Wrap(spacing: 8, children: [
                      ChoiceChip(label: const Text('Semua'), selected: c.year.value == null, onSelected: (_) => c.year.value = null, showCheckmark: false),
                      for (final y in years) ChoiceChip(label: Text('$y'), selected: c.year.value == y, onSelected: (_) => c.year.value = y, showCheckmark: false),
                    ]),
                    const SizedBox(height: 10),
                    if (xs.isEmpty)
                      const StateView(icon: Icons.group_outlined, title: 'Tidak ada anggota', body: 'Tidak ada user yang cocok dengan pencarian atau filter ini.')
                    else
                      Container(
                        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
                        child: Column(children: [
                          for (var i = 0; i < xs.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: C.line),
                            ListTile(
                              leading: Avatar(xs[i].name, url: xs[i].avatarUrl),
                              title: Text(xs[i].name, style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                              subtitle: Text('${xs[i].angkatan != null ? 'Angkatan ${xs[i].angkatan} · ' : ''}${xs[i].email}', style: const TextStyle(fontSize: 12)),
                              trailing: Pill(xs[i].active ? 'Aktif' : 'Nonaktif', bg: xs[i].active ? C.ok50 : C.err50, fg: xs[i].active ? C.ok : C.err),
                              onTap: () => _toggle(xs[i]),
                            ),
                          ],
                        ]),
                      ),
                  ]);
                },
              ),
            ),
          ),
        ]),
      );

  Future<void> _toggle(Profile m) async {
    final ok = await confirm(
      m.active ? 'Nonaktifkan ${m.name}?' : 'Aktifkan ${m.name}?',
      m.active ? 'Akun ini tidak bisa masuk sampai diaktifkan lagi.' : 'Akun ini bisa masuk dan belajar lagi.',
      ok: m.active ? 'Nonaktifkan' : 'Aktifkan',
      danger: m.active,
    );
    if (!ok) return;
    try {
      await c.toggleActive(m);
      toast(m.active ? '${m.name} dinonaktifkan' : '${m.name} diaktifkan');
    } catch (e) {
      toast('$e', error: true);
    }
  }
}

// ============================ Masukan ============================
class FeedbackTab extends StatelessWidget {
  const FeedbackTab({super.key});
  FeedbackController get c => Get.find<FeedbackController>();
  static Map<String, (String, Color, Color)> get _status => {'baru': ('Baru', C.rewardInk, C.reward50), 'proses': ('Diproses', C.primary, C.primary50), 'selesai': ('Selesai', C.ok, C.ok50)};

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader('Masukan pengguna', subtitle: 'Saran, error, dan laporan soal dari user', trailing: adminProfileButton()),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ObxLoad<List<FeedbackItem>>(
                controller: c,
                builder: (all) {
                  final xs = c.filtered; // mengikuti c.filter (reactive)
                  return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                    Wrap(spacing: 8, children: [
                      ChoiceChip(label: Text('Semua (${all.length})'), selected: c.filter.value == 'all', onSelected: (_) => c.filter.value = 'all', showCheckmark: false),
                      for (final s in _status.entries)
                        ChoiceChip(
                          label: Text('${s.value.$1} (${all.where((f) => f.status == s.key).length})'),
                          selected: c.filter.value == s.key, onSelected: (_) => c.filter.value = s.key, showCheckmark: false,
                        ),
                    ]),
                    const SizedBox(height: 10),
                    if (xs.isEmpty)
                      const StateView(icon: Icons.chat_bubble_outline_rounded, title: 'Belum ada masukan', body: 'Masukan dari tombol pesan (ikon chat) di aplikasi user akan muncul di sini.'),
                    ResponsiveColumns(children: [for (final f in xs) _card(f)]),
                  ]);
                },
              ),
            ),
          ),
        ]),
      );

  Widget _card(FeedbackItem f) {
    final t = feedbackTypes[f.type]!;
    final st = _status[f.status]!;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill(t.$1, icon: t.$2, fg: t.$3, bg: t.$4),
          const Spacer(),
          Pill(st.$1, fg: st.$2, bg: st.$3),
        ]),
        const SizedBox(height: 10),
        Text(f.text, style: const TextStyle(height: 1.5)),
        if (f.context.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in f.context.entries) Pill('${e.key}: ${e.value}', bg: C.bg2, fg: C.ink2),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Avatar(f.userName ?? '?', size: 26),
          const SizedBox(width: 8),
          Expanded(child: Text('${f.userName ?? 'Pengguna'} · ${f.createdAt.day} ${_bulan[f.createdAt.month - 1]} ${f.createdAt.year}', style: TextStyle(color: C.ink3, fontSize: 12))),
          PopupMenuButton<String>(
            tooltip: 'Ubah status',
            onSelected: (s) async {
              try {
                await c.setStatus(f.id, s); // daftar & badge menu ikut diperbarui
                toast('Status diubah ke ${_status[s]!.$1}');
              } catch (e) {
                toast('$e', error: true);
              }
            },
            itemBuilder: (_) => [for (final s in _status.entries) PopupMenuItem(value: s.key, child: Text(s.value.$1))],
            child: Padding(padding: EdgeInsets.all(4), child: Text('Ubah status', style: TextStyle(color: C.primary, fontWeight: FontWeight.w800))),
          ),
        ]),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../../widgets/responsive.dart';

/// Soal yang sedang diedit.
class _Q {
  String type; // mc | order
  final prompt = TextEditingController();
  final code = TextEditingController();
  final why = TextEditingController();
  final List<TextEditingController> items; // pilihan (mc) atau blok urutan benar (order)
  int answer; // indeks jawaban benar (mc)
  _Q({this.type = 'mc', List<String>? items, this.answer = 0}) : items = [for (final s in items ?? ['', '']) TextEditingController(text: s)];

  factory _Q.from(Question q) {
    final e = _Q(type: q.type == 'order' ? 'order' : 'mc', items: q.type == 'order' ? q.blocks : q.opts, answer: q.answer is int ? q.answer : 0);
    e.prompt.text = q.prompt;
    e.code.text = q.code ?? '';
    e.why.text = q.explanation ?? '';
    return e;
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? keepTable) {
    final xs = items.map((c) => c.text.trim()).toList();
    if (type == 'order') {
      final pool = List.generate(xs.length, (i) => i)..shuffle();
      if (xs.length > 1 && List.generate(pool.length, (i) => pool[i] == i).every((e) => e)) pool.add(pool.removeAt(0));
      return {'type': 'order', 'prompt': prompt.text.trim(), 'options': {'blocks': xs, 'pool': pool}, 'answer': List.generate(xs.length, (i) => i), 'explanation': why.text.trim().isEmpty ? null : why.text.trim()};
    }
    return {
      'type': 'mc',
      'prompt': prompt.text.trim(),
      'options': {'opts': xs, if (code.text.trim().isNotEmpty) 'code': code.text, 'table': ?keepTable},
      'answer': answer,
      'explanation': why.text.trim().isEmpty ? null : why.text.trim(),
    };
  }
}

/// Tambah / ubah pembahasan: data dasar, isi materi, dan soal tugas.
class LessonEditorScreen extends StatefulWidget {
  final Unit unit;
  final int unitNo;
  final Lesson? lesson;
  const LessonEditorScreen({super.key, required this.unit, required this.unitNo, this.lesson});
  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController(), _dur = TextEditingController(text: '5'), _xp = TextEditingController(text: '15');
  final _intro = TextEditingController(), _code = TextEditingController(), _tip = TextEditingController();
  final List<(TextEditingController, TextEditingController)> _points = [];
  final List<_Q> _qs = [];
  final Map<int, Map<String, dynamic>?> _tables = {};
  bool _pub = false, _loading = true, _saving = false;

  bool get _isNew => widget.lesson == null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final l = widget.lesson;
    if (l != null) {
      _title.text = l.title;
      _dur.text = '${l.durationMin}';
      _xp.text = '${l.xp}';
      _pub = l.published;
      _intro.text = l.material['intro'] ?? '';
      _code.text = l.material['code'] ?? '';
      _tip.text = l.material['tip'] ?? '';
      for (final p in (l.material['points'] ?? []) as List) {
        _points.add((TextEditingController(text: p[0]), TextEditingController(text: p[1])));
      }
      try {
        final qs = await Repo.questions(l.id);
        for (var i = 0; i < qs.length; i++) {
          _qs.add(_Q.from(qs[i]));
          _tables[i] = qs[i].table;
        }
      } catch (e) {
        toast('Soal gagal dimuat: $e', error: true);
      }
    } else {
      _points.add((TextEditingController(), TextEditingController()));
      _qs.addAll([_Q(items: ['', '', '', '']), _Q(items: ['', '', '', '']), _Q(items: ['', '', '', ''])]);
    }
    setState(() => _loading = false);
  }

  String? _checkQuestions() {
    if (_qs.isEmpty) return 'Tambahkan minimal 1 soal.';
    for (var i = 0; i < _qs.length; i++) {
      final q = _qs[i];
      final filled = q.items.where((c) => c.text.trim().isNotEmpty).length;
      if (q.prompt.text.trim().length < 5) return 'Soal ${i + 1}: pertanyaan minimal 5 karakter.';
      if (filled != q.items.length) return 'Soal ${i + 1}: ada ${q.type == 'mc' ? 'pilihan' : 'blok'} yang masih kosong.';
      if (q.items.length < 2) return 'Soal ${i + 1}: minimal 2 ${q.type == 'mc' ? 'pilihan' : 'blok'}.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return toast('Periksa kolom yang masih salah.', error: true);
    final qErr = _checkQuestions();
    if (qErr != null) return toast(qErr, error: true);
    setState(() => _saving = true);
    final types = _qs.map((q) => q.type).toSet();
    final lesson = {
      'unit_id': widget.unit.id,
      'title': _title.text.trim(),
      'type': types.length > 1 ? 'mix' : types.first,
      'duration_min': int.parse(_dur.text),
      'xp': int.parse(_xp.text),
      'published': _pub,
      if (_isNew) 'position': widget.unit.lessons.length,
      'material': {
        'intro': _intro.text.trim(),
        'points': [
          for (final p in _points)
            if (p.$1.text.trim().isNotEmpty) [p.$1.text.trim(), p.$2.text.trim()],
        ],
        if (_code.text.trim().isNotEmpty) 'code': _code.text,
        if (_tip.text.trim().isNotEmpty) 'tip': _tip.text.trim(),
      },
    };
    try {
      await Repo.saveLesson(id: widget.lesson?.id, lesson: lesson, questions: [for (var i = 0; i < _qs.length; i++) _qs[i].toJson(_tables[i])]);
      Get.back(result: true);
      toast(_isNew ? 'Pembahasan ditambahkan' : 'Pembahasan disimpan');
    } catch (e) {
      setState(() => _saving = false);
      toast('Gagal menyimpan: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PageHeader(_isNew ? 'Tambah pembahasan' : 'Ubah pembahasan', subtitle: 'Tugas ${widget.unitNo} · ${widget.unit.title}', onBack: Get.back),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Form(
                          key: _key,
                          child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
                            _basics(),
                            const SizedBox(height: 14),
                            _material(),
                            const SizedBox(height: 14),
                            _questions(),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Icon(Icons.check),
                              label: Text(_isNew ? 'Tambah pembahasan' : 'Simpan perubahan'),
                            ),
                          ]),
                        ),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _basics() => SectionCard(
        title: 'Data pembahasan',
        child: Column(children: [
          TextFormField(
            controller: _title,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Judul pembahasan', counterText: ''),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Minimal 3 karakter' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _dur, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durasi (menit)'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Isi angka ≥ 1' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _xp, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'XP'),
                validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Isi angka ≥ 0' : null,
              ),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _pub,
            activeThumbColor: C.ok,
            onChanged: (v) => setState(() => _pub = v),
            title: const Text('Terbitkan', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(_pub ? 'Langsung terlihat oleh user' : 'Disimpan sebagai draf'),
          ),
        ]),
      );

  Widget _material() => SectionCard(
        title: 'Isi materi',
        subtitle: 'Ditampilkan sebelum user mengerjakan tugas',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _intro, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Penjelasan singkat'),
            validator: (v) => (v ?? '').trim().length < 10 ? 'Minimal 10 karakter' : null,
          ),
          const SizedBox(height: 12),
          const Text('Poin-poin penting', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < _points.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(children: [
                    TextField(controller: _points[i].$1, decoration: InputDecoration(labelText: 'Judul poin ${i + 1}', isDense: true)),
                    const SizedBox(height: 6),
                    TextField(controller: _points[i].$2, maxLines: 2, decoration: const InputDecoration(labelText: 'Isi poin', isDense: true)),
                  ]),
                ),
                IconButton(tooltip: 'Hapus poin', onPressed: () => setState(() => _points.removeAt(i)), icon: Icon(Icons.close, color: C.ink3)),
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _points.add((TextEditingController(), TextEditingController()))),
              icon: const Icon(Icons.add), label: const Text('Tambah poin'),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _code, maxLines: 5,
            style: GoogleFonts.jetBrainsMono(fontSize: 13),
            decoration: const InputDecoration(labelText: 'Contoh kode (opsional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          TextField(controller: _tip, maxLines: 2, decoration: const InputDecoration(labelText: 'Tips (opsional)')),
        ]),
      );

  Widget _questions() => SectionCard(
        title: 'Soal tugas · ${_qs.length}',
        subtitle: 'Lulus jika minimal 2 dari 3 benar (⅔ dari jumlah soal)',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < _qs.length; i++) _questionCard(i),
          OutlinedButton.icon(
            onPressed: () => setState(() => _qs.add(_Q(items: ['', '', '', '']))),
            icon: const Icon(Icons.add), label: const Text('Tambah soal'),
          ),
        ]),
      );

  Widget _questionCard(int i) {
    final q = _qs[i];
    final mc = q.type == 'mc';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Soal ${i + 1}', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 16))),
          IconButton(
            tooltip: 'Hapus soal',
            onPressed: _qs.length <= 1 ? null : () => setState(() => _qs.removeAt(i)),
            icon: Icon(Icons.delete_outline, color: C.err),
          ),
        ]),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'mc', label: Text('Pilihan ganda', maxLines: 1, softWrap: false)),
            ButtonSegment(value: 'order', label: Text('Susun kode', maxLines: 1, softWrap: false)),
          ],
          selected: {q.type},
          onSelectionChanged: (s) => setState(() => q.type = s.first),
        ),
        const SizedBox(height: 10),
        TextField(controller: q.prompt, decoration: const InputDecoration(labelText: 'Pertanyaan', isDense: true)),
        if (mc) ...[
          const SizedBox(height: 8),
          TextField(controller: q.code, maxLines: 3, style: GoogleFonts.jetBrainsMono(fontSize: 13), decoration: const InputDecoration(labelText: 'Kode di soal (opsional)', isDense: true)),
        ],
        const SizedBox(height: 10),
        Text(mc ? 'Pilihan jawaban · pilih yang benar' : 'Blok kode · tulis sesuai URUTAN BENAR (akan diacak untuk user)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: C.ink2)),
        const SizedBox(height: 6),
        for (var j = 0; j < q.items.length; j++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              if (mc)
                IconButton(
                  tooltip: 'Jadikan jawaban benar',
                  onPressed: () => setState(() => q.answer = j),
                  icon: Icon(q.answer == j ? Icons.check_circle : Icons.radio_button_unchecked, color: q.answer == j ? C.ok : C.ink3),
                )
              else
                SizedBox(width: 40, child: Center(child: Text('${j + 1}.', style: const TextStyle(fontWeight: FontWeight.w800)))),
              Expanded(
                child: TextField(
                  controller: q.items[j],
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                  decoration: InputDecoration(isDense: true, hintText: mc ? 'Pilihan ${String.fromCharCode(65 + j)}' : 'Baris ${j + 1}'),
                ),
              ),
              IconButton(
                onPressed: q.items.length <= 2
                    ? null
                    : () => setState(() {
                          q.items.removeAt(j);
                          if (q.answer >= q.items.length) q.answer = 0;
                        }),
                icon: Icon(Icons.close, size: 18, color: C.ink3),
              ),
            ]),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: q.items.length >= 6 ? null : () => setState(() => q.items.add(TextEditingController())),
            icon: const Icon(Icons.add, size: 18), label: Text(mc ? 'Tambah pilihan' : 'Tambah blok'),
          ),
        ),
        TextField(controller: q.why, maxLines: 2, decoration: const InputDecoration(labelText: 'Penjelasan jawaban (opsional)', isDense: true)),
      ]),
    );
  }
}

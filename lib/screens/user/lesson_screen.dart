import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

int passMin(int n) => n <= 2 ? n : (n * 2 / 3).ceil();

/// Satu pembahasan: materi → soal tugas → hasil.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final LessonProgress? prev;
  const LessonScreen({super.key, required this.lesson, this.prev});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<List<Question>> _f = Repo.questions(widget.lesson.id);
  int _step = 0; // 0 = materi, 1..n = soal, n+1 = hasil
  int _correct = 0;
  int? _sel;
  List<int> _order = [];
  bool _checked = false, _right = false, _saving = false;

  void _check(Question q) {
    final ok = q.type == 'order'
        ? _order.length == q.blocks.length && List.generate(_order.length, (i) => _order[i] == i).every((e) => e)
        : _sel == q.answer;
    setState(() {
      _checked = true;
      _right = ok;
      if (ok) _correct++;
    });
  }

  Future<void> _next(int n) async {
    if (_step == n) {
      setState(() => _saving = true);
      final passed = _correct >= passMin(n);
      try {
        await Repo.saveProgress(widget.lesson.id, passed: passed, correct: _correct, total: n, prev: widget.prev);
      } catch (e) {
        toast('Hasil belum tersimpan: $e', error: true);
      }
      setState(() {
        _saving = false;
        _step++;
      });
      return;
    }
    setState(() {
      _step++;
      _sel = null;
      _order = [];
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: AsyncView(
            future: _f,
            onRetry: () => setState(() => _f = Repo.questions(widget.lesson.id)),
            builder: (qs) {
              final n = qs.length;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        if (_step == 0 || _step > n || await confirm('Keluar dari pembahasan?', 'Jawabanmu di pembahasan ini belum disimpan.', ok: 'Keluar', danger: true)) Get.back();
                      },
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: (_step.clamp(0, n + 1)) / (n + 1), minHeight: 8, color: C.ok, backgroundColor: C.bg2),
                      ),
                    ),
                  ]),
                ),
                Expanded(child: _step == 0 ? _material() : _step <= n ? _question(qs[_step - 1], n) : _result(n)),
              ]);
            },
          ))),
        ),
      );

  Widget _material() {
    final m = widget.lesson.material;
    final points = ((m['points'] ?? []) as List).map((e) => (e as List).cast<String>()).toList();
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          const Pill('MATERI', icon: Icons.menu_book_outlined),
          const SizedBox(height: 10),
          Text(widget.lesson.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(m['intro'] ?? '', style: const TextStyle(fontSize: 15.5, height: 1.55, color: C.ink2)),
          const SizedBox(height: 16),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p[0], style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(p[1], style: const TextStyle(color: C.ink2, height: 1.45)),
                  ]),
                ),
              ),
            ),
          if (m['code'] != null) ...[const SizedBox(height: 6), CodeBlock(m['code'])],
          if (m['tip'] != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.reward50, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF8A5A00)),
                const SizedBox(width: 10),
                Expanded(child: Text(m['tip'], style: const TextStyle(color: Color(0xFF5C3D00), height: 1.45))),
              ]),
            ),
          ],
        ]),
      ),
      _bottom(FilledButton(onPressed: () => setState(() => _step = 1), child: const Text('Kerjakan tugas'))),
    ]);
  }

  Widget _question(Question q, int n) {
    final order = q.type == 'order';
    final canCheck = order ? _order.length == q.blocks.length : _sel != null;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          Pill('SOAL $_step DARI $n', bg: C.bg2, fg: C.ink2),
          const SizedBox(height: 10),
          Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
          if (q.code != null) ...[const SizedBox(height: 12), CodeBlock(q.code!)],
          if (q.table != null) ...[const SizedBox(height: 12), _truthTable(q.table!)],
          const SizedBox(height: 16),
          if (!order)
            for (var i = 0; i < q.opts.length; i++) _option(q, i)
          else
            _orderTask(q),
        ]),
      ),
      if (_checked) _feedback(q),
      _bottom(_checked
          ? FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _right ? C.ok : C.err),
              onPressed: _saving ? null : () => _next(n),
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(_step == n ? 'Lihat hasil' : 'Lanjut'),
            )
          : FilledButton(onPressed: canCheck ? () => _check(q) : null, child: const Text('Periksa'))),
    ]);
  }

  Widget _option(Question q, int i) {
    final sel = _sel == i;
    Color border = sel ? C.primary : C.line;
    Color bg = sel ? C.primary50 : Colors.white;
    if (_checked && i == q.answer) {
      border = C.ok;
      bg = C.ok50;
    } else if (_checked && sel) {
      border = C.err;
      bg = C.err50;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border, width: 2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _checked ? null : () => setState(() => _sel = i),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border, width: 2)),
                child: Center(child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.opts[i], style: GoogleFonts.jetBrainsMono(fontSize: 14))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _orderTask(Question q) {
    final left = q.pool.where((b) => !_order.contains(b)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _checked ? (_right ? C.ok : C.err) : C.line, width: 2),
        ),
        child: _order.isEmpty
            ? const Center(child: Text('Ketuk blok di bawah sesuai urutan yang benar', style: TextStyle(color: C.ink3)))
            : Column(children: [
                for (var i = 0; i < _order.length; i++)
                  _block('${i + 1}. ${q.blocks[_order[i]]}', C.primary50, _checked ? null : () => setState(() => _order.removeAt(i))),
              ]),
      ),
      const SizedBox(height: 14),
      for (final b in left) _block(q.blocks[b], C.bg2, _checked ? null : () => setState(() => _order.add(b))),
    ]);
  }

  Widget _block(String text, Color bg, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Text(text, style: GoogleFonts.jetBrainsMono(fontSize: 13.5)),
            ),
          ),
        ),
      );

  Widget _truthTable(Map<String, dynamic> t) {
    final head = (t['head'] as List).cast<String>();
    final rows = (t['rows'] as List).map((r) => (r as List).cast<String>()).toList();
    TableRow row(List<String> cells, {bool h = false}) => TableRow(
          decoration: BoxDecoration(color: h ? C.bg2 : Colors.white),
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(c, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(fontWeight: h || c == '?' ? FontWeight.w700 : FontWeight.w400, color: c == '?' ? C.primary : C.ink)),
              ),
          ],
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Table(border: TableBorder.all(color: C.line), children: [row(head, h: true), ...rows.map(row)]),
    );
  }

  Widget _feedback(Question q) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _right ? C.ok50 : C.err50, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_right ? 'Benar!' : 'Belum tepat', style: GoogleFonts.rubik(fontWeight: FontWeight.w600, color: _right ? C.ok : C.err, fontSize: 16)),
          if (q.explanation != null) ...[const SizedBox(height: 4), Text(q.explanation!, style: const TextStyle(color: C.ink2))],
        ]),
      );

  Widget _result(int n) {
    final passed = _correct >= passMin(n);
    final first = !(widget.prev?.passed ?? false);
    return Column(children: [
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(color: passed ? C.reward : C.err50, shape: BoxShape.circle),
                child: Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 50, color: passed ? Colors.white : C.err),
              ),
              const SizedBox(height: 20),
              Text(passed ? 'Pembahasan lulus!' : 'Belum lulus', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Benar $_correct dari $n soal (minimal ${passMin(n)}).', style: const TextStyle(color: C.ink2)),
              const SizedBox(height: 16),
              if (passed && first) Pill('+${widget.lesson.xp} XP', bg: C.reward50, fg: const Color(0xFF8A5A00), icon: Icons.bolt),
              if (!passed) const Text('Baca lagi materinya, lalu coba sekali lagi.', style: TextStyle(color: C.ink3)),
            ]),
          ),
        ),
      ),
      _bottom(FilledButton(onPressed: () => Get.back(result: passed), child: Text(passed ? 'Lanjut' : 'Kembali'))),
    ]);
  }

  Widget _bottom(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), child: child);
}

class CodeBlock extends StatelessWidget {
  final String code;
  const CodeBlock(this.code, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(14)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(code, style: GoogleFonts.jetBrainsMono(color: const Color(0xFFE6E7F2), fontSize: 13, height: 1.5)),
        ),
      );
}

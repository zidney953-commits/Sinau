import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

Map<String, (String, IconData, Color, Color)> get feedbackTypes => {
  'saran': ('Saran', Icons.auto_awesome_outlined, C.primary, C.primary50),
  'error': ('Error aplikasi', Icons.error_outline, C.err, C.err50),
  'soal': ('Soal/materi salah', Icons.flag_outlined, C.rewardInk, C.reward50),
};

/// Kirim masukan ke admin (tabel feedback). Halaman asal ikut dicatat sebagai konteks.
class FeedbackSheet extends StatefulWidget {
  final String page;
  const FeedbackSheet({super.key, required this.page});
  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  String _type = 'saran';
  final _text = TextEditingController();
  String? _err;
  bool _busy = false;

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.length < 5) return setState(() => _err = 'Tulis minimal 5 karakter');
    setState(() => _busy = true);
    try {
      await Repo.sendFeedback(_type, t, {'Halaman': widget.page});
      Get.back();
      toast('Terima kasih! Masukanmu terkirim ke admin.');
    } catch (e) {
      setState(() {
        _busy = false;
        _err = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 14),
            Text('Kirim masukan', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Dari halaman ${widget.page}. Admin akan membacanya.', style: TextStyle(color: C.ink3)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in feedbackTypes.entries)
                ChoiceChip(
                  selected: _type == e.key,
                  onSelected: (_) => setState(() => _type = e.key),
                  avatar: Icon(e.value.$2, size: 18, color: e.value.$3),
                  label: Text(e.value.$1),
                  selectedColor: e.value.$4,
                  showCheckmark: false,
                ),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              maxLines: 4,
              maxLength: 1000,
              onChanged: (_) => _err != null ? setState(() => _err = null) : null,
              decoration: InputDecoration(hintText: 'Ceritakan saran atau error yang kamu temui…', errorText: _err),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Kirim'),
            ),
          ]),
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

/// Lupa kata sandi: 1) email → 2) kode OTP dari email → 3) kata sandi baru.
class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({super.key, this.email = ''});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController(), _pass = TextEditingController(), _pass2 = TextEditingController();
  final _k1 = GlobalKey<FormState>(), _k3 = GlobalKey<FormState>();
  String? _err;
  bool _busy = false, _hide = true;
  int _wait = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _wait <= 1) {
        t.cancel();
        if (mounted) setState(() => _wait = 0);
      } else {
        setState(() => _wait--);
      }
    });
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await f();
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    if (_step == 0 && !_k1.currentState!.validate()) return;
    await _run(() async {
      await Api.i.sendRecoveryCode(_email.text.trim().toLowerCase());
      _startCooldown();
      setState(() => _step = 1);
      toast('Kode dikirim ke ${_email.text.trim()}');
    });
  }

  Future<void> _verify() async {
    final c = _code.text.trim();
    if (!RegExp(r'^\d{6,8}$').hasMatch(c)) return setState(() => _err = 'Masukkan kode angka dari email.');
    await _run(() async {
      await Api.i.verifyRecoveryCode(_email.text.trim().toLowerCase(), c);
      setState(() => _step = 2);
    });
  }

  Future<void> _savePassword() async {
    if (!_k3.currentState!.validate()) return;
    await _run(() async {
      await Api.i.updatePassword(_pass.text);
      final auth = Get.find<AuthController>();
      toast('Kata sandi berhasil diganti');
      if (await auth.loadProfile()) {
        auth.goHome();
      } else {
        Get.back();
      }
    });
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        child: SingleChildScrollView(
          child: Column(children: [
            Stack(children: [
              const AuthHero(title: 'Lupa sandi', subtitle: 'Atur ulang kata sandi lewat kode di email'),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8, right: 8,
                child: IconButton(onPressed: Get.back, icon: const Icon(Icons.close, color: Colors.white70)),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _stepper(),
                const SizedBox(height: 20),
                if (_err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: C.err50, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: C.err),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_err!, style: const TextStyle(color: C.err, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                [_emailStep, _codeStep, _passStep][_step](),
              ]),
            ),
          ]),
        ),
      );

  Widget _stepper() => Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: i < _step ? C.ok : (i == _step ? C.primary : C.bg2), shape: BoxShape.circle),
            child: Center(
              child: i < _step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('${i + 1}', style: TextStyle(color: i == _step ? Colors.white : C.ink3, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 6),
          Text(['Email', 'Kode', 'Sandi baru'][i], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: i == _step ? C.ink : C.ink3)),
          if (i < 2) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: i < _step ? C.ok : C.line)),
        ],
      ]);

  Widget _button(String label, VoidCallback onTap) => FilledButton(
        onPressed: _busy ? null : onTap,
        child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(label),
      );

  Widget _emailStep() => Form(
        key: _k1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Masukkan email akun Sinau kamu. Kami akan mengirim kode verifikasi ke email itu.', style: TextStyle(color: C.ink2, height: 1.5)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@gmail.com', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Email wajib diisi' : !emailRe.hasMatch(v!.trim()) ? 'Format email salah' : null,
          ),
          const SizedBox(height: 20),
          _button('Kirim kode', _sendCode),
        ]),
      );

  Widget _codeStep() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(TextSpan(style: const TextStyle(color: C.ink2, height: 1.5), children: [
          const TextSpan(text: 'Kode verifikasi sudah dikirim ke '),
          TextSpan(text: _email.text.trim(), style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
          const TextSpan(text: '. Cek kotak masuk atau folder Spam. Kode berlaku 1 jam.'),
        ])),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _err != null ? setState(() => _err = null) : null,
          onSubmitted: (_) => _verify(),
          style: GoogleFonts.jetBrainsMono(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 10),
          decoration: const InputDecoration(hintText: '••••••', counterText: ''),
        ),
        const SizedBox(height: 16),
        _button('Verifikasi kode', _verify),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Belum menerima kode? ', style: TextStyle(color: C.ink2)),
          _wait > 0
              ? Text('Kirim ulang (${_wait}s)', style: const TextStyle(color: C.ink3, fontWeight: FontWeight.w800))
              : GestureDetector(onTap: _busy ? null : _sendCode, child: const Text('Kirim ulang', style: TextStyle(color: C.primary, fontWeight: FontWeight.w800))),
        ]),
        TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Ganti email')),
      ]);

  Widget _passStep() => Form(
        key: _k3,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Kode benar. Buat kata sandi baru untuk akunmu.', style: TextStyle(color: C.ink2)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pass,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Kata sandi baru',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hide = !_hide)),
            ),
            validator: (v) => (v ?? '').length < 8 ? 'Minimal 8 karakter' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pass2,
            obscureText: _hide,
            onFieldSubmitted: (_) => _savePassword(),
            decoration: const InputDecoration(labelText: 'Ulangi kata sandi baru', prefixIcon: Icon(Icons.lock_reset)),
            validator: (v) => v != _pass.text ? 'Kata sandi tidak sama' : null,
          ),
          const SizedBox(height: 20),
          _button('Simpan & masuk', _savePassword),
        ]),
      );
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String? _error;
  final auth = Get.find<AuthController>();

  int get _strength {
    final p = _pass.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p) || p.length >= 12) s++;
    return s;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final err = await auth.signUp(_name.text, _email.text, _pass.text);
    if (!mounted) return;
    if (err == 'CONFIRM') {
      Get.back();
      toast('Akun dibuat. Cek email kamu untuk konfirmasi, lalu masuk.');
    } else if (err != null) {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final st = _strength;
    final stColor = [C.err, C.err, C.reward, C.ok, C.ok][st];
    return AuthFrame(
      child: SingleChildScrollView(
        child: Column(children: [
          Stack(children: [
            const AuthHero(title: 'Daftar', subtitle: 'Gabung dan mulai belajar setiap hari'),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8, right: 8,
              child: IconButton(onPressed: Get.back, icon: const Icon(Icons.close, color: Colors.white70)),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: C.err50, borderRadius: BorderRadius.circular(14)),
                    child: Text(_error!, style: const TextStyle(color: C.err, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _name,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person_outline), counterText: ''),
                  validator: (v) => (v ?? '').trim().length < 3 ? 'Nama minimal 3 karakter' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@gmail.com', prefixIcon: Icon(Icons.mail_outline)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Email wajib diisi' : !emailRe.hasMatch(v!.trim()) ? 'Format email salah' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: _hide,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hide = !_hide)),
                  ),
                  validator: (v) => (v ?? '').length < 8 ? 'Minimal 8 karakter' : null,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Container(
                        height: 5, margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(color: i < st ? stColor : C.line, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(['Terlalu pendek', 'Lemah', 'Cukup', 'Kuat', 'Sangat kuat'][st], style: TextStyle(fontSize: 12, color: stColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.primary50, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.school_outlined, color: C.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Angkatan otomatis $now, sesuai tahun kamu mendaftar.', style: const TextStyle(color: C.primary, fontWeight: FontWeight.w600))),
                  ]),
                ),
                const SizedBox(height: 20),
                Obx(() => FilledButton(
                      onPressed: auth.loading.value ? null : _submit,
                      child: auth.loading.value
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Buat akun'),
                    )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

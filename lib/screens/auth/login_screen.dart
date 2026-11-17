import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'forgot_password_screen.dart';

final emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Di HP tampil penuh; di tablet/laptop jadi kartu di tengah dengan latar gelap.
class AuthFrame extends StatelessWidget {
  final Widget child;
  const AuthFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) return Scaffold(body: child);
    return Scaffold(
      backgroundColor: C.ink,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 820),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: C.bg, borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 16))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Kepala halaman gelap dengan logo (dipakai login & daftar).
class AuthHero extends StatelessWidget {
  final String title, subtitle;
  const AuthHero({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: C.ink,
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 28, 24, 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: LogoMark(size: 24)),
            ),
            const SizedBox(width: 10),
            Text('MACHINE LEARNING', style: GoogleFonts.rubik(color: Colors.white70, fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 26),
          Text(title, style: GoogleFonts.rubik(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFFB9BCD3), fontSize: 15)),
        ]),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String? _error;
  final auth = Get.find<AuthController>();

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final err = await auth.signIn(_email.text, _pass.text);
    if (err != null && mounted) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        child: SingleChildScrollView(
          child: Column(children: [
            const AuthHero(title: 'Sinau', subtitle: 'Lanjutkan belajarmu'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Masuk', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('Gunakan akun Sinau kamu.', style: TextStyle(color: C.ink2)),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: C.err50, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: C.err),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(color: C.err, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@gmail.com', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : !emailRe.hasMatch(v.trim()) ? 'Format email salah' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hide = !_hide)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : v.length < 8 ? 'Minimal 8 karakter' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => ForgotPasswordScreen(email: _email.text.trim())),
                      child: const Text('Lupa kata sandi?', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => FilledButton(
                        onPressed: auth.loading.value ? null : _submit,
                        child: auth.loading.value
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Masuk'),
                      )),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Belum punya akun? ', style: TextStyle(color: C.ink2)),
                    GestureDetector(
                      onTap: () => Get.toNamed('/register'),
                      child: const Text('Daftar', style: TextStyle(color: C.primary, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      );
}

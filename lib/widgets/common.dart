import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/app_controllers.dart';
import '../core/theme.dart';

/// Logo Sinau (jaringan titik, sama dengan prototipe).
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 32;
    final line = Paint()
      ..color = const Color(0xFFC9C5F2)
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(8 * k, 9 * k), Offset(16 * k, 16 * k), line);
    c.drawLine(Offset(8 * k, 23 * k), Offset(16 * k, 16 * k), line);
    c.drawLine(Offset(16 * k, 16 * k), Offset(25 * k, 16 * k), line);
    final p = Paint()..color = C.primary;
    c.drawCircle(Offset(8 * k, 9 * k), 4 * k, p);
    c.drawCircle(Offset(8 * k, 23 * k), 4 * k, p);
    c.drawCircle(Offset(16 * k, 16 * k), 4.2 * k, p);
    c.drawCircle(Offset(25 * k, 16 * k), 4.6 * k, Paint()..color = C.reward);
  }

  @override
  bool shouldRepaint(_) => false;
}

const _avc = [Color(0xFF4338CA), Color(0xFF1F9D6B), Color(0xFFC2372B), Color(0xFFB87503), Color(0xFF171A2B), Color(0xFF6D5BD0), Color(0xFF0E7C86), Color(0xFF9B3D8F)];

String initials(String n) => n.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

/// Avatar: foto jika ada, jika tidak memakai inisial nama.
class Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const Avatar(this.name, {super.key, this.url, this.size = 40});
  @override
  Widget build(BuildContext context) {
    final color = _avc[name.codeUnits.fold<int>(0, (a, b) => a + b) % _avc.length];
    final fallback = Center(
      child: Text(initials(name), style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * .36)),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: url == null ? color : C.bg2),
      child: url == null ? fallback : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: color, child: fallback)),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color? bg, fg;
  final IconData? icon;
  const Pill(this.text, {super.key, this.bg, this.fg, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg ?? C.primary50, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg ?? C.primary), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: fg ?? C.primary, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
}

/// Status kosong / galat / memuat yang konsisten.
class StateView extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  final Color? tint;
  const StateView({super.key, required this.icon, required this.title, required this.body, this.action, this.onAction, Color? color}) : tint = color;
  Color get color => tint ?? C.primary;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(24)),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(color: C.ink2), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 200, child: FilledButton(onPressed: onAction, child: Text(action!))),
            ],
          ]),
        ),
      );
}

/// Pembungkus data async: memuat → galat (coba lagi) → konten.
class AsyncView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  const AsyncView({super.key, required this.future, required this.builder, required this.onRetry});
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (_, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) {
            return StateView(icon: Icons.wifi_off_rounded, color: C.err, title: 'Gagal memuat', body: s.error.toString(), action: 'Coba lagi', onAction: onRetry);
          }
          return builder(s.data as T);
        },
      );
}

void toast(String msg, {bool error = false}) {
  Get.closeAllSnackbars();
  Get.rawSnackbar(
    message: msg,
    backgroundColor: error ? C.err : C.ink,
    margin: const EdgeInsets.all(14),
    borderRadius: 16,
    duration: const Duration(seconds: 3),
    icon: Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
  );
}

Future<bool> confirm(String title, String body, {String ok = 'Ya', bool danger = false}) async {
  final r = await Get.dialog<bool>(AlertDialog(
    backgroundColor: C.bg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
      TextButton(
        onPressed: () => Get.back(result: true),
        child: Text(ok, style: TextStyle(color: danger ? C.err : C.primary, fontWeight: FontWeight.w700)),
      ),
    ],
  ));
  return r ?? false;
}

/// Menampilkan state LoadController secara reaktif dengan Obx:
/// memuat → spinner, gagal → pesan + Coba lagi, berhasil → builder(data).
class ObxLoad<T> extends StatelessWidget {
  final LoadController<T> controller;
  final Widget Function(T data) builder;
  const ObxLoad({super.key, required this.controller, required this.builder});
  @override
  Widget build(BuildContext context) => Obx(() {
        final d = controller.data.value;
        if (d == null && controller.error.value != null) {
          return StateView(icon: Icons.wifi_off_rounded, color: C.err, title: 'Gagal memuat', body: controller.error.value!, action: 'Coba lagi', onAction: controller.load);
        }
        if (d == null) return const Center(child: CircularProgressIndicator());
        return builder(d);
      });
}

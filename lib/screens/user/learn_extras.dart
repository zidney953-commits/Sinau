import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/app_controllers.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

Future<void> openLink(String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) toast('Tautan tidak bisa dibuka', error: true);
}

String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays == 1) return 'kemarin';
  return '${d.inDays} hari lalu';
}

// ============================ BERITA TI ============================

/// Berita teknologi terkini (berganti setiap hari), digeser ke samping.
class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<NewsController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.newspaper_rounded, color: C.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('Berita TI hari ini', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700))),
        Text('Geser →', style: TextStyle(color: C.ink3, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      Text('Topik teknologi terbaru, berganti setiap hari', style: TextStyle(color: C.ink3, fontSize: 12.5)),
      const SizedBox(height: 10),
      SizedBox(
        height: 262,
        child: Obx(() {
          final items = c.data.value;
          if (c.error.value != null && items == null) {
            return Center(
              child: TextButton.icon(onPressed: c.load, icon: const Icon(Icons.refresh), label: const Text('Berita belum bisa dimuat · Coba lagi')),
            );
          }
          if (items == null) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => Container(width: 250, decoration: BoxDecoration(color: C.bg2, borderRadius: BorderRadius.circular(18))),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _NewsCard(items[i]),
          );
        }),
      ),
    ]);
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem n;
  const _NewsCard(this.n);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 250,
        child: Material(
          color: C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: C.line)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openLink(n.link),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: n.image == null
                    ? _imgFallback()
                    : Image.network(
                        n.image!,
                        fit: BoxFit.cover,
                        // Web: pakai elemen <img> jika server gambar tidak mengizinkan CORS.
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        errorBuilder: (_, _, _) => _imgFallback(),
                        loadingBuilder: (_, child, p) => p == null ? child : Container(color: C.bg2),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Pill(n.source, bg: C.primary50, fg: C.primary)),
                    const SizedBox(width: 6),
                    Flexible(child: Text(timeAgo(n.published), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink3, fontSize: 11.5))),
                  ]),
                  const SizedBox(height: 6),
                  Text(n.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 14.5, height: 1.3)),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _imgFallback() => Container(color: C.bg2, child: Center(child: Icon(Icons.memory_rounded, color: C.ink3, size: 36)));
}

// ============================ PROMOSI APK ============================

/// Rasio tampilan seperti Instagram: 3:4 … 16:9. Gambar lebih tinggi (mis. 9:16) dipotong menjadi 3:4.
double feedRatio(double r) => r.clamp(3 / 4, 16 / 9);

/// Postingan promosi APK ala Instagram (gambar + caption): gambar dari assets/Gambar, ketuk untuk melihat penuh.
class PromoPost extends StatefulWidget {
  const PromoPost({super.key});
  @override
  State<PromoPost> createState() => _PromoPostState();
}

class _PromoPostState extends State<PromoPost> {
  final _pc = PageController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PromoController>();
    return Obx(() {
      final imgs = c.data.value;
      if (imgs == null || imgs.isEmpty) return const SizedBox();
      return Container(
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: C.primary, width: 1.5),
                ),
                child: const Center(child: LogoMark(size: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sinau', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('Promosi · ${AppConfig.brand}', style: TextStyle(color: C.ink3, fontSize: 12)),
                ]),
              ),
              Pill('APK', bg: C.reward50, fg: C.rewardInk, icon: Icons.android_rounded),
            ]),
          ),
          AspectRatio(
            aspectRatio: feedRatio(imgs.first.ratio),
            child: Stack(children: [
              PageView.builder(
                controller: _pc,
                itemCount: imgs.length,
                onPageChanged: (i) => c.page.value = i,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Get.dialog(PromoViewer(images: imgs, initial: i), barrierColor: Colors.black, useSafeArea: false),
                  child: Image.asset(imgs[i].asset, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
              ),
              if (imgs.length > 1)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text('${c.page.value + 1}/${imgs.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              Positioned(
                left: 10, bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Ketuk untuk lihat penuh', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          // Titik penanda gambar (hanya jika gambarnya lebih dari satu).
          if (imgs.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < imgs.length; i++)
                  Container(
                    width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: i == c.page.value ? C.primary : C.line, shape: BoxShape.circle),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Sinau ', style: TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(text: 'Belajar coding jadi lebih mudah! Kuasai pemrograman langkah demi langkah, langsung dari HP-mu. '),
                TextSpan(text: '#BelajarBarengSinau', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
              ]),
              style: TextStyle(color: C.ink2, height: 1.45, fontSize: 13.5),
            ),
          ),
        ]),
      );
    });
  }
}

/// Tampilan penuh gambar promosi (bisa dicubit untuk zoom, geser untuk gambar lain).
class PromoViewer extends StatefulWidget {
  final List<PromoImage> images;
  final int initial;
  const PromoViewer({super.key, required this.images, this.initial = 0});
  @override
  State<PromoViewer> createState() => _PromoViewerState();
}

class _PromoViewerState extends State<PromoViewer> {
  late final _pc = PageController(initialPage: widget.initial);
  late final page = widget.initial.obs;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.images.length,
              onPageChanged: (i) => page.value = i,
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 4,
                child: Center(child: Image.asset(widget.images[i].asset, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                onPressed: Get.back,
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Tutup',
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                top: 18, left: 0, right: 0,
                child: Center(
                  child: Obx(() => Text('${page.value + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ),
              ),
          ]),
        ),
      );
}

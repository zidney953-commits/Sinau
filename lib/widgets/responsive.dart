import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'common.dart';

/// Ukuran layar: HP < 600 ≤ Tablet < 1024 ≤ Laptop.
enum Screen { phone, tablet, laptop }

Screen screenOf(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  return w < 600 ? Screen.phone : (w < 1024 ? Screen.tablet : Screen.laptop);
}

class NavItem {
  final IconData icon, activeIcon;
  final String label;
  final int badge;
  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
}

/// Kerangka aplikasi seperti prototipe:
/// HP = menu bawah · Tablet = rail kiri dengan logo · Laptop = sidebar berlabel.
class AppShell extends StatelessWidget {
  final List<NavItem> items;
  final List<Widget> pages;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget? fab;
  const AppShell({super.key, required this.items, required this.pages, required this.index, required this.onSelect, this.fab});

  @override
  Widget build(BuildContext context) {
    final s = screenOf(context);
    final body = IndexedStack(index: index, children: pages);
    if (s == Screen.phone) {
      return Scaffold(
        body: body,
        floatingActionButton: fab,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.line))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(children: [
                for (var i = 0; i < items.length; i++) Expanded(child: _BottomItem(item: items[i], active: i == index, onTap: () => onSelect(i))),
              ]),
            ),
          ),
        ),
      );
    }
    final laptop = s == Screen.laptop;
    return Scaffold(
      floatingActionButton: fab,
      body: Row(children: [
        Container(
          width: laptop ? 232 : 88,
          decoration: BoxDecoration(color: C.surface, border: Border(right: BorderSide(color: C.line))),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(laptop ? 20 : 0, 20, 0, 18),
                child: Row(mainAxisAlignment: laptop ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                  const LogoMark(size: 30),
                  if (laptop) ...[const SizedBox(width: 10), Text('Sinau', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700))],
                ]),
              ),
              for (var i = 0; i < items.length; i++) _SideItem(item: items[i], active: i == index, wide: laptop, onTap: () => onSelect(i)),
            ]),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: BoxConstraints(maxWidth: laptop ? 1120 : 760), child: body),
          ),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final int n;
  const _Badge(this.n);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
        decoration: BoxDecoration(color: C.reward, borderRadius: BorderRadius.circular(9), border: Border.all(color: C.surface, width: 2)),
        child: Center(child: Text('$n', style: const TextStyle(color: C.onReward, fontSize: 10, fontWeight: FontWeight.w800))),
      );
}

class _BottomItem extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _BottomItem({required this.item, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28, height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: active ? C.primary : Colors.transparent, borderRadius: BorderRadius.circular(3)),
          ),
          Stack(clipBehavior: Clip.none, children: [
            Icon(active ? item.activeIcon : item.icon, color: active ? C.primary : C.ink3, size: 24),
            if (item.badge > 0) Positioned(right: -10, top: -6, child: _Badge(item.badge)),
          ]),
          const SizedBox(height: 3),
          Text(item.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? C.primary : C.ink3)),
        ]),
      );
}

class _SideItem extends StatelessWidget {
  final NavItem item;
  final bool active, wide;
  final VoidCallback onTap;
  const _SideItem({required this.item, required this.active, required this.wide, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final icon = Stack(clipBehavior: Clip.none, children: [
      Icon(active ? item.activeIcon : item.icon, color: active ? C.primary : C.ink2, size: 22),
      if (item.badge > 0 && !wide) Positioned(right: -9, top: -6, child: _Badge(item.badge)),
    ]);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 10, vertical: 3),
      child: Material(
        color: active ? C.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 0, vertical: wide ? 11 : 10),
            child: wide
                ? Row(children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? C.primary : C.ink2))),
                    if (item.badge > 0) _Badge(item.badge),
                  ])
                : Column(children: [
                    icon,
                    const SizedBox(height: 4),
                    Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? C.primary : C.ink2)),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Judul halaman seperti prototipe: judul + keterangan kecil + aksi di kanan.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  const PageHeader(this.title, {super.key, this.subtitle, this.trailing, this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(onBack != null ? 6 : 20, 16, 20, 12),
        child: Row(children: [
          if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left, size: 28)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700, color: C.ink)),
              if (subtitle != null) Text(subtitle!, style: TextStyle(color: C.ink3, fontSize: 12.5)),
            ]),
          ),
          ?trailing,
        ]),
      );
}

/// Kartu putih bergaris tipis dengan judul bagian (dipakai di banyak layar).
class SectionCard extends StatelessWidget {
  final String? title, subtitle;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard({super.key, this.title, this.subtitle, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) Text(title!, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600)),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: TextStyle(color: C.ink3, fontSize: 12.5))),
          if (title != null) const SizedBox(height: 12),
          child,
        ]),
      );
}

/// Grid responsif: 1 kolom di HP, 2 kolom di layar lebar.
class ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  const ResponsiveColumns({super.key, required this.children, this.gap = 14});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        if (c.maxWidth < 720) {
          return Column(children: [for (final w in children) Padding(padding: EdgeInsets.only(bottom: gap), child: w)]);
        }
        final left = <Widget>[], right = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          (i.isEven ? left : right).add(Padding(padding: EdgeInsets.only(bottom: gap), child: children[i]));
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: left)),
          SizedBox(width: gap),
          Expanded(child: Column(children: right)),
        ]);
      });
}

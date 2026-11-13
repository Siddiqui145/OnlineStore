import 'package:flutter/material.dart';
import 'models.dart';
import 'services.dart';
import 'theme.dart';

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
    .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, width: 420));

String money(num v) => '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({required this.child, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: child,
      );
}

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageTitle(this.title, {this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kInk)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: const TextStyle(color: kMuted)),
                ),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, hint;
  const EmptyState(this.icon, this.title, this.hint);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 44, color: kMuted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(color: kMuted), textAlign: TextAlign.center),
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'new' => (const Color(0xFFFFF1CF), const Color(0xFF8A5A00)),
      'contacted' => (const Color(0xFFE0ECFF), const Color(0xFF1D4ED8)),
      'in_progress' => (const Color(0xFFEDE5FF), const Color(0xFF6D28D9)),
      'completed' => (const Color(0xFFDDF5E5), const Color(0xFF15803D)),
      _ => (const Color(0xFFEDEFF3), const Color(0xFF59677B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabel(status), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

// ---------------- Navigation shell shared by customer & admin ----------------
class Dest {
  final IconData icon;
  final String label;
  final Widget page;
  final int badge;
  Dest(this.icon, this.label, this.page, {this.badge = 0});
}

class Shell extends StatefulWidget {
  final String title;
  final AppUser user;
  final List<Dest> dests;
  const Shell({required this.title, required this.user, required this.dests});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  Widget icon(Dest d) => Badge(
        isLabelVisible: d.badge > 0,
        label: Text('${d.badge}'),
        child: Icon(d.icon),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final d = widget.dests;
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.all(wide ? 28 : 16),
          child: KeyedSubtree(key: ValueKey(i), child: d[i].page),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.settings, size: 18, color: kInk),
          ),
          const SizedBox(width: 10),
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text(widget.user.name, style: const TextStyle(color: kMuted))),
            ),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: Repo.signOut),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                extended: true,
                minExtendedWidth: 210,
                selectedIndex: i,
                onDestinationSelected: (v) => setState(() => i = v),
                destinations: [
                  for (final x in d) NavigationRailDestination(icon: icon(x), label: Text(x.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: i,
              onDestinationSelected: (v) => setState(() => i = v),
              destinations: [for (final x in d) NavigationDestination(icon: icon(x), label: x.label)],
            ),
    );
  }
}

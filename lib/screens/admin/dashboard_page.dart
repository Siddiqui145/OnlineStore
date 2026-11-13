import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<OrderModel>>(
        stream: Repo.allOrders(),
        builder: (context, os) => StreamBuilder<List<Product>>(
          stream: Repo.products(),
          builder: (context, ps) {
            if (os.hasError || ps.hasError) {
              return Center(child: Text('Could not load data: ${os.error ?? ps.error}'));
            }
            if (!os.hasData || !ps.hasData) return const Center(child: CircularProgressIndicator());
            final o = os.data!, p = ps.data!;
            int c(String s) => o.where((x) => x.status == s).length;
            final low = p.where((x) => x.quantity <= 5).length;
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PageTitle('Dashboard', subtitle: 'Overview of orders, services and stock.'),
                Wrap(spacing: 16, runSpacing: 16, children: [
                  _Stat(Icons.mark_email_unread_outlined, 'New requests', c('new'), kAccent),
                  _Stat(Icons.autorenew, 'In progress', c('in_progress') + c('contacted'), const Color(0xFF6D28D9)),
                  _Stat(Icons.check_circle_outline, 'Completed', c('completed'), const Color(0xFF15803D)),
                  _Stat(Icons.inventory_2_outlined, 'Products', p.length, kInk),
                  _Stat(Icons.warning_amber_rounded, 'Low stock (≤5)', low, const Color(0xFFB42318)),
                ]),
                const SizedBox(height: 28),
                const Text('Recent requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 12),
                if (o.isEmpty)
                  const Panel(child: EmptyState(Icons.inbox_outlined, 'No requests yet', 'New orders will show up here.'))
                else
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (final x in o.take(8))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
                          child: Row(children: [
                            Icon(x.isService ? Icons.build_circle_outlined : Icons.inventory_2_outlined, color: kMuted),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(x.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(x.isService ? 'Service: ${x.serviceType}' : '${x.items.length} item(s) · ${money(x.total)}',
                                    style: const TextStyle(color: kMuted, fontSize: 12)),
                              ]),
                            ),
                            if (MediaQuery.of(context).size.width > 600)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text(x.createdAt == null ? '' : DateFormat('d MMM, h:mm a').format(x.createdAt!),
                                    style: const TextStyle(color: kMuted, fontSize: 12)),
                              ),
                            StatusChip(x.status),
                          ]),
                        ),
                    ]),
                  ),
              ]),
            );
          },
        ),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _Stat(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Panel(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ]),
        ),
      );
}

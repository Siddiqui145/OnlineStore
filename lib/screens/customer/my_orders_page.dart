import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle('My orders', subtitle: 'Track your parts orders and service requests.'),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: Repo.myOrders(),
            builder: (context, s) {
              if (s.hasError) return Center(child: Text('Could not load orders: ${s.error}'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              if (s.data!.isEmpty) {
                return const EmptyState(Icons.receipt_long_outlined, 'No orders yet', 'Your orders will appear here.');
              }
              return ListView.separated(
                itemCount: s.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final o = s.data![i];
                  return Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(o.isService ? Icons.build_circle_outlined : Icons.inventory_2_outlined, color: kInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(o.isService ? 'Service: ${o.serviceType}' : 'Parts order',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kInk)),
                        ),
                        StatusChip(o.status),
                      ]),
                      const SizedBox(height: 6),
                      Text(o.createdAt == null ? 'Just now' : DateFormat('d MMM yyyy, h:mm a').format(o.createdAt!),
                          style: const TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      if (o.isService)
                        Text(o.notes)
                      else ...[
                        for (final it in o.items) Text('${it['qty']} × ${it['name']}'),
                        const SizedBox(height: 6),
                        Text('Total ${money(o.total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String? status; // null = all
  String? type; // null = all

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle('Orders & requests', subtitle: 'Contact the customer, then update the status.'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('All'), selected: status == null, onSelected: (_) => setState(() => status = null)),
          for (final s in orderStatuses)
            ChoiceChip(label: Text(statusLabel(s)), selected: status == s, onSelected: (_) => setState(() => status = s)),
          const SizedBox(width: 12),
          ChoiceChip(label: const Text('Parts'), selected: type == 'spare_part', onSelected: (v) => setState(() => type = v ? 'spare_part' : null)),
          ChoiceChip(label: const Text('Services'), selected: type == 'service', onSelected: (v) => setState(() => type = v ? 'service' : null)),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: Repo.allOrders(),
            builder: (context, s) {
              if (s.hasError) return Center(child: Text('Could not load orders: ${s.error}'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!.where((o) => (status == null || o.status == status) && (type == null || o.type == type)).toList();
              if (list.isEmpty) return const EmptyState(Icons.inbox_outlined, 'Nothing here', 'No requests match these filters.');
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderTile(list[i]),
              );
            },
          ),
        ),
      ]);
}

class _OrderTile extends StatelessWidget {
  final OrderModel o;
  const _OrderTile(this.o);

  Future<void> _open(String url) async => launchUrl(Uri.parse(url));

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(color: kMuted))),
          Expanded(child: SelectableText(v.isEmpty ? '-' : v)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Panel(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: Icon(o.isService ? Icons.build_circle_outlined : Icons.inventory_2_outlined, color: kInk),
            title: Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${o.isService ? 'Service: ${o.serviceType}' : 'Parts · ${money(o.total)}'}'
              '${o.createdAt == null ? '' : '  ·  ${DateFormat('d MMM, h:mm a').format(o.createdAt!)}'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: StatusChip(o.status),
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _row('Phone', o.phone),
              _row('Email', o.email),
              _row('Address', o.address),
              if (o.isService && o.preferredDate.isNotEmpty) _row('Preferred', o.preferredDate),
              if (o.notes.isNotEmpty) _row(o.isService ? 'Job' : 'Notes', o.notes),
              if (!o.isService) ...[
                const SizedBox(height: 6),
                for (final it in o.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(child: Text('${it['qty']} × ${it['name']}')),
                      Text(money(((it['price'] ?? 0) as num) * ((it['qty'] ?? 1) as num))),
                    ]),
                  ),
              ],
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                OutlinedButton.icon(
                    onPressed: () => _open('tel:${o.phone}'), icon: const Icon(Icons.call_outlined), label: const Text('Call')),
                OutlinedButton.icon(
                    onPressed: () => _open('mailto:${o.email}'), icon: const Icon(Icons.mail_outline), label: const Text('Email')),
                const SizedBox(width: 8),
                const Text('Status:', style: TextStyle(color: kMuted)),
                DropdownButton<String>(
                  value: o.status,
                  underline: const SizedBox(),
                  items: [for (final s in orderStatuses) DropdownMenuItem(value: s, child: Text(statusLabel(s)))],
                  onChanged: (v) async {
                    if (v == null) return;
                    try {
                      await Repo.setStatus(o.id, v);
                    } catch (e) {
                      if (context.mounted) toast(context, 'Could not update status: $e');
                    }
                  },
                ),
              ]),
            ],
          ),
        ),
      );
}

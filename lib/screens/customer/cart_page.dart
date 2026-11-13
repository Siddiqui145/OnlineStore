import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'shop_page.dart';

class CartPage extends StatelessWidget {
  final AppUser user;
  const CartPage({required this.user});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.lines.isEmpty) {
            return const EmptyState(Icons.shopping_cart_outlined, 'Your cart is empty',
                'Add spare parts from the Shop tab.');
          }
          final lines = Panel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final l in cart.lines.values.toList()) _Line(l),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const Spacer(),
                  Text(money(cart.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kInk)),
                ]),
              ),
            ]),
          );
          final checkout = _CheckoutForm(user: user);
          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 860;
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PageTitle('Cart', subtitle: 'Review your parts and tell us where to reach you.'),
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: lines),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: checkout),
                  ])
                else ...[lines, const SizedBox(height: 16), checkout],
              ]),
            );
          });
        },
      );
}

class _Line extends StatelessWidget {
  final CartLine l;
  const _Line(this.l);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 56, height: 56, child: ProductImage(l.product.imageUrl)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(money(l.product.price), style: const TextStyle(color: kMuted)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.setQty(l.product, l.qty - 1)),
          Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.setQty(l.product, l.qty + 1)),
        ]),
      );
}

class _CheckoutForm extends StatefulWidget {
  final AppUser user;
  const _CheckoutForm({required this.user});
  @override
  State<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<_CheckoutForm> {
  final _key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.user.name);
  late final phone = TextEditingController(text: widget.user.phone);
  final address = TextEditingController(), notes = TextEditingController();
  bool busy = false;

  Future<void> place() async {
    if (!_key.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Repo.placeOrder({
        'type': 'spare_part',
        'customerName': name.text.trim(),
        'phone': phone.text.trim(),
        'email': widget.user.email,
        'address': address.text.trim(),
        'notes': notes.text.trim(),
        'items': cart.toItems(),
        'total': cart.total,
      });
      cart.clear();
      if (mounted) toast(context, 'Order placed. We will contact you shortly.');
    } catch (e) {
      if (mounted) {
        toast(context, 'Could not place order: $e');
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
        child: Form(
          key: _key,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Delivery details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: kInk)),
            const SizedBox(height: 16),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name'), validator: req),
            const SizedBox(height: 12),
            TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: req),
            const SizedBox(height: 12),
            TextFormField(
                controller: address,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Delivery address'),
                validator: req),
            const SizedBox(height: 12),
            TextFormField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccent, foregroundColor: kInk),
              onPressed: busy ? null : place,
              child: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Place order', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            const Text('Our team will call you to confirm the order and payment.',
                style: TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
      );
}

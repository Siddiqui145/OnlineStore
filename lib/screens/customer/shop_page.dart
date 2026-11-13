import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String q = '';

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle('Spare parts', subtitle: 'Browse the catalogue and add parts to your cart.'),
        TextField(
          decoration: const InputDecoration(hintText: 'Search by name or category', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => q = v.toLowerCase()),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: Repo.products(),
            builder: (context, s) {
              if (s.hasError) return Center(child: Text('Could not load products: ${s.error}'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!
                  .where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
                  .toList();
              if (list.isEmpty) {
                return const EmptyState(Icons.inventory_2_outlined, 'No parts found', 'Try a different search.');
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 350,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _ProductCard(list[i]),
              );
            },
          ),
        ),
      ]);
}

class _ProductCard extends StatelessWidget {
  final Product p;
  const _ProductCard(this.p);

  @override
  Widget build(BuildContext context) {
    final out = p.quantity <= 0;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
          child: SizedBox(height: 150, width: double.infinity, child: ProductImage(p.imageUrl)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.category, style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kInk)),
            const SizedBox(height: 4),
            Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              Text(money(p.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kInk)),
              const Spacer(),
              Text(out ? 'Out of stock' : '${p.quantity} in stock',
                  style: TextStyle(fontSize: 12, color: out ? const Color(0xFFB42318) : kMuted)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: out
                    ? null
                    : () {
                        cart.add(p);
                        toast(context, '${p.name} added to cart');
                      },
                child: const Text('Add to cart'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String url;
  const ProductImage(this.url, {super.key});
  @override
  Widget build(BuildContext context) {
    final ph = Container(
      color: const Color(0xFFEDF0F5),
      child: const Center(child: Icon(Icons.settings_outlined, size: 40, color: kMuted)),
    );
    if (url.isEmpty) return ph;
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ph);
  }
}

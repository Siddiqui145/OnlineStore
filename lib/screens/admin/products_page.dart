import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../services.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../customer/shop_page.dart' show ProductImage;

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  Future<void> _edit(BuildContext context, [Product? p]) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => ProductDialog(p: p));
    if (saved == true && context.mounted) toast(context, p == null ? 'Product added' : 'Product updated');
  }

  Future<void> _delete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${p.name}" will be removed from the catalogue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await Repo.deleteProduct(p);
      if (context.mounted) toast(context, 'Product deleted');
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTitle('Products',
            subtitle: 'Manage spare parts, prices and stock.',
            trailing: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: Repo.products(),
            builder: (context, s) {
              if (s.hasError) return Center(child: Text('Could not load products: ${s.error}'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              if (s.data!.isEmpty) {
                return const EmptyState(Icons.inventory_2_outlined, 'No products yet', 'Use "Add product" to create the first one.');
              }
              return ListView.separated(
                itemCount: s.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final p = s.data![i];
                  final low = p.quantity <= 5;
                  return Panel(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(width: 56, height: 56, child: ProductImage(p.imageUrl)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(p.category, style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      Text(money(p.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: low ? const Color(0xFFFEE4E2) : const Color(0xFFEDF0F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Qty ${p.quantity}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: low ? const Color(0xFFB42318) : kInk)),
                      ),
                      IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, p)),
                      IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, p)),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]);
}

class ProductDialog extends StatefulWidget {
  final Product? p;
  const ProductDialog({this.p});
  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.p?.name);
  late final category = TextEditingController(text: widget.p?.category);
  late final desc = TextEditingController(text: widget.p?.description);
  late final price = TextEditingController(text: widget.p == null ? '' : widget.p!.price.toString());
  late final qty = TextEditingController(text: widget.p == null ? '' : widget.p!.quantity.toString());
  XFile? image;
  Uint8List? preview;
  bool busy = false;
  String? err;

  Future<void> pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      image = x;
      preview = b;
    });
  }

  Future<void> save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      busy = true;
      err = null;
    });
    try {
      await Repo.saveProduct(
        id: widget.p?.id,
        image: image,
        data: {
          'name': name.text.trim(),
          'category': category.text.trim(),
          'description': desc.text.trim(),
          'price': double.parse(price.text.trim()),
          'quantity': int.parse(qty.text.trim()),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        err = 'Could not save: $e';
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.p == null ? 'Add product' : 'Edit product'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: pick,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF0F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kLine),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: preview != null
                        ? Image.memory(preview!, fit: BoxFit.cover)
                        : (widget.p?.imageUrl.isNotEmpty ?? false)
                            ? ProductImage(widget.p!.imageUrl)
                            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32, color: kMuted),
                                SizedBox(height: 6),
                                Text('Upload product photo', style: TextStyle(color: kMuted)),
                              ]),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: req),
                const SizedBox(height: 12),
                TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Category'), validator: req),
                const SizedBox(height: 12),
                TextFormField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (₹)'),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a whole number' : null,
                    ),
                  ),
                ]),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(err!, style: const TextStyle(color: Color(0xFFB42318))),
                  ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: busy ? null : save,
            child: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save product'),
          ),
        ],
      );
}

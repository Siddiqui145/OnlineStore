import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services.dart';
import '../../widgets.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';
import 'service_page.dart';
import 'shop_page.dart';

class CustomerHome extends StatelessWidget {
  final AppUser user;
  const CustomerHome({required this.user});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: cart,
        builder: (_, __) => Shell(
          title: 'DeshmukhAutoMobiles',
          user: user,
          dests: [
            Dest(Icons.storefront_outlined, 'Shop', const ShopPage()),
            Dest(Icons.shopping_cart_outlined, 'Cart', CartPage(user: user), badge: cart.count),
            Dest(Icons.build_circle_outlined, 'Book service', ServicePage(user: user)),
            Dest(Icons.receipt_long_outlined, 'My orders', const MyOrdersPage()),
          ],
        ),
      );
}

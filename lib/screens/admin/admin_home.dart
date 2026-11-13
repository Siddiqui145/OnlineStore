import 'dart:async';
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services.dart';
import '../../widgets.dart';
import 'dashboard_page.dart';
import 'orders_page.dart';
import 'products_page.dart';

class AdminHome extends StatefulWidget {
  final AppUser user;
  const AdminHome({required this.user});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  StreamSubscription<List<OrderModel>>? sub;
  Set<String>? seen;
  final newCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Live in-app alert whenever a new order or service request arrives.
    sub = Repo.allOrders().listen((list) {
      newCount.value = list.where((o) => o.status == 'new').length;
      if (seen != null && mounted) {
        for (final o in list.where((o) => !seen!.contains(o.id))) {
          toast(context, 'New ${o.isService ? 'service request' : 'order'} from ${o.customerName}');
        }
      }
      seen = list.map((e) => e.id).toSet();
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    newCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: newCount,
        builder: (_, n, __) => Shell(
          title: 'DeshmukhAutoMobiles Admin',
          user: widget.user,
          dests: [
            Dest(Icons.dashboard_outlined, 'Dashboard', const DashboardPage()),
            Dest(Icons.receipt_long_outlined, 'Orders', const OrdersPage(), badge: n),
            Dest(Icons.inventory_2_outlined, 'Products', const ProductsPage()),
          ],
        ),
      );
}

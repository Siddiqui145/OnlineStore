import 'package:cloud_firestore/cloud_firestore.dart';

typedef Doc = DocumentSnapshot<Map<String, dynamic>>;

const orderStatuses = ['new', 'contacted', 'in_progress', 'completed', 'cancelled'];
const serviceTypes = ['Repair', 'Installation', 'Maintenance', 'Inspection', 'Other'];

String statusLabel(String s) => switch (s) {
      'new' => 'New',
      'contacted' => 'Contacted',
      'in_progress' => 'In progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => s,
    };

class AppUser {
  final String uid, name, email, phone, role;
  AppUser(this.uid, this.name, this.email, this.phone, this.role);
  bool get isAdmin => role == 'admin';
  factory AppUser.fromDoc(Doc d) {
    final m = d.data()!;
    return AppUser(d.id, m['name'] ?? '', m['email'] ?? '', m['phone'] ?? '', m['role'] ?? 'customer');
  }
}

class Product {
  final String id, name, category, description, imageUrl;
  final double price;
  final int quantity;
  Product(this.id, this.name, this.category, this.description, this.imageUrl, this.price, this.quantity);
  factory Product.fromDoc(Doc d) {
    final m = d.data()!;
    return Product(
      d.id,
      m['name'] ?? '',
      m['category'] ?? '',
      m['description'] ?? '',
      m['imageUrl'] ?? '',
      (m['price'] ?? 0).toDouble(),
      (m['quantity'] ?? 0).toInt(),
    );
  }
}

class OrderModel {
  final String id, type, userId, customerName, phone, email, address, status, notes, serviceType, preferredDate;
  final List<Map<String, dynamic>> items;
  final double total;
  final DateTime? createdAt;
  OrderModel(this.id, this.type, this.userId, this.customerName, this.phone, this.email, this.address,
      this.status, this.notes, this.serviceType, this.preferredDate, this.items, this.total, this.createdAt);
  bool get isService => type == 'service';
  factory OrderModel.fromDoc(Doc d) {
    final m = d.data()!;
    return OrderModel(
      d.id,
      m['type'] ?? 'spare_part',
      m['userId'] ?? '',
      m['customerName'] ?? '',
      m['phone'] ?? '',
      m['email'] ?? '',
      m['address'] ?? '',
      m['status'] ?? 'new',
      m['notes'] ?? '',
      m['serviceType'] ?? '',
      m['preferredDate'] ?? '',
      List<Map<String, dynamic>>.from((m['items'] ?? []).map((e) => Map<String, dynamic>.from(e))),
      (m['total'] ?? 0).toDouble(),
      (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

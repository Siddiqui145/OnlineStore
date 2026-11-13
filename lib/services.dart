import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';

class Repo {
  static final auth = FirebaseAuth.instance;
  static final db = FirebaseFirestore.instance;
  static final storage = FirebaseStorage.instance;
  static String get uid => auth.currentUser!.uid;

  /// True while sign-up is writing the profile, so the auth gate doesn't race it.
  static bool signingUp = false;

  // ---- auth ----
  static Future<void> signIn(String email, String pass) =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: pass);

  static Future<void> signUp(String name, String phone, String email, String pass) async {
    signingUp = true;
    try {
      final c = await auth.createUserWithEmailAndPassword(email: email.trim(), password: pass);
      await db.collection('users').doc(c.user!.uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      signingUp = false;
    }
  }

  static Future<void> signOut() => auth.signOut();

  /// Creates a profile if one is missing (e.g. user created from the console).
  static Future<void> ensureUser(User u) async {
    if (signingUp) return;
    final r = db.collection('users').doc(u.uid);
    if (!(await r.get()).exists) {
      await r.set({
        'name': u.email?.split('@').first ?? 'User',
        'phone': '',
        'email': u.email ?? '',
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<AppUser?> userStream(String uid) =>
      db.collection('users').doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  // ---- products ----
  static Stream<List<Product>> products() => db
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  static Future<void> saveProduct({String? id, required Map<String, dynamic> data, XFile? image}) async {
    final ref = db.collection('products').doc(id);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final file = storage.ref('products/${ref.id}_${DateTime.now().millisecondsSinceEpoch}');
      await file.putData(bytes, SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'));
      data['imageUrl'] = await file.getDownloadURL();
    }
    if (id == null) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
  }

  static Future<void> deleteProduct(Product p) async {
    await db.collection('products').doc(p.id).delete();
    if (p.imageUrl.isNotEmpty) {
      try {
        await storage.refFromURL(p.imageUrl).delete();
      } catch (_) {}
    }
  }

  // ---- orders ----
  static Stream<List<OrderModel>> allOrders() => db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  static Stream<List<OrderModel>> myOrders() =>
      db.collection('orders').where('userId', isEqualTo: uid).snapshots().map((s) {
        final l = s.docs.map(OrderModel.fromDoc).toList();
        l.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return l;
      });

  static Future<void> placeOrder(Map<String, dynamic> data) => db.collection('orders').add({
        ...data,
        'userId': uid,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> setStatus(String id, String status) =>
      db.collection('orders').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
}

// ---- cart (in-memory) ----
class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, this.qty);
}

class Cart extends ChangeNotifier {
  final Map<String, CartLine> lines = {};
  int get count => lines.values.fold(0, (a, l) => a + l.qty);
  double get total => lines.values.fold(0.0, (a, l) => a + l.qty * l.product.price);

  void add(Product p) {
    final l = lines[p.id];
    if (l == null) {
      lines[p.id] = CartLine(p, 1);
    } else if (l.qty < p.quantity) {
      l.qty++;
    }
    notifyListeners();
  }

  void setQty(Product p, int q) {
    if (q <= 0) {
      lines.remove(p.id);
    } else {
      lines[p.id]?.qty = q.clamp(1, p.quantity);
    }
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toItems() => lines.values
      .map((l) => {'productId': l.product.id, 'name': l.product.name, 'qty': l.qty, 'price': l.product.price})
      .toList();
}

final cart = Cart();

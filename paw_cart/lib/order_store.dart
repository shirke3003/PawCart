import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'order_model.dart';


class OrderStore {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  CollectionReference<Map<String, dynamic>> get _ordersCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to access your orders.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders');
  }

  Stream<List<PawCartOrder>> watchOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = data['id'] ?? doc.id;
              return PawCartOrder.fromMap(data);
            }).toList());
  }

  Future<void> add(PawCartOrder order) async {
    await _ordersCollection.doc(order.id).set(order.toMap());
  }

  Future<void> updateStatus(PawCartOrder order) async {
    await _ordersCollection.doc(order.id).update({
      'status': order.status.name,
    });
  }
}

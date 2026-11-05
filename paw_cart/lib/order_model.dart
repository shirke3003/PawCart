import 'order_state_machine.dart';

class PawCartOrder {
  PawCartOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.total,
    required this.machine,
  });

  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String pinCode;
  final double total;
  OrderStateMachine machine;

  OrderStatus get status => machine.status;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'city': city,
        'pinCode': pinCode,
        'total': total,
        'status': status.name,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory PawCartOrder.fromMap(Map<String, dynamic> data) {
    final statusName = data['status'] as String?;
    final status = OrderStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => OrderStatus.placed,
    );

    return PawCartOrder(
      id: data['id'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      pinCode: data['pinCode'] as String? ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      machine: OrderStateMachine(initialStatus: status),
    );
  }
}

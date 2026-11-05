
import 'package:flutter/material.dart';

import 'order_model.dart';
import 'order_state_machine.dart';
import 'order_store.dart';

const Color paymentPink = Color(0xFFFF6F9F);
const Color paymentCream = Color(0xFFFFFAF7);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.total,
  });

  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String pinCode;
  final double total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _processing = false;
  String? _message;
  bool? _paymentSucceeded;
  PawCartOrder? _order;

  Future<void> _processPayment({required bool succeed}) async {
    if (_processing || _order != null) return;

    setState(() {
      _processing = true;
      _message = null;
    });

    // Simulated payment event: no real money is charged.
    final machine = OrderStateMachine();

    final order = PawCartOrder(
      id: 'PAW${DateTime.now().millisecondsSinceEpoch}',
      customerName: widget.customerName,
      phone: widget.phone,
      address: widget.address,
      city: widget.city,
      pinCode: widget.pinCode,
      total: widget.total,
      machine: machine,
    );

    final event = succeed
        ? OrderEvent.paymentSuccess
        : OrderEvent.paymentFailure;

    final accepted = machine.apply(event);

    String message;
    var paymentSucceeded = succeed && accepted;
    PawCartOrder? savedOrder = accepted ? order : null;

    if (!accepted) {
      message = 'The order transition was rejected.';
    } else {
      try {
        await OrderStore.instance.add(order);
        message = succeed
            ? 'Payment successful! Your order is saved. 💗'
            : 'Payment failed. No money was charged in this demo.';
      } catch (error) {
        savedOrder = null;
        paymentSucceeded = false;
        message = 'We could not save this order. Check your internet connection and Firestore rules, then try again. Details: $error';
      }
    }

    if (!mounted) return;
    setState(() {
      _processing = false;
      _paymentSucceeded = paymentSucceeded;
      _order = savedOrder;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?.status;

    return Scaffold(
      backgroundColor: paymentCream,
      appBar: AppBar(
        title: const Text('Payment 💳'),
        backgroundColor: paymentCream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                const Text('🛍️', style: TextStyle(fontSize: 58)),
                const SizedBox(height: 12),
                const Text(
                  'One last little step!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a demo payment screen. '
                  'Choose an outcome to test PawCart’s order workflow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8E7D85)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Amount to pay',
                  style: TextStyle(color: Color(0xFF8E7D85)),
                ),
                Text(
                  '₹${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: paymentPink,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          if (_message == null) ...[
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _processing
                    ? null
                    : () => _processPayment(succeed: true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Simulate successful payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: paymentPink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _processing
                  ? null
                  : () => _processPayment(succeed: false),
              icon: const Icon(Icons.error_outline),
              label: const Text('Simulate payment failure'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Icon(
                    _paymentSucceeded == true
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 48,
                    color: _paymentSucceeded == true
                        ? Colors.green
                        : paymentPink,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_order != null) ...[
                    const SizedBox(height: 12),
                    SelectableText('Order ID: ${_order!.id}'),
                    const SizedBox(height: 6),
                    Text(
                      'Current state: ${OrderStateMachine.label(status!)}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: paymentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Back to PawCart'),
            ),
          ],
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'payment_screen.dart';

const Color pawPink = Color(0xFFFF6F9F);
const Color pawCream = Color(0xFFFFFAF7);
const Color pawInk = Color(0xFF382B32);
const Color pawMuted = Color(0xFF8E7D85);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
  });

  final double subtotal;
  final double deliveryFee;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinController = TextEditingController();

  double get total => widget.subtotal + widget.deliveryFee;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void continueToPayment() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          customerName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          pinCode: _pinController.text.trim(),
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pawCream,
      appBar: AppBar(
        title: const Text('Checkout 💌'),
        backgroundColor: pawCream,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Where should we send the goodies?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: pawInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your delivery details below.',
              style: TextStyle(color: pawMuted),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline,
              validator: requiredField,
            ),
            _field(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            _field(
              controller: _addressController,
              label: 'House, street and area',
              icon: Icons.location_on_outlined,
              validator: requiredField,
            ),
            _field(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city_outlined,
              validator: requiredField,
            ),
            _field(
              controller: _pinController,
              label: 'PIN code',
              icon: Icons.markunread_mailbox_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                  return 'Enter a valid 6-digit PIN code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _priceRow('Subtotal', widget.subtotal),
                  const SizedBox(height: 10),
                  _priceRow('Delivery', widget.deliveryFee),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: pawPink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: continueToPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: pawPink,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Continue to payment 💗',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: pawPink),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('₹${amount.toStringAsFixed(0)}'),
      ],
    );
  }
}

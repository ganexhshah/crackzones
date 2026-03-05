import 'package:flutter/material.dart';
import '../models/shop_models.dart';

class DeliveryScreen extends StatelessWidget {
  final ShopOrder order;

  const DeliveryScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isCode = order.product.deliveryMode == DeliveryMode.code;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: isCode ? _codeDelivery(context) : _topupDelivery(),
          ),
        ],
      ),
    );
  }

  Widget _codeDelivery(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code Delivered',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Code: ABCD-EFGH-IJKL'),
        const Text('PIN: 1234'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Code copied')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Code'),
        ),
        const SizedBox(height: 10),
        const Text(
          'How to redeem',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const Text('1. Open official redeem page.'),
        const Text('2. Enter code and PIN.'),
        const Text('3. Confirm to apply value.'),
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _topupDelivery() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topup Successful',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('Timestamp: $now'),
        Text('Reference: REF-${now.millisecondsSinceEpoch}'),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import 'delivery_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final ShopOrder order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.paidConfirmed,
      OrderStatus.processing,
      OrderStatus.completed,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: ${order.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('Time: ${order.createdAt}'),
                Text('Amount: Rs ${order.total}'),
                const SizedBox(height: 8),
                ...order.inputs.entries.map(
                  (e) => Text('${e.key}: ${_mask(e.value)}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final status = entry.value;
            final done = idx <= 2; // mock progress
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : Colors.grey,
                    ),
                    if (idx < steps.length - 1)
                      Container(width: 2, height: 24, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(orderStatusLabel(status)),
                ),
              ],
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryScreen(order: order),
                  ),
                );
              },
              child: const Text('Open Delivery Details'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support team will contact you soon'),
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Support'),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  String _mask(String value) {
    if (value.length <= 4) return value;
    return '${value.substring(0, 2)}****${value.substring(value.length - 2)}';
  }
}

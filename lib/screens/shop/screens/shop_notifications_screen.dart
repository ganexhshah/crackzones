import 'package:flutter/material.dart';

class ShopNotificationsScreen extends StatelessWidget {
  const ShopNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Payment received for Order ORD-101',
      'Order ORD-101 completed',
      'Refund update for ORD-074',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(items[i]),
        ),
      ),
    );
  }
}

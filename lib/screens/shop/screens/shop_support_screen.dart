import 'package:flutter/material.dart';

class ShopSupportScreen extends StatelessWidget {
  const ShopSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('- How to find Player ID?'),
          const Text('- How to redeem gift card?'),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            leading: const Icon(Icons.chat),
            title: const Text('Live Chat / WhatsApp'),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            leading: const Icon(Icons.confirmation_num_outlined),
            title: const Text('Create Ticket + Upload Screenshot'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

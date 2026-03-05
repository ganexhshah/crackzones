import 'package:flutter/material.dart';

class ShopWalletScreen extends StatelessWidget {
  const ShopWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance: Rs 0',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text('Wallet history is shown here.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: null,
            child: Text('Add Balance (Coming Soon)'),
          ),
        ],
      ),
    );
  }
}

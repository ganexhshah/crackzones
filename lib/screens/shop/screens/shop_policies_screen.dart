import 'package:flutter/material.dart';

class ShopPoliciesScreen extends StatelessWidget {
  const ShopPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final policies = [
      'Refund Policy',
      'Delivery Time Policy',
      'Privacy Policy',
      'Terms of Service',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: ListView.builder(
        itemCount: policies.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(policies[i]),
          subtitle: const Text('Tap to view details'),
          onTap: () {},
        ),
      ),
    );
  }
}

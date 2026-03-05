import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final ShopProduct product;
  final ProductPack pack;
  final Map<String, String> inputs;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.pack,
    required this.inputs,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _payment = 'eSewa';
  bool _manualProofAttached = false;

  static const _payments = ['eSewa', 'Khalti', 'IME Pay', 'Bank'];

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fee = 0;
    final total = widget.pack.price + fee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Product: ${widget.product.name}'),
                Text('Package: ${widget.pack.label}'),
                Text('Price: Rs ${widget.pack.price}'),
                Text('Fee: Rs $fee'),
                const Divider(),
                Text(
                  'Total: Rs $total',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entered Details',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...widget.inputs.entries.map(
                  (e) => Text('${e.key}: ${_maskValue(e.key, e.value)}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _couponController,
            decoration: const InputDecoration(
              labelText: 'Apply Coupon',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _payment,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
            ),
            items: _payments
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _payment = v ?? 'eSewa'),
          ),
          if (_payment == 'Bank') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _manualProofAttached = true),
              icon: const Icon(Icons.upload_file),
              label: Text(
                _manualProofAttached
                    ? 'Payment screenshot attached'
                    : 'Upload payment screenshot',
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_payment == 'Bank' && !_manualProofAttached) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload payment screenshot first'),
                    ),
                  );
                  return;
                }
                final order = ShopOrder(
                  orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
                  createdAt: DateTime.now(),
                  product: widget.product,
                  pack: widget.pack,
                  inputs: widget.inputs,
                  fee: fee,
                  total: total,
                  paymentMethod: _payment,
                  status: OrderStatus.pending,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(order: order),
                  ),
                );
              },
              child: const Text('Confirm Order'),
            ),
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

  String _maskValue(String key, String value) {
    final lower = key.toLowerCase();
    if (lower.contains('email') && value.contains('@')) {
      final i = value.indexOf('@');
      if (i <= 2) return value;
      return '${value.substring(0, 2)}***${value.substring(i)}';
    }
    if (lower.contains('id') || lower.contains('uid')) {
      if (value.length <= 4) return value;
      return '${value.substring(0, 2)}****${value.substring(value.length - 2)}';
    }
    return value;
  }
}

import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ShopProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductPack? _selectedPack;
  final Map<ProductInputType, TextEditingController> _controllers = {};
  final Map<ProductInputType, String> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedPack = widget.product.packs.isNotEmpty
        ? widget.product.packs.first
        : null;
    for (final field in widget.product.inputFields) {
      _controllers[field.type] = TextEditingController();
      if (field.options != null && field.options!.isNotEmpty) {
        _selectedOptions[field.type] = field.options!.first;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(p.imageAsset, height: 170, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(
            p.description,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Rules', style: TextStyle(fontWeight: FontWeight.w800)),
          ...p.rules.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('- $r'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Price Packs',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.packs
                .map(
                  (pack) => ChoiceChip(
                    label: Text('${pack.label} - Rs ${pack.price}'),
                    selected: _selectedPack?.id == pack.id,
                    onSelected: (_) => setState(() => _selectedPack = pack),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Required Information',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...p.inputFields.map(_buildField),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: const Text(
              'Please check your Game ID / Email carefully. Wrong information cannot be refunded.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedPack == null ? null : _confirmAndContinue,
              child: const Text('Buy Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(ProductInputField field) {
    if (field.options != null && field.options!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedOptions[field.type],
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: field.options!
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => _selectedOptions[field.type] = v ?? '',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controllers[field.type],
        keyboardType: field.keyboardType,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _confirmAndContinue() async {
    final missing = <String>[];
    final inputs = <String, String>{};
    for (final field in widget.product.inputFields) {
      if (field.options != null && field.options!.isNotEmpty) {
        final value = _selectedOptions[field.type] ?? '';
        if (value.trim().isEmpty) {
          missing.add(field.label);
        } else {
          inputs[field.label] = value;
        }
      } else {
        final value = _controllers[field.type]?.text.trim() ?? '';
        if (value.isEmpty) {
          missing.add(field.label);
        } else {
          inputs[field.label] = value;
        }
      }
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fill required fields: ${missing.join(', ')}')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Double-check details'),
        content: const Text('Confirm your Game ID / Email before payment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          product: widget.product,
          pack: _selectedPack!,
          inputs: inputs,
        ),
      ),
    );
  }
}

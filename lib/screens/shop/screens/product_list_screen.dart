import 'package:flutter/material.dart';
import '../data/shop_catalog.dart';
import '../models/shop_models.dart';
import '../widgets/shop_service_box.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final ShopCategory category;
  final String? initialQuery;

  const ProductListScreen({
    super.key,
    required this.category,
    this.initialQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late TextEditingController _searchController;
  String _query = '';
  int _maxPrice = 10000000;
  DeliveryType? _deliveryType;
  String _sort = 'popularity';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var products = ShopCatalog.byCategory(widget.category).where((p) {
      final searchOk =
          _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
      final priceOk = p.minPrice <= _maxPrice;
      final deliveryOk =
          _deliveryType == null || p.deliveryType == _deliveryType;
      return searchOk && priceOk && deliveryOk;
    }).toList();

    if (_sort == 'price_low') {
      products.sort((a, b) => a.minPrice.compareTo(b.minPrice));
    } else if (_sort == 'price_high') {
      products.sort((a, b) => b.minPrice.compareTo(a.minPrice));
    } else {
      products.sort((a, b) => b.popularity.compareTo(a.popularity));
    }

    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel(widget.category))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: 'popularity',
                      child: Text('Popularity'),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low-High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High-Low'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? 'popularity'),
                ),
                const SizedBox(width: 12),
                DropdownButton<DeliveryType?>(
                  value: _deliveryType,
                  items: [
                    const DropdownMenuItem<DeliveryType?>(
                      value: null,
                      child: Text('All Delivery'),
                    ),
                    ...DeliveryType.values.map(
                      (e) => DropdownMenuItem<DeliveryType?>(
                        value: e,
                        child: Text(deliveryTypeLabel(e)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _deliveryType = v),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Price: Rs $_maxPrice'),
                      Slider(
                        value: _maxPrice.toDouble(),
                        min: 100000,
                        max: 10000000,
                        divisions: 20,
                        onChanged: (v) => setState(() => _maxPrice = v.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final product = products[i];
                      return ShopServiceBox(
                        title: product.name,
                        badge: product.badge,
                        priceCoins: product.minPrice,
                        accentColor: Colors.amber,
                        imageAsset: product.imageAsset,
                        showPrice: true,
                        onBuy: () => _openDetail(product),
                        onTap: () => _openDetail(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(ShopProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }
}

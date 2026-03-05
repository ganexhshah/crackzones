import 'package:flutter/material.dart';
import '../data/shop_catalog.dart';
import '../models/shop_models.dart';
import '../widgets/shop_service_box.dart';

class StoreHomeView extends StatelessWidget {
  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final void Function(ShopCategory category) onOpenCategory;
  final void Function(ShopProduct product) onOpenProduct;

  const StoreHomeView({
    super.key,
    required this.search,
    required this.searchController,
    required this.onSearch,
    required this.onOpenCategory,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final featured = ShopCatalog.featured().where((p) {
      if (search.trim().isEmpty) return true;
      return p.name.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Search products',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        _categoryCards(),
        const SizedBox(height: 10),
        _banners(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Featured / Popular',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => onOpenCategory(ShopCategory.gameTopups),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: featured.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (_, i) {
            final product = featured[i];
            return ShopServiceBox(
              title: product.name,
              badge: product.badge,
              imageAsset: product.imageAsset,
              accentColor: Colors.amber,
              priceCoins: product.minPrice,
              showPrice: false,
              onBuy: () => onOpenProduct(product),
              onTap: () => onOpenProduct(product),
            );
          },
        ),
      ],
    );
  }

  Widget _categoryCards() {
    final items = [
      (
        ShopCategory.gameTopups,
        'Game Topups\n(UC / Diamonds)',
        Icons.sports_esports,
      ),
      (
        ShopCategory.giftCards,
        'Gift Cards\n(Netflix / Prime / Google Play / App Store)',
        Icons.card_giftcard,
      ),
      (
        ShopCategory.subscriptions,
        'Subscriptions\n(Canva / ChatGPT)',
        Icons.workspace_premium,
      ),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (category, title, icon) = items[i];
          return SizedBox(
            width: 220,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpenCategory(category),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.yellow[100],
                        child: Icon(icon, color: Colors.yellow[800]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _banners() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _OfferBanner(text: 'Offer: Free Fire Topups up to 10% OFF'),
          SizedBox(width: 8),
          _OfferBanner(text: 'Gift Cards instant delivery available'),
          SizedBox(width: 8),
          _OfferBanner(text: 'Canva + ChatGPT official subscriptions'),
        ],
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  final String text;

  const _OfferBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.amber.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

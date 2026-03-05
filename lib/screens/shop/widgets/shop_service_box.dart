import 'package:flutter/material.dart';

class ShopServiceBox extends StatelessWidget {
  final String title;
  final String? badge;
  final int? priceCoins;
  final Color accentColor;
  final String? imageAsset;
  final bool soldOut;
  final bool showPrice;
  final VoidCallback onBuy;
  final VoidCallback? onTap;

  const ShopServiceBox({
    super.key,
    required this.title,
    this.badge,
    this.priceCoins,
    required this.accentColor,
    this.imageAsset,
    this.soldOut = false,
    this.showPrice = true,
    required this.onBuy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageArea(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (showPrice && priceCoins != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$priceCoins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 82,
      width: double.infinity,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: imageAsset != null
                ? Image.asset(
                    imageAsset!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.videogame_asset,
                      color: accentColor,
                      size: 36,
                    ),
                  ),
          ),
          if (badge != null && badge!.trim().isNotEmpty)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: soldOut ? Colors.grey[700] : Colors.red[600],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 6,
            top: 6,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                onTap: onBuy,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.add_shopping_cart_outlined,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

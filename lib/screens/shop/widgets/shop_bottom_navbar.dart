import 'package:flutter/material.dart';

class ShopBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const ShopBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        return Container(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 16,
                vertical: isCompact ? 8 : 12,
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    context,
                    Icons.storefront_outlined,
                    Icons.storefront,
                    'Home',
                    0,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    isCompact ? 'Orders' : 'My Orders',
                    1,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.shopping_cart_outlined,
                    Icons.shopping_cart,
                    'Cart',
                    2,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.person_outline,
                    Icons.person,
                    isCompact ? 'Account' : 'My Account',
                    3,
                    isCompact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    bool isCompact,
  ) {
    final isActive = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? Colors.yellow[700] : Colors.grey[600],
                  size: isCompact ? 24 : 26,
                ),
                SizedBox(height: isCompact ? 2 : 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11,
                        color: isActive ? Colors.yellow[700] : Colors.grey[600],
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

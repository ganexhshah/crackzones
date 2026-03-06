import 'package:flutter/material.dart';
import '../screens/navigation/app_shell_screen.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final bool managedByParent;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.managedByParent = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        return Container(
          decoration: BoxDecoration(color: Colors.grey[50]),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 16,
                vertical: isCompact ? 8 : 12,
              ),
              child: Row(
                children: [
                  _buildNavItem(context, Icons.home, 'Home', 0, isCompact),
                  _buildNavItem(
                    context,
                    Icons.emoji_events_outlined,
                    isCompact ? 'Tourneys' : 'Tournaments',
                    1,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.sports_kabaddi_outlined,
                    isCompact ? 'Custom' : 'Custom Match',
                    2,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    3,
                    isCompact,
                  ),
                  _buildNavItem(
                    context,
                    Icons.more_horiz,
                    'More',
                    4,
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

  void _handleTap(BuildContext context, int index) {
    if (managedByParent) {
      onTap?.call(index);
      return;
    }

    if (index == currentIndex) {
      onTap?.call(index);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AppShellScreen(initialIndex: index)),
      (route) => false,
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isCompact,
  ) {
    final isActive = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context, index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
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


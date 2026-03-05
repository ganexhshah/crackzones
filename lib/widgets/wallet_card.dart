import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class WalletCard extends StatelessWidget {
  final VoidCallback? onAddMoney;
  final VoidCallback? onWithdraw;
  final double? winningAmount;

  const WalletCard({
    super.key,
    this.onAddMoney,
    this.onWithdraw,
    this.winningAmount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final balance = userProvider.walletBalance;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow[100]!, Colors.yellow[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.yellow[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.diamond,
                    color: Colors.yellow[700],
                    size: isCompact ? 18 : 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Diamonds',
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      color: Colors.yellow[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.yellow[50]!, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.diamond,
                                    color: Colors.yellow[700],
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Diamond Value',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[700],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.diamond,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '=',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '₹1',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Each diamond equals one rupee',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.yellow[50],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Got it!',
                                    style: TextStyle(
                                      color: Colors.yellow[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.yellow[600]!,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.info,
                        color: Colors.yellow[700],
                        size: isCompact ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.diamond,
                    color: Colors.grey[900],
                    size: isCompact ? 24 : 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isCompact ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
              if (winningAmount != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: isCompact ? 14 : 15,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Winning Amount: Rs ${winningAmount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Add or withdraw funds instantly',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 300) {
                    return Column(
                      children: [
                        _buildButton('Add Diamond', true, isCompact),
                        const SizedBox(height: 10),
                        _buildButton('Withdraw', false, isCompact),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _buildButton('Add Diamond', true, isCompact),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton('Withdraw', false, isCompact),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String text, bool isPrimary, bool isCompact) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onAddMoney,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow[700],
          padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diamond,
              color: Colors.white,
              size: isCompact ? 14 : 16,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ],
        ),
      );
    }
    return OutlinedButton(
      onPressed: onWithdraw,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
        side: BorderSide(color: Colors.yellow[700]!, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.yellow[700],
          fontWeight: FontWeight.w600,
          fontSize: isCompact ? 13 : 14,
        ),
      ),
    );
  }
}

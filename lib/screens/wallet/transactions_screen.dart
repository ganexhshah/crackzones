import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WalletProvider>(context, listen: false).loadTransactions();
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions(
    List<dynamic> transactions,
  ) {
    if (_selectedFilter == 'all') {
      return transactions.cast<Map<String, dynamic>>();
    }

    return transactions
        .where((tx) {
          final type = tx['type']?.toString() ?? '';
          switch (_selectedFilter) {
            case 'deposit':
              return type == 'deposit';
            case 'withdrawal':
              return type == 'withdrawal';
            case 'wins':
              return type == 'tournament_win' || type == 'custom_match_win';
            case 'entry':
              return type == 'tournament_entry' ||
                  type == 'custom_match_entry_fee';
            default:
              return true;
          }
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<WalletProvider>(
                    context,
                    listen: false,
                  ).loadTransactions();
                },
                child: Consumer<WalletProvider>(
                  builder: (context, walletProvider, _) {
                    if (walletProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredTransactions = _getFilteredTransactions(
                      walletProvider.transactions,
                    );

                    if (filteredTransactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                          filteredTransactions[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'All Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Deposits', 'deposit'),
            const SizedBox(width: 8),
            _buildFilterChip('Withdrawals', 'withdrawal'),
            const SizedBox(width: 8),
            _buildFilterChip('Wins', 'wins'),
            const SizedBox(width: 8),
            _buildFilterChip('Entry Fees', 'entry'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Your transaction history will appear here'
                : 'No $_selectedFilter transactions yet',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final status = transaction['status'] ?? 'pending';
    final method = transaction['method'] ?? '';
    final createdAt = DateTime.parse(transaction['createdAt']);
    final timeAgo = _getTimeAgo(createdAt);
    final referenceNote = transaction['reference']?.toString();

    // Determine transaction display properties
    String title;
    String subtitle;
    IconData icon;
    Color color;
    bool isCredit;

    if (type == 'deposit') {
      if (status == 'rejected') {
        title = 'Payment Rejected';
        subtitle = referenceNote ?? 'Tap to view reason';
        icon = Icons.cancel_outlined;
        color = Colors.red;
      } else if (status == 'pending') {
        title = 'Deposit Pending';
        subtitle = 'Verification Pending';
        icon = Icons.account_balance;
        color = Colors.orange;
      } else {
        title = 'Money Added';
        subtitle = method;
        icon = Icons.account_balance;
        color = Colors.green;
      }
      isCredit = true;
    } else if (type == 'withdrawal') {
      title = 'Withdrawal';
      subtitle = status == 'pending' ? 'Processing' : method;
      icon = Icons.arrow_upward;
      color = Colors.red;
      isCredit = false;
    } else if (type == 'tournament_entry') {
      title = 'Entry Fee';
      subtitle = method;
      icon = Icons.sports_esports;
      color = Colors.red;
      isCredit = false;
    } else if (type == 'tournament_win') {
      title = 'Match Win';
      subtitle = method;
      icon = Icons.emoji_events;
      color = Colors.green;
      isCredit = true;
    } else if (type == 'custom_match_entry_fee') {
      title = 'Custom Match Entry Fee';
      subtitle = referenceNote ?? method;
      icon = Icons.sports_martial_arts_outlined;
      color = Colors.red;
      isCredit = false;
    } else if (type == 'custom_match_refund') {
      title = 'Custom Match Refund';
      subtitle = referenceNote ?? 'Match cancelled refund';
      icon = Icons.replay_circle_filled_outlined;
      color = Colors.green;
      isCredit = true;
    } else if (type == 'custom_match_win') {
      title = 'Custom Match Winnings';
      subtitle = referenceNote ?? 'Match win prize';
      icon = Icons.emoji_events_outlined;
      color = Colors.green;
      isCredit = true;
    } else if (type == 'gift_sent' || type == 'gift_sent_withdrawable') {
      title = 'Gift Sent';
      subtitle = referenceNote ?? 'Gift sent to user';
      icon = Icons.redeem_outlined;
      color = Colors.deepOrange;
      isCredit = false;
    } else if (type == 'gift_received') {
      title = 'Gift Received';
      subtitle = referenceNote ?? 'Gift received from user';
      icon = Icons.card_giftcard_outlined;
      color = Colors.green;
      isCredit = true;
    } else if (type == 'reward_coin_withdrawal') {
      title = 'Coins Withdrawn';
      subtitle = referenceNote ?? 'Coins converted to wallet balance';
      icon = Icons.swap_horiz;
      color = Colors.teal;
      isCredit = true;
    } else {
      title = type;
      subtitle = method;
      icon = Icons.receipt;
      color = Colors.grey;
      isCredit = amount >= 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'} Rs ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'completed'
                    ? Colors.green[50]
                    : status == 'pending'
                    ? Colors.orange[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: status == 'completed'
                      ? Colors.green[700]
                      : status == 'pending'
                      ? Colors.orange[700]
                      : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

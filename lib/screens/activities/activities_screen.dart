import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/custom_navbar.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final int _currentIndex = 3;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletProvider>().loadTransactions();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<WalletProvider>().loadTransactions();
  }

  void _openActivityDetails(Map tx) {
    final ui = _mapTx(tx);
    final amount = ((tx['amount'] ?? 0) as num).toDouble();
    final type = (tx['type'] ?? '').toString();
    final status = (tx['status'] ?? '').toString();
    final method = (tx['method'] ?? '').toString();
    final createdAt = (tx['createdAt'] ?? '').toString();
    final isCredit = type == 'deposit' || type == 'tournament_win';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ui.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(ui.icon, color: ui.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ui.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _detailRow(
                  'Amount',
                  '${isCredit ? '+' : '-'}Rs ${amount.toStringAsFixed(0)}',
                ),
                _detailRow('Status', status.isEmpty ? '-' : status),
                _detailRow('Type', type.isEmpty ? '-' : type),
                _detailRow('Method', method.isEmpty ? '-' : method),
                _detailRow('Time', createdAt.isEmpty ? '-' : createdAt),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        const options = ['all', 'pending', 'completed', 'rejected'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final active = _filter == option;
              return ListTile(
                leading: Icon(
                  active ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: active ? Colors.yellow[700] : Colors.grey[500],
                ),
                title: Text(option[0].toUpperCase() + option.substring(1)),
                onTap: () {
                  setState(() => _filter = option);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  ({String title, String subtitle, IconData icon, Color color}) _mapTx(Map tx) {
    final type = (tx['type'] ?? '').toString();
    final status = (tx['status'] ?? '').toString();
    final method = (tx['method'] ?? '').toString();

    if (type == 'deposit') {
      if (status == 'rejected') {
        return (
          title: 'Payment Rejected',
          subtitle: 'Tap wallet to see reject reason',
          icon: Icons.cancel_outlined,
          color: Colors.red,
        );
      }
      if (status == 'pending') {
        return (
          title: 'Deposit Pending',
          subtitle: 'Verification pending',
          icon: Icons.upload_file_outlined,
          color: Colors.orange,
        );
      }
      return (
        title: 'Money Added',
        subtitle: method.isEmpty ? 'Deposit completed' : method,
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green,
      );
    }

    if (type == 'withdrawal') {
      return (
        title: status == 'pending'
            ? 'Withdrawal Pending'
            : status == 'rejected'
            ? 'Withdrawal Rejected'
            : 'Withdrawal Completed',
        subtitle: method.isEmpty ? 'Withdrawal request' : method,
        icon: Icons.payments_outlined,
        color: status == 'rejected'
            ? Colors.red
            : status == 'pending'
            ? Colors.orange
            : Colors.blue,
      );
    }

    if (type == 'tournament_win') {
      return (
        title: 'Tournament Win',
        subtitle: 'Winning credited',
        icon: Icons.emoji_events_outlined,
        color: Colors.green,
      );
    }

    if (type == 'tournament_entry') {
      return (
        title: 'Tournament Entry',
        subtitle: 'Entry fee deducted',
        icon: Icons.sports_esports_outlined,
        color: Colors.red,
      );
    }

    return (
      title: type.isEmpty ? 'Activity' : type,
      subtitle: method,
      icon: Icons.history,
      color: Colors.grey,
    );
  }

  String _timeLabel(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activities',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _todayLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openFilterSheet,
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: Colors.grey[800],
                    ),
                    tooltip: 'Filter',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  final all = wallet.transactions
                      .whereType<Map>()
                      .where(
                        (tx) =>
                            _filter == 'all' ||
                            (tx['status'] ?? '').toString() == _filter,
                      )
                      .toList();

                  if (wallet.isLoading && all.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: all.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 120),
                              Icon(
                                Icons.local_activity_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'No activities found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: all.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final tx = all[index];
                              final ui = _mapTx(tx);
                              final amount = ((tx['amount'] ?? 0) as num)
                                  .toDouble();
                              final type = (tx['type'] ?? '').toString();
                              final isCredit =
                                  type == 'deposit' || type == 'tournament_win';

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _openActivityDetails(tx),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: ui.color.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(ui.icon, color: ui.color),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ui.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey[900],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ui.subtitle,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isCredit ? '+' : '-'}Rs ${amount.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isCredit
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _timeLabel(
                                                (tx['createdAt'] ?? '')
                                                    .toString(),
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavbar(currentIndex: _currentIndex),
    );
  }
}

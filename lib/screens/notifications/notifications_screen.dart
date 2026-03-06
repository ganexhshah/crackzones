import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../custom_match/custom_match_home_screen.dart';
import '../tournament/tournament_screen.dart';
import '../wallet/wallet_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _notifications = [];
  DateTime? _clearedBefore;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications_cleared_before');
    _clearedBefore = raw != null ? DateTime.tryParse(raw) : null;
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getNotifications(take: 80),
        ApiService.getTournamentAlerts(),
        ApiService.getTransactions(),
        ApiService.getSystemSettings(),
        ApiService.getCustomMatchAlerts(),
        ApiService.getBroadcastNotifications(),
      ]);
      if (!mounted) return;

      final storedRes = results[0];
      final alertsRes = results[1];
      final txRes = results[2];
      final settingsRes = results[3];
      final customAlertsRes = results[4];
      final broadcastRes = results[5];

      final stored = (storedRes['notifications'] is List)
          ? List<Map<String, dynamic>>.from(
              (storedRes['notifications'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final alerts = (alertsRes['alerts'] is List)
          ? List<Map<String, dynamic>>.from(
              (alertsRes['alerts'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final transactions = (txRes['transactions'] is List)
          ? List<Map<String, dynamic>>.from(
              (txRes['transactions'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final settings = (settingsRes['settings'] is Map)
          ? Map<String, dynamic>.from(settingsRes['settings'] as Map)
          : <String, dynamic>{};
      final customAlerts = (customAlertsRes['alerts'] is List)
          ? List<Map<String, dynamic>>.from(
              (customAlertsRes['alerts'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];
      final broadcasts = (broadcastRes['notifications'] is List)
          ? List<Map<String, dynamic>>.from(
              (broadcastRes['notifications'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final all = <Map<String, dynamic>>[
        ..._buildStoredNotifications(stored),
        ..._buildTournamentNotifications(alerts),
        ..._buildCustomMatchNotifications(customAlerts),
        ..._buildBroadcastNotifications(broadcasts),
        ..._buildWalletNotifications(transactions),
        ..._buildSystemNotifications(settings),
      ];

      all.sort((a, b) {
        final at = a['sortAt'] as DateTime;
        final bt = b['sortAt'] as DateTime;
        return bt.compareTo(at);
      });

      final filteredByClear = _clearedBefore == null
          ? all
          : all.where((n) {
              final dt = n['sortAt'] as DateTime;
              return dt.isAfter(_clearedBefore!);
            }).toList();

      setState(() {
        _notifications = filteredByClear;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load notifications')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _buildTournamentNotifications(
    List<Map<String, dynamic>> alerts,
  ) {
    final next = <Map<String, dynamic>>[];
    for (final alert in alerts) {
      final title = (alert['tournamentTitle'] ?? 'Tournament').toString();
      final roomId = (alert['roomId'] ?? '').toString();
      final roomPass = (alert['roomPass'] ?? '').toString();
      final winner = (alert['winner'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(alert['winner'])
          : null;
      final updatedAt = _parseDate(
        (alert['updatedAt'] ?? alert['createdAt'] ?? '').toString(),
      );

      if (roomId.isNotEmpty && roomPass.isNotEmpty) {
        next.add({
          'id': 'tournament-room-$title-$roomId',
          'title': '$title room started',
          'message': 'Room ID: $roomId | Password: $roomPass',
          'time': _formatAlertTime(updatedAt),
          'sortAt': updatedAt,
          'read': false,
          'icon': Icons.meeting_room_outlined,
          'color': Colors.orange,
          'category': 'tournament',
        });
      }

      if (winner != null) {
        final winnerName = (winner['name'] ?? 'Unknown').toString();
        next.add({
          'id': 'tournament-result-$title-$winnerName',
          'title': '$title result declared',
          'message': 'Winner: $winnerName',
          'time': _formatAlertTime(updatedAt),
          'sortAt': updatedAt,
          'read': false,
          'icon': Icons.emoji_events_outlined,
          'color': Colors.green,
          'category': 'tournament',
        });
      }
    }
    return next;
  }

  List<Map<String, dynamic>> _buildWalletNotifications(
    List<Map<String, dynamic>> transactions,
  ) {
    final next = <Map<String, dynamic>>[];
    for (final tx in transactions) {
      final built = _mapTransactionToNotification(tx);
      if (built != null) next.add(built);
    }
    return next;
  }

  List<Map<String, dynamic>> _buildStoredNotifications(
    List<Map<String, dynamic>> rows,
  ) {
    final next = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = (row['id'] ?? '').toString();
      final title = (row['title'] ?? 'Notification').toString();
      final message = (row['message'] ?? '').toString();
      final category = (row['category'] ?? 'SYSTEM').toString().toUpperCase();
      final imageUrl = (row['imageUrl'] ?? '').toString();
      final isRead = row['isRead'] == true;
      final createdAt = _parseDate((row['createdAt'] ?? '').toString());

      IconData icon = Icons.notifications_outlined;
      Color color = Colors.blue;
      if (category == 'WALLET') {
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.teal;
      } else if (category == 'CUSTOM') {
        icon = Icons.sports_esports_outlined;
        color = Colors.indigo;
      } else if (category == 'TOURNAMENT') {
        icon = Icons.emoji_events_outlined;
        color = Colors.orange;
      } else if (category == 'BROADCAST') {
        icon = Icons.campaign_outlined;
        color = Colors.purple;
      }

      next.add({
        'id': id,
        'title': title,
        'message': message,
        'time': _formatAlertTime(createdAt),
        'sortAt': createdAt,
        'read': isRead,
        'icon': icon,
        'color': color,
        'category': category.toLowerCase(),
        'type': (row['metadata'] is Map)
            ? (((row['metadata'] as Map)['type'] ?? '').toString())
            : '',
        'metadata': row['metadata'] is Map
            ? Map<String, dynamic>.from(row['metadata'] as Map)
            : <String, dynamic>{},
        'persisted': true,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
      });
    }
    return next;
  }

  List<Map<String, dynamic>> _buildCustomMatchNotifications(
    List<Map<String, dynamic>> alerts,
  ) {
    final next = <Map<String, dynamic>>[];
    for (final a in alerts) {
      final id = (a['id'] ?? '').toString();
      final type = (a['type'] ?? '').toString();
      final title = (a['title'] ?? 'Custom Match Update').toString();
      final message = (a['message'] ?? '').toString();
      final createdAt = _parseDate((a['createdAt'] ?? '').toString());

      IconData icon = Icons.sports_esports_outlined;
      Color color = Colors.deepPurple;

      if (type == 'custom_join_request_pending') {
        icon = Icons.person_add_alt_1_outlined;
        color = Colors.orange;
      } else if (type == 'custom_join_request_accepted') {
        icon = Icons.check_circle_outline;
        color = Colors.green;
      } else if (type == 'custom_join_request_rejected') {
        icon = Icons.cancel_outlined;
        color = Colors.redAccent;
      } else if (type == 'custom_room_ready') {
        icon = Icons.meeting_room_outlined;
        color = Colors.indigo;
      } else if (type == 'custom_result_pending') {
        icon = Icons.hourglass_top_outlined;
        color = Colors.amber;
      } else if (type == 'custom_result_approved') {
        icon = Icons.verified_outlined;
        color = Colors.teal;
      } else if (type == 'custom_result_rejected') {
        icon = Icons.report_problem_outlined;
        color = Colors.red;
      } else if (type == 'custom_match_closed') {
        icon = Icons.lock_outline;
        color = Colors.blueGrey;
      }

      next.add({
        'id': id.isNotEmpty
            ? id
            : 'custom-$type-${createdAt.millisecondsSinceEpoch}',
        'title': title,
        'message': message,
        'time': _formatAlertTime(createdAt),
        'sortAt': createdAt,
        'read': false,
        'icon': icon,
        'color': color,
        'category': 'custom',
        'metadata': a,
        'type': type,
        'persisted': false,
      });
    }
    return next;
  }

  List<Map<String, dynamic>> _buildBroadcastNotifications(
    List<Map<String, dynamic>> rows,
  ) {
    final next = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = (row['id'] ?? '').toString();
      final title = (row['title'] ?? 'Announcement').toString();
      final message = (row['message'] ?? '').toString();
      final type = (row['type'] ?? 'NORMAL').toString().toUpperCase();
      final bannerImageUrl = (row['bannerImageUrl'] ?? '').toString();
      final createdAt = _parseDate((row['createdAt'] ?? '').toString());

      next.add({
        'id': id.isNotEmpty
            ? id
            : 'broadcast-${createdAt.millisecondsSinceEpoch}',
        'title': title,
        'message': message,
        'time': _formatAlertTime(createdAt),
        'sortAt': createdAt,
        'read': false,
        'icon': type == 'BANNER'
            ? Icons.campaign_outlined
            : Icons.notifications_active_outlined,
        'color': type == 'BANNER' ? Colors.purple : Colors.blue,
        'category': 'broadcast',
        'metadata': row,
        'type': type.toLowerCase(),
        'persisted': false,
        if (bannerImageUrl.isNotEmpty) 'image': bannerImageUrl,
      });
    }
    return next;
  }

  Map<String, dynamic>? _mapTransactionToNotification(Map<String, dynamic> tx) {
    final id = (tx['id'] ?? '').toString();
    final type = (tx['type'] ?? '').toString().trim().toLowerCase();
    final status = (tx['status'] ?? '').toString().trim().toLowerCase();
    final method = (tx['method'] ?? '').toString().trim();
    final reference = (tx['reference'] ?? '').toString().trim();
    final amount = (tx['amount'] is num)
        ? (tx['amount'] as num).toDouble()
        : 0.0;
    final updatedAt = _parseDate(
      (tx['updatedAt'] ?? tx['createdAt'] ?? '').toString(),
    );
    final amountText = _formatAmount(amount);

    IconData icon = Icons.account_balance_wallet_outlined;
    Color color = Colors.blueGrey;
    String title = 'Wallet update';
    String message = 'Your wallet activity was updated.';
    String category = 'wallet';

    if (type == 'deposit') {
      icon = Icons.south_west_rounded;
      color = Colors.green;
      if (status == 'pending') {
        title = 'Deposit submitted';
        message =
            'Your deposit of Rs $amountText is submitted and under review.';
      } else if (status == 'completed') {
        title = 'Deposit approved';
        message =
            'Rs $amountText has been added to your wallet${method.isNotEmpty ? ' via $method' : ''}.';
      } else if (status == 'rejected') {
        title = 'Deposit rejected';
        message = reference.isNotEmpty
            ? 'Deposit of Rs $amountText was rejected. Reason: $reference'
            : 'Deposit of Rs $amountText was rejected by admin.';
      } else {
        title = 'Deposit update';
        message = 'Deposit of Rs $amountText status: $status';
      }
    } else if (type == 'withdrawal') {
      icon = Icons.north_east_rounded;
      color = Colors.deepOrange;
      if (status == 'pending') {
        title = 'Withdrawal submitted';
        message =
            'Withdrawal request of Rs $amountText is submitted${method.isNotEmpty ? ' via $method' : ''}.';
      } else if (status == 'completed') {
        title = 'Withdrawal approved';
        message = 'Rs $amountText withdrawal completed successfully.';
      } else if (status == 'rejected') {
        title = 'Withdrawal rejected';
        message = reference.isNotEmpty
            ? 'Withdrawal of Rs $amountText was rejected. Reason: $reference'
            : 'Withdrawal of Rs $amountText was rejected by admin.';
      } else {
        title = 'Withdrawal update';
        message = 'Withdrawal of Rs $amountText status: $status';
      }
    } else if (type == 'custom_match_win' ||
        type == 'tournament_win' ||
        type == 'winning') {
      icon = Icons.emoji_events_outlined;
      color = Colors.teal;
      title = 'Winnings credited';
      message = 'You won Rs $amountText and it has been added to your wallet.';
    } else if (type == 'entry_fee' ||
        type == 'tournament_entry' ||
        type == 'custom_match_entry_fee') {
      icon = Icons.sports_esports_outlined;
      color = Colors.indigo;
      title = 'Entry fee deducted';
      message = 'Rs $amountText deducted as match/tournament entry fee.';
    } else if (type == 'admin_credit' || type == 'admin_debit') {
      final isCredit = type == 'admin_credit';
      icon = isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline;
      color = isCredit ? Colors.green : Colors.redAccent;
      title = 'Admin wallet adjustment';
      message = isCredit
          ? 'Admin credited Rs $amountText to your wallet${reference.isNotEmpty ? '. Reason: $reference' : '.'}'
          : 'Admin debited Rs $amountText from your wallet${reference.isNotEmpty ? '. Reason: $reference' : '.'}';
      category = 'admin';
    } else if (type == 'custom_match_refund') {
      icon = Icons.refresh_outlined;
      color = Colors.lightBlue;
      title = 'Refund credited';
      message = 'Custom match refund of Rs $amountText has been credited.';
    } else if (type == 'gift_sent' || type == 'gift_sent_withdrawable') {
      icon = Icons.redeem_outlined;
      color = Colors.deepOrange;
      title = 'Gift sent';
      message = reference.isNotEmpty
          ? reference
          : 'You sent a gift of Rs $amountText.';
    } else if (type == 'gift_received') {
      icon = Icons.card_giftcard_outlined;
      color = Colors.green;
      title = 'Gift received';
      message = reference.isNotEmpty
          ? reference
          : 'You received a gift of Rs $amountText.';
    } else if (type == 'reward_coin_withdrawal') {
      icon = Icons.swap_horiz;
      color = Colors.teal;
      title = 'Coin withdrawal';
      message = reference.isNotEmpty
          ? reference
          : 'Coins were converted and credited to your wallet.';
    } else {
      return null;
    }

    return {
      'id': 'tx-$id-$status',
      'title': title,
      'message': message,
      'time': _formatAlertTime(updatedAt),
      'sortAt': updatedAt,
      'read': false,
      'icon': icon,
      'color': color,
      'category': category,
      'metadata': tx,
      'type': type,
      'persisted': false,
    };
  }

  List<Map<String, dynamic>> _buildSystemNotifications(
    Map<String, dynamic> settings,
  ) {
    final minDeposit = (settings['minDepositAmount'] is num)
        ? (settings['minDepositAmount'] as num).toDouble()
        : 100.0;
    final minWithdrawal = (settings['minWithdrawalAmount'] is num)
        ? (settings['minWithdrawalAmount'] as num).toDouble()
        : 100.0;
    final autoApprove = settings['autoApprovePayments'] == true;

    final now = DateTime.now();
    return [
      {
        'id': 'sys-min-deposit',
        'title': 'Minimum deposit rule',
        'message': 'Minimum deposit amount is Rs ${_formatAmount(minDeposit)}.',
        'time': _formatAlertTime(now),
        'sortAt': now,
        'read': true,
        'icon': Icons.info_outline,
        'color': Colors.blueGrey,
        'category': 'system',
        'persisted': false,
      },
      {
        'id': 'sys-min-withdraw',
        'title': 'Minimum withdrawal rule',
        'message':
            'Minimum withdrawal amount is Rs ${_formatAmount(minWithdrawal)}.',
        'time': _formatAlertTime(now),
        'sortAt': now,
        'read': true,
        'icon': Icons.info_outline,
        'color': Colors.blueGrey,
        'category': 'system',
        'persisted': false,
      },
      {
        'id': 'sys-auto-approve',
        'title': 'Payment approval mode',
        'message': autoApprove
            ? 'Deposits are auto-approved by system settings.'
            : 'Deposits require admin review before approval.',
        'time': _formatAlertTime(now),
        'sortAt': now,
        'read': true,
        'icon': autoApprove
            ? Icons.task_alt_outlined
            : Icons.pending_actions_outlined,
        'color': autoApprove ? Colors.green : Colors.amber,
        'category': 'system',
        'persisted': false,
      },
    ];
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will remove all notifications from this device and delete stored ones from server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final now = DateTime.now();
    await ApiService.markNotificationRead(clearAll: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications_cleared_before',
      now.toIso8601String(),
    );

    setState(() {
      _notifications = [];
      _clearedBefore = now;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All notifications cleared')));
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final category = (item['category'] ?? '').toString().toLowerCase();
    final type = (item['type'] ?? '').toString().toLowerCase();

    if (category.contains('wallet') ||
        category == 'admin' ||
        type.contains('wallet') ||
        type.contains('deposit') ||
        type.contains('withdraw') ||
        type.contains('refund') ||
        type.contains('winning') ||
        type.contains('entry')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const WalletScreen(showBottomNav: false, showBackButton: true),
        ),
      );
      return;
    }

    if (category.contains('tournament') || type.contains('tournament')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TournamentScreen(
            showBottomNav: false,
            showBackButton: true,
          ),
        ),
      );
      return;
    }

    if (category.contains('custom') ||
        type.contains('custom') ||
        type.contains('match')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomMatchHomeScreen(
            showBottomNav: false,
            showBackButton: true,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No linked page for this notification yet')),
    );
  }

  DateTime _parseDate(String input) {
    return DateTime.tryParse(input)?.toLocal() ?? DateTime.now();
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
    return amount.toStringAsFixed(2);
  }

  String _formatAlertTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour ago';
    return '${diff.inDays} day ago';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _showUnreadOnly
        ? _notifications.where((n) => n['read'] == false).toList()
        : _notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: _notifications.isEmpty ? null : _clearAllNotifications,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          TextButton(
            onPressed: () async {
              await ApiService.markNotificationRead(markAll: true);
              setState(() {
                for (final n in _notifications) {
                  n['read'] = true;
                }
              });
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: Colors.yellow[800],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildControls(filtered.length),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildNotificationTile(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.yellow[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Updates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count notification${count == 1 ? '' : 's'} shown',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          FilterChip(
            selected: _showUnreadOnly,
            label: const Text('Unread only'),
            onSelected: (value) {
              setState(() {
                _showUnreadOnly = value;
              });
            },
            selectedColor: Colors.yellow[100],
            checkmarkColor: Colors.orange[800],
            side: BorderSide(color: Colors.grey[300]!),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _showUnreadOnly ? Colors.orange[800] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> item) {
    final Color color = item['color'] as Color;
    final bool isRead = item['read'] as bool;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            item['read'] = true;
          });
          final id = (item['id'] ?? '').toString();
          final persisted = item['persisted'] == true;
          if (persisted && id.isNotEmpty) {
            ApiService.markNotificationRead(notificationId: id);
          }
          _openNotification(item);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.grey[200]! : Colors.yellow[200]!,
            ),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['message'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (item['image'] is String &&
                        (item['image'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item['image'] as String,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      item['time'] as String,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No unread notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You are all caught up. New updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



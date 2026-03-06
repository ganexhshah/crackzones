import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GiftHistoryScreen extends StatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> {
  List<dynamic> _giftHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Sent, Received

  @override
  void initState() {
    super.initState();
    _loadGiftHistory();
  }

  Future<void> _loadGiftHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getGiftHistory();
      if (response['error'] == null && response['history'] != null) {
        setState(() {
          _giftHistory = List<dynamic>.from(response['history'] as List);
          _isLoading = false;
        });
      } else {
        setState(() {
          _giftHistory = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading gift history: $e');
      setState(() {
        _giftHistory = [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredHistory {
    if (_selectedFilter == 'All') {
      return _giftHistory;
    } else if (_selectedFilter == 'Sent') {
      return _giftHistory.where((item) {
        final type = (item['type'] ?? '').toString();
        return type == 'gift_sent' || type == 'gift_sent_withdrawable';
      }).toList();
    } else {
      return _giftHistory
          .where((item) => (item['type'] ?? '').toString() == 'gift_received')
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gift History',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _filterChip('All'),
                const SizedBox(width: 8),
                _filterChip('Sent'),
                const SizedBox(width: 8),
                _filterChip('Received'),
              ],
            ),
          ),

          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No gift history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGiftHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final item = _filteredHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _historyCard(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black87 : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _historyCard(dynamic item) {
    final type = (item['type'] ?? '').toString();
    final isSent = type == 'gift_sent' || type == 'gift_sent_withdrawable';
    final amountValue = item['amount'];
    final amount = amountValue is num
        ? amountValue.abs().toInt()
        : int.tryParse(amountValue?.toString() ?? '0')?.abs() ?? 0;
    final status = (item['status'] ?? 'completed').toString().toUpperCase();
    final reference = (item['reference'] ?? '').toString();
    final userName = _extractUserName(reference, isSent);
    final sentAt = _formatDateTime((item['createdAt'] ?? '').toString());
    final message = (item['message'] ?? '').toString();

    return InkWell(
      onTap: () => _showGiftDetailsDialog(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSent ? Colors.pink[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSent ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                    color: isSent ? Colors.pink[600] : Colors.green[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent
                            ? 'Sent to $userName'
                            : 'Received from $userName',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sentAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSent ? Colors.red[600] : Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'COMPLETED'
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: status == 'COMPLETED'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _extractUserName(String reference, bool isSent) {
    if (isSent && reference.startsWith('Gift to ')) {
      final raw = reference.replaceFirst('Gift to ', '');
      final parts = raw.split(':');
      return parts.first.split('[').first.trim();
    } else if (!isSent && reference.startsWith('Gift from ')) {
      final raw = reference.replaceFirst('Gift from ', '');
      final parts = raw.split(':');
      return parts.first.split('[').first.trim();
    }
    return reference.isNotEmpty
        ? reference.split('[').first.trim()
        : 'Unknown user';
  }

  String _formatDateTime(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        final hh = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        return 'Today at $hh:$min';
      } else if (diff.inDays == 1) {
        final hh = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        return 'Yesterday at $hh:$min';
      } else {
        final mm = dt.month.toString().padLeft(2, '0');
        final dd = dt.day.toString().padLeft(2, '0');
        return '$dd/$mm/${dt.year}';
      }
    } catch (_) {
      return rawDate;
    }
  }

  String _formatFullDateTime(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final sec = dt.second.toString().padLeft(2, '0');
      return '$dd/$mm/${dt.year} at $hh:$min:$sec';
    } catch (_) {
      return rawDate;
    }
  }

  void _showGiftDetailsDialog(dynamic item) {
    final type = (item['type'] ?? '').toString();
    final isSent = type == 'gift_sent' || type == 'gift_sent_withdrawable';
    final amountValue = item['amount'];
    final amount = amountValue is num
        ? amountValue.abs().toInt()
        : int.tryParse(amountValue?.toString() ?? '0')?.abs() ?? 0;
    final status = (item['status'] ?? 'completed').toString();
    final reference = (item['reference'] ?? '').toString();
    final userName = _extractUserName(reference, isSent);
    final message = (item['message'] ?? '').toString();
    final transactionId = (item['id'] ?? item['_id'] ?? 'N/A').toString();
    final createdAt = _formatFullDateTime((item['createdAt'] ?? '').toString());
    final updatedAt = _formatFullDateTime((item['updatedAt'] ?? '').toString());

    // Extract user info from item
    final userAvatar = (item['recipientAvatar'] ?? item['senderAvatar'] ?? '')
        .toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSent
                                  ? [Colors.pink[400]!, Colors.pink[600]!]
                                  : [Colors.green[400]!, Colors.green[600]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSent ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSent ? 'Gift Sent' : 'Gift Received',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == 'completed'
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: status.toLowerCase() == 'completed'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Amount Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.yellow[100]!, Colors.yellow[50]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 32,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$amount',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: isSent
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Details Section
                    _detailRowWithAvatar(
                      label: isSent ? 'Recipient' : 'Sender',
                      userName: userName,
                      userAvatar: userAvatar,
                    ),
                    const Divider(height: 24),
                    _detailRow(
                      icon: Icons.access_time,
                      label: 'Date & Time',
                      value: createdAt,
                    ),
                    const Divider(height: 24),
                    _detailRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transaction ID',
                      value: transactionId,
                      isMonospace: true,
                    ),
                    if (updatedAt != createdAt && updatedAt != 'N/A') ...[
                      const Divider(height: 24),
                      _detailRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: updatedAt,
                      ),
                    ],

                    // Message Section
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRowWithAvatar({
    required String label,
    required String userName,
    required String userAvatar,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
            image: (userAvatar.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(userAvatar),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (userAvatar.isEmpty)
              ? Icon(Icons.person, size: 24, color: Colors.yellow[700])
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



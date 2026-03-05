import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CoinWithdrawScreen extends StatefulWidget {
  const CoinWithdrawScreen({super.key});

  @override
  State<CoinWithdrawScreen> createState() => _CoinWithdrawScreenState();
}

class _CoinWithdrawScreenState extends State<CoinWithdrawScreen> {
  bool _loading = true;
  bool _withdrawing = false;
  int _coins = 0;
  int _diamonds = 0;
  List<dynamic> _history = [];
  final TextEditingController _coinsController = TextEditingController(
    text: '500',
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getRewardsStatus(),
      ApiService.getRewardWithdrawHistory(),
    ]);

    if (!mounted) return;

    final statusRes = results[0];
    final historyRes = results[1];

    if (statusRes['error'] == null) {
      _coins = _asInt(statusRes['coins']);
      _diamonds = _asInt(statusRes['diamonds']);
    }
    if (historyRes['error'] == null && historyRes['history'] is List) {
      _history = List<dynamic>.from(historyRes['history'] as List);
    }

    setState(() => _loading = false);
  }

  Future<void> _withdrawNow() async {
    if (_withdrawing) return;
    final coins = int.tryParse(_coinsController.text.trim()) ?? 0;
    if (coins < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum is 500 coins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (coins > _coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient coins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _withdrawing = true);
    final res = await ApiService.withdrawRewardCoins(coins: coins);
    if (!mounted) return;
    setState(() => _withdrawing = false);

    if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Converted ${res['coinsDeducted']} coins to Rs ${res['rupeesCredited']}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm/${dt.year} $hh:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxRupees = _coins ~/ 500;
    final maxCoins = maxRupees * 500;
    final quick = <int>[
      500,
      1000,
      5000,
      10000,
    ].where((v) => v <= _coins).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Withdraw Coins'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available: $_coins coins | $_diamonds diamonds',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rate: 500 coins = Rs 1',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max now: $maxCoins coins -> Rs $maxRupees',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _coinsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Coins to convert',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (quick.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: quick
                                .map(
                                  (v) => ActionChip(
                                    label: Text('$v'),
                                    onPressed: () =>
                                        _coinsController.text = '$v',
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _withdrawing ? null : _withdrawNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                            ),
                            child: _withdrawing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Convert to Wallet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Withdraw History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_history.isEmpty)
                          Text(
                            'No withdrawals yet',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else
                          ..._history.map((item) {
                            final amount = ((item['amount'] ?? 0) as num)
                                .toDouble();
                            final reference = (item['reference'] ?? '')
                                .toString();
                            final createdAt = _formatDate(
                              (item['createdAt'] ?? '').toString(),
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '+ Rs ${amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          reference,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          createdAt,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

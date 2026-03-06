import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class WalletReportsScreen extends StatefulWidget {
  const WalletReportsScreen({super.key});

  @override
  State<WalletReportsScreen> createState() => _WalletReportsScreenState();
}

class _WalletReportsScreenState extends State<WalletReportsScreen> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final res = await ApiService.getV1WalletReports();
    if (!mounted) return;
    if (res['error'] != null) {
      setState(() {
        _loading = false;
        _error = res['error'].toString();
        _reports = [];
      });
      return;
    }
    final rows = (res['reports'] is List)
        ? List<Map<String, dynamic>>.from(
            (res['reports'] as List).whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
          )
        : <Map<String, dynamic>>[];
    setState(() {
      _loading = false;
      _reports = rows;
    });
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'ACTION_TAKEN') return Colors.green;
    if (s == 'IN_REVIEW') return Colors.orange;
    if (s == 'REJECTED') return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Wallet Reports'),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 130),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red[700])),
            if (!_loading && _error.isEmpty && _reports.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 130),
                child: Center(child: Text('No wallet reports yet')),
              ),
            if (!_loading && _reports.isNotEmpty)
              ..._reports.map((r) {
                final status = (r['status'] ?? 'SUBMITTED').toString();
                final color = _statusColor(status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Transaction ${(r['transactionId'] ?? '').toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Reason: ${(r['reason'] ?? '').toString()}'),
                      if ((r['details'] ?? '').toString().isNotEmpty)
                        Text('Details: ${(r['details'] ?? '').toString()}'),
                      if ((r['adminNote'] ?? '').toString().isNotEmpty)
                        Text(
                          'Admin note: ${(r['adminNote'] ?? '').toString()}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}


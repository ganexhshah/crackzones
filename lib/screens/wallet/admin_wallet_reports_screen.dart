import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminWalletReportsScreen extends StatefulWidget {
  const AdminWalletReportsScreen({super.key});

  @override
  State<AdminWalletReportsScreen> createState() =>
      _AdminWalletReportsScreenState();
}

class _AdminWalletReportsScreenState extends State<AdminWalletReportsScreen> {
  bool _loading = true;
  String _error = '';
  String _statusFilter = 'ALL';
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
    final res = await ApiService.getV1AdminWalletReports(status: _statusFilter);
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

  Future<void> _updateStatus(Map<String, dynamic> report, String status) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Set status: $status'),
        content: TextField(
          controller: noteCtrl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Admin note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await ApiService.reviewV1AdminWalletReport(
      reportId: (report['id'] ?? '').toString(),
      status: status,
      adminNote: noteCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res['error'] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['error'].toString())));
      return;
    }
    await _load();
  }

  Widget _chip(String label) {
    final selected = _statusFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = label);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.yellow[700] : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.yellow[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : Colors.grey[700],
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Admin Wallet Reports'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('ALL'),
                  const SizedBox(width: 8),
                  _chip('SUBMITTED'),
                  const SizedBox(width: 8),
                  _chip('IN_REVIEW'),
                  const SizedBox(width: 8),
                  _chip('ACTION_TAKEN'),
                  const SizedBox(width: 8),
                  _chip('REJECTED'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loading && _error.isNotEmpty)
                    Text(_error, style: TextStyle(color: Colors.red[700])),
                  if (!_loading && _error.isEmpty && _reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: Text('No wallet reports')),
                    ),
                  if (!_loading && _reports.isNotEmpty)
                    ..._reports.map(
                      (r) => Container(
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
                            Text(
                              '${(r['userName'] ?? 'User').toString()} • ${(r['status'] ?? 'SUBMITTED').toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Report ID: ${(r['id'] ?? '').toString()}'),
                            Text(
                              'Transaction: ${(r['transactionId'] ?? '').toString()}',
                            ),
                            Text('Reason: ${(r['reason'] ?? '').toString()}'),
                            if ((r['details'] ?? '').toString().isNotEmpty)
                              Text(
                                'Details: ${(r['details'] ?? '').toString()}',
                              ),
                            if ((r['adminNote'] ?? '').toString().isNotEmpty)
                              Text(
                                'Admin note: ${(r['adminNote'] ?? '').toString()}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _updateStatus(r, 'IN_REVIEW'),
                                  child: const Text('In Review'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      _updateStatus(r, 'ACTION_TAKEN'),
                                  child: const Text('Action Taken'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _updateStatus(r, 'REJECTED'),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


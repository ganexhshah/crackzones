import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class CustomMatchReportsScreen extends StatefulWidget {
  const CustomMatchReportsScreen({super.key});

  @override
  State<CustomMatchReportsScreen> createState() =>
      _CustomMatchReportsScreenState();
}

class _CustomMatchReportsScreenState extends State<CustomMatchReportsScreen> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final res = await ApiService.getV1CustomMatchReports();
    if (!mounted) return;
    if (res['error'] != null) {
      setState(() {
        _loading = false;
        _reports = [];
        _error = res['error'].toString();
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
    final normalized = status.toUpperCase();
    if (normalized == 'ACTION_TAKEN') return Colors.green;
    if (normalized == 'IN_REVIEW') return Colors.orange;
    if (normalized == 'REJECTED') return Colors.red;
    return Colors.blue;
  }

  String _fmtDate(String value) {
    final dt = DateTime.tryParse(value)?.toLocal();
    if (dt == null) return value;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('My Match Reports'),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 140),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red[700])),
            if (!_loading && _error.isEmpty && _reports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Text('No reports yet'),
                ),
              ),
            if (!_loading && _reports.isNotEmpty)
              ..._reports.map((r) {
                final status = (r['status'] ?? 'SUBMITTED').toString();
                final statusColor = _statusColor(status);
                final reportId = (r['id'] ?? '').toString();
                final matchId = (r['matchId'] ?? '').toString();
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
                              (r['gameName'] ?? 'Custom Match').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report ID: ${reportId.length > 8 ? reportId.substring(0, 8) : reportId}',
                      ),
                      Text(
                        'Match ID: ${matchId.length > 10 ? matchId.substring(0, 10) : matchId}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reason: ${(r['reason'] ?? '').toString()}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if ((r['details'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Details: ${(r['details'] ?? '').toString()}',
                          ),
                        ),
                      if ((r['adminNote'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Admin note: ${(r['adminNote'] ?? '').toString()}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _fmtDate((r['createdAt'] ?? '').toString()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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


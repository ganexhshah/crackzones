import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'custom_match_components.dart';
import 'custom_match_details_screen.dart';
import 'custom_match_result_screen.dart';
import 'custom_match_ui_models.dart';

enum _HistoryFilter { all, joined, waitingResult, adminVerified }

class CustomMatchHistoryScreen extends StatefulWidget {
  const CustomMatchHistoryScreen({super.key});

  @override
  State<CustomMatchHistoryScreen> createState() =>
      _CustomMatchHistoryScreenState();
}

class _CustomMatchHistoryScreenState extends State<CustomMatchHistoryScreen> {
  bool _loading = true;
  String _error = '';
  String _currentUserId = '';
  _HistoryFilter _activeFilter = _HistoryFilter.all;
  List<CustomMatchUiModel> _historyMatches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final profileRes = await ApiService.getProfile();
      final user = profileRes['user'] is Map
          ? Map<String, dynamic>.from(profileRes['user'] as Map)
          : <String, dynamic>{};
      final userId = (user['id'] ?? '').toString();

      if (userId.isEmpty) {
        setState(() {
          _currentUserId = '';
          _historyMatches = [];
          _loading = false;
          _error = 'Could not read current user.';
        });
        return;
      }

      _currentUserId = userId;
      // Use v1 matches directly because some deployments do not implement
      // /custom-matches/history and return HTML 404.
      final sourceRes = await ApiService.getV1Matches(limit: 100);
      if (!mounted) return;
      if (sourceRes['error'] != null) {
        setState(() {
          _loading = false;
          _historyMatches = [];
          _error = sourceRes['error'].toString();
        });
        return;
      }

      final rawItems = sourceRes['matches'] is List
          ? List<dynamic>.from(sourceRes['matches'] as List)
          : sourceRes['history'] is List
          ? List<dynamic>.from(sourceRes['history'] as List)
          : sourceRes['data'] is List
          ? List<dynamic>.from(sourceRes['data'] as List)
          : <dynamic>[];

      final rows = rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final parsed = rows.map((raw) {
        final creatorId = (raw['creatorId'] ?? '').toString();
        final role = creatorId == userId ? MatchRole.creator : MatchRole.joiner;
        return matchFromApi(raw: raw, role: role, currentUserId: userId);
      }).toList();

      setState(() {
        _historyMatches = parsed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _historyMatches = [];
        _error = 'Failed to load custom match history.';
      });
    }
  }

  bool _isResultApproved(CustomMatchUiModel m) {
    final status = m.resultSubmissionStatus.toUpperCase();
    if (status == 'APPROVED' || status == 'ACCEPTED' || status == 'VERIFIED') {
      return true;
    }
    if (m.status == MatchStatus.completed &&
        m.verifiedWinnerUserId.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool _isWaitingResult(CustomMatchUiModel m) {
    final status = m.resultSubmissionStatus.toUpperCase();
    final explicitlyPending = status == 'PENDING' || status == 'WAITING';
    final hasSubmissionWaiting =
        m.resultSubmittedForVerification &&
        !_isResultApproved(m) &&
        status != 'REJECTED';
    return explicitlyPending || hasSubmissionWaiting;
  }

  List<CustomMatchUiModel> get _filteredHistory {
    switch (_activeFilter) {
      case _HistoryFilter.all:
        return _historyMatches;
      case _HistoryFilter.joined:
        return _historyMatches
            .where((m) => m.joinerUserId == _currentUserId)
            .toList();
      case _HistoryFilter.waitingResult:
        return _historyMatches.where(_isWaitingResult).toList();
      case _HistoryFilter.adminVerified:
        return _historyMatches.where(_isResultApproved).toList();
    }
  }

  Future<void> _openMatch(CustomMatchUiModel m) async {
    final waitingResult = _isWaitingResult(m);
    final approved = _isResultApproved(m);
    if (waitingResult || approved || m.status == MatchStatus.completed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomMatchResultScreen(match: m)),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomMatchDetailsScreen(match: m)),
    );
  }

  String _actionLabel(CustomMatchUiModel m) {
    if (_isResultApproved(m) || m.status == MatchStatus.completed) {
      return 'View Result';
    }
    if (_isWaitingResult(m)) {
      return 'Open Result';
    }
    return 'Open Details';
  }

  Widget _filterChip({required _HistoryFilter value, required String label}) {
    final selected = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredHistory;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Custom Match History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(value: _HistoryFilter.all, label: 'All'),
                  const SizedBox(width: 8),
                  _filterChip(value: _HistoryFilter.joined, label: 'Joined'),
                  const SizedBox(width: 8),
                  _filterChip(
                    value: _HistoryFilter.waitingResult,
                    label: 'Waiting Result',
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    value: _HistoryFilter.adminVerified,
                    label: 'Admin Verified',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loading && _error.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Text(
                        _error,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!_loading && _error.isEmpty && rows.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.grey[500],
                            size: 42,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matches found in this filter.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loading && rows.isNotEmpty)
                    ...rows.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomMatchCard(
                          match: m,
                          actionLabel: _actionLabel(m),
                          onAction: () => _openMatch(m),
                          onTap: () => _openMatch(m),
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


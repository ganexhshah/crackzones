import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/custom_match_socket_service.dart';
import '../../widgets/custom_navbar.dart';
import '../wallet/add_money_screen.dart';
import 'create_match_screen.dart';
import 'custom_match_chat_screen.dart';
import 'custom_match_details_screen.dart';
import 'custom_match_history_screen.dart';
import 'custom_match_result_screen.dart';
import 'custom_match_ui_models.dart';
import 'custom_match_components.dart';

class CustomMatchHomeScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const CustomMatchHomeScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = false,
  });

  @override
  State<CustomMatchHomeScreen> createState() => _CustomMatchHomeScreenState();
}

class _CustomMatchHomeScreenState extends State<CustomMatchHomeScreen> {
  int _currentIndex = 2;
  MatchRole _activeRole = MatchRole.joiner;
  final PageController _pageController = PageController();
  String? _joiningMatchId;
  bool _refreshing = false;
  String _currentUserId = '';
  StreamSubscription<MatchSocketEvent>? _socketSub;

  bool _loading = true;
  List<CustomMatchUiModel> _joinerMatches = [];
  List<CustomMatchUiModel> _creatorMatches = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    await CustomMatchSocketService.instance.connect();
    _socketSub ??= CustomMatchSocketService.instance.events.listen(
      _handleSocketEvent,
    );
  }

  void _handleSocketEvent(MatchSocketEvent event) {
    if (!mounted) return;
    if (event.type == 'socket.connected' ||
        event.type == 'socket.reconnected') {
      _refresh(silent: true);
      return;
    }
    if (event.type == 'wallet.updated') return;
    if (event.matchId == null || event.matchId!.isEmpty) return;
    _applySocketPatch(event);
    _refreshSingleMatch(event.matchId!);
  }

  void _applySocketPatch(MatchSocketEvent event) {
    final matchId = event.matchId;
    if (matchId == null || matchId.isEmpty) return;
    final rawStatus = (event.payload['status'] ?? '').toString();
    if (rawStatus.isEmpty) return;
    final status = parseBackendStatus(rawStatus);

    CustomMatchUiModel patch(CustomMatchUiModel row) {
      if (row.id != matchId) return row;
      return row.copyWith(
        status: status,
        chatEnabled: status == MatchStatus.confirmed,
        subtitle: status == MatchStatus.confirmed
            ? 'Match confirmed. Room and chat enabled.'
            : row.subtitle,
        roomId: event.type == 'match.room_ready'
            ? (event.payload['roomIdMasked'] ?? row.roomId).toString()
            : row.roomId,
        roomPassword: event.type == 'match.room_ready'
            ? (event.payload['roomPasswordMasked'] ?? row.roomPassword)
                  .toString()
            : row.roomPassword,
      );
    }

    setState(() {
      _joinerMatches = _joinerMatches.map(patch).toList();
      _creatorMatches = _creatorMatches.map(patch).toList();
    });
  }

  Future<void> _refreshSingleMatch(String matchId) async {
    if (_currentUserId.isEmpty) return;
    final res = await ApiService.getV1MatchDetails(matchId);
    if (!mounted || res['error'] != null) return;
    final raw = res['match'] is Map
        ? Map<String, dynamic>.from(res['match'] as Map)
        : <String, dynamic>{};
    if (raw.isEmpty) return;

    final creatorId = (raw['creatorId'] ?? '').toString();
    if (creatorId.isEmpty) return;
    final isCreator = creatorId == _currentUserId;
    final updated = matchFromApi(
      raw: raw,
      role: isCreator ? MatchRole.creator : MatchRole.joiner,
      currentUserId: _currentUserId,
    );

    setState(() {
      if (isCreator) {
        _creatorMatches = _upsertMatch(_creatorMatches, updated);
        _joinerMatches = _joinerMatches.where((m) => m.id != matchId).toList();
      } else {
        _joinerMatches = _upsertMatch(_joinerMatches, updated);
        _creatorMatches = _creatorMatches
            .where((m) => m.id != matchId)
            .toList();
      }
    });
  }

  List<CustomMatchUiModel> _upsertMatch(
    List<CustomMatchUiModel> list,
    CustomMatchUiModel row,
  ) {
    final copy = List<CustomMatchUiModel>.from(list);
    final idx = copy.indexWhere((m) => m.id == row.id);
    
    // Don't show matches where both players have submitted
    if (row.resultClaims.length >= 2) {
      if (idx >= 0) {
        copy.removeAt(idx);
      }
      return copy;
    }
    
    if (idx >= 0) {
      copy[idx] = row;
      return copy;
    }
    copy.insert(0, row);
    return copy;
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      if (!silent && mounted) {
        setState(() => _loading = true);
      }

      final profileRes = await ApiService.getProfile();
      final user = profileRes['user'] is Map
          ? Map<String, dynamic>.from(profileRes['user'] as Map)
          : <String, dynamic>{};
      final userId = (user['id'] ?? '').toString();
      if (userId.isNotEmpty) {
        _currentUserId = userId;
        await _initSocket();
      }

      final matchesRes = await ApiService.getV1Matches(limit: 100);
      if (!mounted) return;

      if (userId.isEmpty || matchesRes['error'] != null) {
        if (!silent) {
          setState(() {
            _loading = false;
            _joinerMatches = [];
            _creatorMatches = [];
          });
        } else {
          setState(() {
            _loading = false;
          });
        }
        if (matchesRes['error'] != null) {
          _toast(matchesRes['error'].toString());
        }
        return;
      }

      final rows = (matchesRes['matches'] is List)
          ? List<Map<String, dynamic>>.from(
              (matchesRes['matches'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final creator = rows
          .where((m) => (m['creatorId'] ?? '').toString() == userId)
          .map(
            (m) => matchFromApi(
              raw: m,
              role: MatchRole.creator,
              currentUserId: userId,
            ),
          )
          .where((m) => m.resultClaims.length < 2) // Hide if both players submitted
          .toList();

      final joiner = rows
          .where((m) {
            final creatorId = (m['creatorId'] ?? '').toString();
            final joinerId = (m['joinerId'] ?? '').toString();
            final status = (m['status'] ?? '').toString().toUpperCase();
            final isOpenForJoining = status == 'OPEN' && creatorId != userId;
            final isMyJoinedMatch = joinerId == userId;
            return isOpenForJoining || isMyJoinedMatch;
          })
          .map(
            (m) => matchFromApi(
              raw: m,
              role: MatchRole.joiner,
              currentUserId: userId,
            ),
          )
          .where((m) => m.resultClaims.length < 2) // Hide if both players submitted
          .toList();

      setState(() {
        _joinerMatches = joiner;
        _creatorMatches = creator;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String _actionLabel(CustomMatchUiModel m) {
    if (_joiningMatchId == m.id) return 'Joining...';
    final resultPending =
        m.resultSubmittedForVerification &&
        m.resultSubmissionStatus.toUpperCase() != 'REJECTED' &&
        m.status == MatchStatus.confirmed;

    if (m.isCreator) {
      switch (m.status) {
        case MatchStatus.open:
          return 'Waiting';
        case MatchStatus.requested:
          return 'Review Request';
        case MatchStatus.confirmed:
          return resultPending ? 'Open Result' : 'Manage Room';
        case MatchStatus.completed:
          return 'View Result';
        case MatchStatus.rejected:
          return 'Rejected';
        case MatchStatus.expired:
          return 'Expired';
        case MatchStatus.cancelled:
          return 'Cancelled';
      }
    }

    switch (m.status) {
      case MatchStatus.open:
        return 'JOIN';
      case MatchStatus.requested:
        return 'REQUESTED';
      case MatchStatus.confirmed:
        return resultPending ? 'Open Result' : 'ACCEPTED';
      case MatchStatus.completed:
        return 'RESULT';
      case MatchStatus.rejected:
      case MatchStatus.expired:
      case MatchStatus.cancelled:
        return 'JOIN';
    }
  }

  Future<void> _onAction(CustomMatchUiModel m) async {
    final resultPending =
        m.resultSubmittedForVerification &&
        m.resultSubmissionStatus.toUpperCase() != 'REJECTED' &&
        m.status == MatchStatus.confirmed;

    if (resultPending || m.status == MatchStatus.completed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomMatchResultScreen(match: m)),
      );
      await _refresh(silent: true);
      return;
    }

    if (m.isCreator) {
      await _openDetails(m);
      return;
    }

    if (m.status == MatchStatus.open ||
        m.status == MatchStatus.rejected ||
        m.status == MatchStatus.expired ||
        m.status == MatchStatus.cancelled) {
      await _joinWithChecks(m);
      return;
    }

    await _openDetails(m);
  }

  Future<void> _onCardTap(CustomMatchUiModel m) async {
    final resultPending =
        m.resultSubmittedForVerification &&
        m.resultSubmissionStatus.toUpperCase() != 'REJECTED' &&
        m.status == MatchStatus.confirmed;
    if (resultPending || m.status == MatchStatus.completed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomMatchResultScreen(match: m)),
      );
      await _refresh(silent: true);
      return;
    }
    await _openDetails(m);
  }

  Future<void> _joinWithChecks(CustomMatchUiModel m) async {
    final confirm = await _showJoinRulesDialog(m);
    if (confirm != true || !mounted) return;

    setState(() => _joiningMatchId = m.id);
    final balanceRes = await ApiService.getWalletBalance();
    if (!mounted) return;
    final balance = ((balanceRes['balance'] ?? 0) as num).toDouble();
    if (balance < m.entryFee) {
      await _showInsufficientBalanceDialog(m.entryFee, balance);
      if (mounted) setState(() => _joiningMatchId = null);
      return;
    }

    final res = await ApiService.joinV1Match(m.id);
    if (!mounted) return;
    setState(() => _joiningMatchId = null);
    if (res['error'] != null) {
      _toast(res['error'].toString());
      return;
    }
    final expiresAtRaw = (res['expiresAt'] ?? '').toString().trim();
    final expiresAt = expiresAtRaw.isEmpty
        ? null
        : DateTime.tryParse(expiresAtRaw)?.toLocal();
    setState(() {
      _joinerMatches = _joinerMatches
          .map(
            (row) => row.id == m.id
                ? row.copyWith(
                    status: MatchStatus.requested,
                    subtitle: 'Waiting for approval',
                    requestExpiryAt: expiresAt,
                  )
                : row,
          )
          .toList();
    });
    _toast('Join request sent');
    await _refresh(silent: true);
  }

  Future<bool?> _showJoinRulesDialog(CustomMatchUiModel m) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Join'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entry Fee: Rs ${m.entryFee.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Room Type: ${m.roomType == 'LONE_WOLF' ? 'Lone Wolf' : 'Custom Room'}',
              ),
              Text('Mode: ${m.matchType}'),
              Text('Rounds: ${m.rounds}'),
              Text('Default Coin: ${m.defaultCoin}'),
              const SizedBox(height: 8),
              Text('Throwable Limit: ${m.throwableLimit ? 'ON' : 'OFF'}'),
              Text('Character Skill: ${m.characterSkill ? 'ON' : 'OFF'}'),
              Text('Headshot Mode: ${m.headshotOnly ? 'ON' : 'OFF'}'),
              Text('Gun Attributes: ${m.gunAttributes ? 'ON' : 'OFF'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.yellow[700]),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInsufficientBalanceDialog(double need, double have) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.yellow[800],
          size: 34,
        ),
        title: const Text('Insufficient Balance'),
        content: Text(
          'Required: Rs ${need.toStringAsFixed(2)}\nAvailable: Rs ${have.toStringAsFixed(2)}\n\nPlease add money to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.yellow[700]),
            icon: const Icon(Icons.add_card, color: Colors.black87),
            label: const Text(
              'Add Money',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(CustomMatchUiModel m) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CustomMatchDetailsScreen(match: m)),
    );
    if (changed == true) {
      await _refresh(silent: true);
    }
  }

  Future<void> _openCreateMatch() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
    );
    if (created == true) {
      await _refresh();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomMatchHistoryScreen()),
    );
  }

  Future<void> _cancelMatch(CustomMatchUiModel m) async {
    if (!m.isCreator || m.status != MatchStatus.open) {
      _toast('Only open creator matches can be cancelled');
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Match'),
        content: const Text(
          'Do you want to cancel this match? Locked entry will be refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Cancel Match'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    final res = await ApiService.cancelV1Match(m.id);
    if (!mounted) return;
    if (res['error'] != null) {
      _toast(res['error'].toString());
      return;
    }
    _toast('Match cancelled');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      floatingActionButton: _activeRole == MatchRole.creator
          ? FloatingActionButton.extended(
              onPressed: _openCreateMatch,
              backgroundColor: Colors.yellow[700],
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: const Text('Create Match'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _horizontalRoleSelector(),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _activeRole = index == 0
                        ? MatchRole.joiner
                        : MatchRole.creator;
                  });
                },
                children: [
                  _buildMatchList(_joinerMatches),
                  _buildMatchList(_creatorMatches),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            )
          : null,
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Match',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _openHistory,
            icon: const Icon(Icons.history, size: 18),
            label: const Text(
              'History',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Chat',
            onPressed: () {
              final confirmed = [
                ..._creatorMatches,
                ..._joinerMatches,
              ].where((m) => m.status == MatchStatus.confirmed).toList();
              if (confirmed.isEmpty) {
                _toast('No confirmed match available for chat');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomMatchChatScreen(
                    isEnabled: true,
                    matchId: confirmed.first.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
    );
  }

  Widget _horizontalRoleSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: _roleButton(
                selected: _activeRole == MatchRole.joiner,
                icon: Icons.person_add_outlined,
                label: 'Join Matches',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: _roleButton(
                selected: _activeRole == MatchRole.creator,
                icon: Icons.add_circle_outline,
                label: 'My Matches',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleButton({
    required bool selected,
    required IconData icon,
    required String label,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? Colors.yellow[700] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.yellow[700]! : Colors.grey[300]!,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.black87 : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black87 : Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(List<CustomMatchUiModel> matches) {
    // Filter out matches where both players have submitted results
    final activeMatches = matches.where((m) {
      // If match is completed, don't show in active list
      if (m.status == MatchStatus.completed) return false;
      
      // Check if both players have submitted results
      final creatorSubmitted = m.resultClaims.any((claim) => claim.submittedBy == m.creatorUserId);
      final joinerSubmitted = m.resultClaims.any((claim) => claim.submittedBy == m.joinerUserId);
      final bothSubmitted = creatorSubmitted && joinerSubmitted;
      
      // Hide if both submitted (waiting for admin)
      if (bothSubmitted) return false;
      
      return true;
    }).toList();
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_loading) ...List.generate(3, (_) => _skeletonCard()),
          if (!_loading && activeMatches.isEmpty) _emptyState(),
          if (!_loading && activeMatches.isNotEmpty)
            ...activeMatches.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CustomMatchCard(
                  match: m,
                  actionLabel: _actionLabel(m),
                  onAction: _joiningMatchId == m.id ? null : () => _onAction(m),
                  onDelete: (m.isCreator && m.status == MatchStatus.open)
                      ? () => _cancelMatch(m)
                      : null,
                  onTap: () => _onCardTap(m),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
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
          Container(height: 14, width: 180, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 10),
          Container(
            height: 44,
            width: double.infinity,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No matches found',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Pull to refresh or create a new match.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}


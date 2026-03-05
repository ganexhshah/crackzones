import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/custom_match_socket_service.dart';
import '../profile/view_profile_screen.dart';
import '../wallet/add_money_screen.dart';
import 'custom_match_chat_screen.dart';
import 'custom_match_components.dart';
import 'custom_match_result_screen.dart';
import 'custom_match_ui_models.dart';
import 'match_rules_screen.dart';

class CustomMatchDetailsScreen extends StatefulWidget {
  final CustomMatchUiModel match;

  const CustomMatchDetailsScreen({super.key, required this.match});

  @override
  State<CustomMatchDetailsScreen> createState() => _CustomMatchDetailsScreenState();
}

class _CustomMatchDetailsScreenState extends State<CustomMatchDetailsScreen> {
  late CustomMatchUiModel _match;
  final _roomIdCtrl = TextEditingController();
  final _roomPassCtrl = TextEditingController();
  bool _busy = false;
  bool _roomSubmitting = false;
  bool _loadingDetails = false;
  bool _reloadAfterCurrent = false;
  String? _requestActionLoading;
  String _currentUserId = '';
  StreamSubscription<MatchSocketEvent>? _socketSub;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _currentUserId = _match.isCreator ? _match.creatorUserId : _match.joinerUserId;
    // Don't mask room details - show them in full
    _roomIdCtrl.text = _match.roomId;
    _roomPassCtrl.text = _match.roomPassword;
    _loadDetails();
    _initSocket();
  }

  @override
  void dispose() {
    CustomMatchSocketService.instance.unsubscribeMatch(_match.id);
    _socketSub?.cancel();
    _roomIdCtrl.dispose();
    _roomPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    await CustomMatchSocketService.instance.connect();
    CustomMatchSocketService.instance.subscribeMatch(_match.id);
    _socketSub ??=
        CustomMatchSocketService.instance.events.listen((event) {
          if (!mounted) return;
          if (event.type == 'socket.connected' || event.type == 'socket.reconnected') {
            CustomMatchSocketService.instance.subscribeMatch(_match.id);
            _loadDetails(silent: true);
            return;
          }
          if (event.matchId == _match.id) {
            _applySocketPatch(event);
            _loadDetails(silent: true);
          }
        });
  }

  void _applySocketPatch(MatchSocketEvent event) {
    final rawStatus = (event.payload['status'] ?? '').toString();
    final patchedStatus =
        rawStatus.isEmpty ? _match.status : parseBackendStatus(rawStatus);

    setState(() {
      _match = _match.copyWith(
        status: patchedStatus,
        chatEnabled: patchedStatus == MatchStatus.confirmed,
        subtitle: patchedStatus == MatchStatus.confirmed
            ? 'Match confirmed. Chat enabled.'
            : _match.subtitle,
      );
    });
  }

  void _showToast(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _openResultScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomMatchResultScreen(match: _match),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _loadDetails({bool silent = false}) async {
    if (_loadingDetails) {
      _reloadAfterCurrent = true;
      return;
    }
    _loadingDetails = true;
    try {
      final res = await ApiService.getV1MatchDetails(_match.id);
      if (!mounted) return;
      if (res['error'] != null) {
        if (!silent) {
          _showToast(res['error'].toString());
        }
        return;
      }
      final raw = res['match'] is Map
          ? Map<String, dynamic>.from(res['match'] as Map)
          : <String, dynamic>{};
      if (raw.isEmpty) return;

      if (_currentUserId.isEmpty) {
        final profileRes = await ApiService.getProfile();
        if (!mounted) return;
        _currentUserId = (profileRes['user'] is Map)
            ? ((profileRes['user'] as Map)['id'] ?? '').toString()
            : '';
      }
      if (_currentUserId.isEmpty) return;

      setState(() {
        _match = matchFromApi(raw: raw, role: _match.role, currentUserId: _currentUserId);
      });
    } finally {
      _loadingDetails = false;
      if (_reloadAfterCurrent && mounted) {
        _reloadAfterCurrent = false;
        _loadDetails(silent: true);
      }
    }
  }

  Future<void> _requestJoin() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Show rules screen first
    final agreedToRules = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchRulesScreen(actionType: 'join'),
      ),
    );
    
    if (agreedToRules != true || !mounted) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    final balanceRes = await ApiService.getWalletBalance();
    if (!mounted) return;
    final balance = ((balanceRes['balance'] ?? 0) as num).toDouble();
    if (balance < _match.entryFee) {
      await _showInsufficientBalanceDialog(_match.entryFee, balance);
      if (mounted) setState(() => _busy = false);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final res = await ApiService.joinV1Match(_match.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['error'] != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Request sent successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _loadDetails();
    if (!mounted) return;
    navigator.pop(true);
  }

  Future<bool?> _showJoinRulesDialog() {
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
                'Entry Fee: Rs ${_match.entryFee.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text('Room Type: ${_match.roomType == 'LONE_WOLF' ? 'Lone Wolf' : 'Custom Room'}'),
              Text('Mode: ${_match.matchType}'),
              Text('Rounds: ${_match.rounds}'),
              Text('Default Coin: ${_match.defaultCoin}'),
              const SizedBox(height: 8),
              Text('Throwable Limit: ${_match.throwableLimit ? 'ON' : 'OFF'}'),
              Text('Character Skill: ${_match.characterSkill ? 'ON' : 'OFF'}'),
              Text('Headshot Mode: ${_match.headshotOnly ? 'ON' : 'OFF'}'),
              Text('Gun Attributes: ${_match.gunAttributes ? 'ON' : 'OFF'}'),
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
            child: const Text('Continue', style: TextStyle(color: Colors.black87)),
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
            label: const Text('Add Money', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptJoinRequest() async {
    if (_busy) return;
    
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _requestActionLoading = 'accept';
    });

    final acceptRes = await ApiService.acceptV1MatchRequest(_match.id);
    
    if (!mounted) return;

    if (acceptRes['error'] != null) {
      setState(() {
        _busy = false;
        _requestActionLoading = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(acceptRes['error'].toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Match request accepted successfully!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // Update match status
    setState(() {
      _match = _match.copyWith(
        status: MatchStatus.confirmed,
        subtitle: 'Match confirmed. Chat enabled.',
        chatEnabled: true,
      );
    });

    if (!mounted) return;
    setState(() {
      _busy = false;
      _requestActionLoading = null;
    });
    await _loadDetails(silent: true);
  }

  Future<void> _rejectJoinRequest() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _requestActionLoading = 'reject';
    });
    final res = await ApiService.rejectV1MatchRequest(_match.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _requestActionLoading = null;
    });
    if (res['error'] != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Join request rejected and refunded'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _loadDetails(silent: true);
    if (!mounted) return;
    navigator.pop(true);
  }

  Future<void> _submitRoom() async {
    final roomId = _roomIdCtrl.text.trim();
    final roomPass = _roomPassCtrl.text.trim();
    if (roomId.isEmpty || roomPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Room ID and Password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_roomSubmitting) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _roomSubmitting = true);
    final res = await ApiService.submitV1MatchRoom(
      matchId: _match.id,
      roomId: roomId,
      roomPassword: roomPass,
    );
    if (!mounted) return;
    setState(() => _roomSubmitting = false);
    
    if (res['error'] != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Room details submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _match = _match.copyWith(
        roomId: roomId,
        roomPassword: roomPass,
      );
    });
    
    await _loadDetails(silent: true);
  }

  Future<void> _cancelMatch() async {
    if (_busy || !_match.isCreator || _match.status != MatchStatus.open) return;

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
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final res = await ApiService.cancelV1Match(_match.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res['error'] != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Match cancelled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _loadDetails();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final resultPending =
        _match.status == MatchStatus.confirmed &&
        _match.resultSubmittedForVerification &&
        _match.resultSubmissionStatus.toUpperCase() != 'REJECTED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Match Details'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _loadDetails,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_match.isCreator && _match.status == MatchStatus.open)
            IconButton(
              tooltip: 'Cancel Match',
              onPressed: _busy ? null : _cancelMatch,
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[700]),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomMatchCard(
              match: _match,
              actionLabel: _match.isCreator ? 'Manage' : _joinerButtonLabel(),
              onAction: _match.isCreator ? null : _joinerAction(),
              onDelete: (_match.isCreator && _match.status == MatchStatus.open)
                  ? _cancelMatch
                  : null,
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _setupSummaryCard(),
            const SizedBox(height: 12),
            if (_match.status == MatchStatus.open && _match.isCreator)
              _creatorOpenState(),
            if (_match.status == MatchStatus.requested && _match.isCreator)
              _creatorRequestedState(),
            if (_match.status == MatchStatus.confirmed && !resultPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green[700]),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Match Confirmed! Submit room details below.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (resultPending)
              _stateBanner(
                'Result already submitted. Waiting for admin verification.',
                Colors.orange,
              ),
            if (_match.chatEnabled)
              MatchActionButton(
                label: 'Open Match Chat',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomMatchChatScreen(
                        isEnabled: true,
                        matchId: _match.id,
                      ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            
            // Room Details Section
            if (_match.status == MatchStatus.confirmed) ...[
              if (_match.isCreator)
                _roomInputCard()
              else
                _roomDisplayCard(),
              const SizedBox(height: 10),
            ],
            
            if (_match.status == MatchStatus.confirmed && !resultPending)
              MatchActionButton(
                label: 'Stop Match & Submit Result',
                outlined: true,
                onTap: _openResultScreen,
              ),
            if (_match.status == MatchStatus.completed || resultPending)
              MatchActionButton(
                label: 'Open Result',
                onTap: _openResultScreen,
              ),
            if (_match.status == MatchStatus.requested &&
                !_match.isCreator &&
                _match.requestExpiryAt != null) ...[
              const SizedBox(height: 10),
              TimerChip(expiresAt: _match.requestExpiryAt!),
            ],
            if (_match.status == MatchStatus.rejected)
              _stateBanner('Request rejected. Refund completed.', Colors.red),
            if (_match.status == MatchStatus.expired)
              _stateBanner('Request expired. Refund completed.', Colors.grey),
            if (_match.status == MatchStatus.cancelled)
              _stateBanner('Match cancelled by creator.', Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _creatorOpenState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange[700]),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Waiting for players to request join',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupSummaryCard() {
    final characterText = !_match.characterSkill
        ? 'Off'
        : _match.allSkillsAllowed
        ? 'All Active'
        : '${_match.selectedSkills.length} Selected';

    return Container(
      width: double.infinity,
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
              Icon(Icons.tune_rounded, color: Colors.orange[800]),
              const SizedBox(width: 8),
              const Text(
                'Room Settings',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _settingTile(
                  icon: Icons.stadium_rounded,
                  title: 'Room Type',
                  value: _match.roomType == 'LONE_WOLF'
                      ? 'Lone Wolf'
                      : 'Custom Room',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _settingTile(
                  icon: Icons.sports_esports_rounded,
                  title: 'Mode',
                  value: _match.matchType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _settingTile(
                  icon: Icons.flag_circle_rounded,
                  title: 'Rounds',
                  value: '${_match.rounds}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _settingTile(
                  icon: Icons.monetization_on_rounded,
                  title: 'Default Coin',
                  value: '${_match.defaultCoin}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ruleChip(
                icon: Icons.whatshot_rounded,
                label: 'Throwable',
                enabled: _match.throwableLimit,
              ),
              _ruleChip(
                icon: Icons.auto_fix_high_rounded,
                label: 'Character Skill',
                enabled: _match.characterSkill,
                trailing: characterText,
              ),
              _ruleChip(
                icon: Icons.gps_fixed_rounded,
                label: 'Headshot Mode',
                enabled: _match.headshotOnly,
              ),
              _ruleChip(
                icon: Icons.tune_rounded,
                label: 'Gun Attributes',
                enabled: _match.gunAttributes,
              ),
            ],
          ),
          if (_match.characterSkill &&
              !_match.allSkillsAllowed &&
              _match.selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Allowed Characters',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _match.selectedSkills
                  .map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.orange[100]!),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.orange[900]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleChip({
    required IconData icon,
    required String label,
    required bool enabled,
    String? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: enabled ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: enabled ? Colors.green[800] : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            trailing == null ? '$label ${enabled ? 'ON' : 'OFF'}' : '$label: $trailing',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.green[900] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorRequestedState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Request Received',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.orange[900],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _match.joinerUserId.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewProfileScreen(userId: _match.joinerUserId),
                          ),
                        ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.yellow[100],
                        backgroundImage: _match.joinerAvatar.startsWith('http')
                            ? NetworkImage(_match.joinerAvatar)
                            : null,
                        child: _match.joinerAvatar.startsWith('http')
                            ? null
                            : Text(
                                _initialsFromName(_match.joinerName),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _match.joinerName.isEmpty
                                    ? 'Pending joiner request'
                                    : _match.joinerName,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (_match.joinerUserId.isNotEmpty)
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                          ],
                        ),
                      ),
                      if (_match.requestExpiryAt != null)
                        TimerChip(expiresAt: _match.requestExpiryAt!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MatchActionButton(
                      label: _requestActionLoading == 'reject'
                          ? 'Please wait...'
                          : 'Reject',
                      outlined: true,
                      onTap: _busy ? null : _rejectJoinRequest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MatchActionButton(
                      label: _requestActionLoading == 'accept'
                          ? 'Please wait...'
                          : 'Accept',
                      onTap: _busy ? null : _acceptJoinRequest,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stateBanner(String text, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        border: Border.all(color: color[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: color[900]),
      ),
    );
  }

  String _joinerButtonLabel() {
    final resultPending =
        _match.status == MatchStatus.confirmed &&
        _match.resultSubmittedForVerification &&
        _match.resultSubmissionStatus.toUpperCase() != 'REJECTED';
    if (_busy && _match.status == MatchStatus.open) {
      return 'Joining...';
    }
    switch (_match.status) {
      case MatchStatus.open:
        return 'JOIN';
      case MatchStatus.requested:
        return 'REQUESTED';
      case MatchStatus.confirmed:
        return resultPending ? 'OPEN RESULT' : 'ACCEPTED';
      case MatchStatus.completed:
        return 'OPEN RESULT';
      case MatchStatus.rejected:
      case MatchStatus.expired:
      case MatchStatus.cancelled:
        return 'JOIN';
    }
  }

  VoidCallback? _joinerAction() {
    final resultPending =
        _match.status == MatchStatus.confirmed &&
        _match.resultSubmittedForVerification &&
        _match.resultSubmissionStatus.toUpperCase() != 'REJECTED';

    switch (_match.status) {
      case MatchStatus.open:
      case MatchStatus.rejected:
      case MatchStatus.expired:
      case MatchStatus.cancelled:
        return _busy ? null : _requestJoin;
      case MatchStatus.completed:
        return _openResultScreen;
      case MatchStatus.requested:
        return null;
      case MatchStatus.confirmed:
        if (resultPending) {
          return _openResultScreen;
        }
        return null;
    }
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'J';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _roomInputCard() {
    final hasRoomDetails = _match.roomId.isNotEmpty && _match.roomPassword.isNotEmpty;
    
    // If room details already submitted, show them in read-only mode
    if (hasRoomDetails) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
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
                Icon(Icons.meeting_room, size: 20, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Room Credentials (Submitted)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _roomDetailRow('Room ID', _match.roomId, Icons.tag),
            const SizedBox(height: 10),
            _roomDetailRow('Password', _match.roomPassword, Icons.lock),
          ],
        ),
      );
    }
    
    // Show input form if not yet submitted
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
              Icon(Icons.meeting_room, size: 20, color: Colors.yellow[700]),
              const SizedBox(width: 8),
              const Text(
                'Room Credentials',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomIdCtrl,
            decoration: InputDecoration(
              labelText: 'Room ID',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.tag),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _roomPassCtrl,
            decoration: InputDecoration(
              labelText: 'Room Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _roomSubmitting ? null : _submitRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _roomSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                      ),
                    )
                  : const Text(
                      'Submit Room Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomDisplayCard() {
    final hasRoomDetails = _match.roomId.isNotEmpty && _match.roomPassword.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
              Icon(Icons.meeting_room, size: 20, color: Colors.yellow[700]),
              const SizedBox(width: 8),
              const Text(
                'Room Credentials',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasRoomDetails)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for creator to share room details...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _roomDetailRow('Room ID', _match.roomId, Icons.tag),
            const SizedBox(height: 10),
            _roomDetailRow('Password', _match.roomPassword, Icons.lock),
          ],
        ],
      ),
    );
  }

  Widget _roomDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              // Copy to clipboard functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}

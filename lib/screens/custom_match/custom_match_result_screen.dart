import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/api_service.dart';
import 'custom_match_reports_screen.dart';
import 'custom_match_ui_models.dart';

class CustomMatchResultScreen extends StatefulWidget {
  final CustomMatchUiModel match;

  const CustomMatchResultScreen({super.key, required this.match});

  @override
  State<CustomMatchResultScreen> createState() =>
      _CustomMatchResultScreenState();
}

class _CustomMatchResultScreenState extends State<CustomMatchResultScreen> {
  late CustomMatchUiModel _match;
  String? _selectedWinnerUserId;
  String? _proofPath;
  String? _proofUrl;
  bool _submitting = false;
  bool _refreshing = false;
  bool _submittedLocalWaiting = false;
  bool _resubmitMode = false;
  final TextEditingController _reportDetailsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    if (_match.submittedWinnerUserId.isNotEmpty) {
      _selectedWinnerUserId = _match.submittedWinnerUserId;
    }
    _proofUrl = _match.submittedProofUrl.isNotEmpty
        ? _match.submittedProofUrl
        : null;
    _submittedLocalWaiting = _match.resultSubmittedForVerification;
  }

  @override
  void dispose() {
    _reportDetailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final profileRes = await ApiService.getProfile();
    final userId = (profileRes['user'] is Map)
        ? ((profileRes['user'] as Map)['id'] ?? '').toString()
        : '';
    final details = await ApiService.getV1MatchDetails(_match.id);
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (details['error'] != null || userId.isEmpty) return;
    final raw = details['match'] is Map
        ? Map<String, dynamic>.from(details['match'] as Map)
        : <String, dynamic>{};
    if (raw.isEmpty) return;
    setState(() {
      _match = matchFromApi(raw: raw, role: _match.role, currentUserId: userId);
      if (_match.submittedWinnerUserId.isNotEmpty) {
        _selectedWinnerUserId = _match.submittedWinnerUserId;
      }
      if (_match.submittedProofUrl.isNotEmpty) {
        _proofUrl = _match.submittedProofUrl;
      }
      _submittedLocalWaiting =
          _match.resultSubmittedForVerification || _submittedLocalWaiting;
    });
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (x == null) return;
    setState(() => _proofPath = x.path);
  }

  Future<void> _submitResult() async {
    if (_submitting) return;
    if (_selectedWinnerUserId == null || _selectedWinnerUserId!.isEmpty) {
      _toast('Select winner first');
      return;
    }
    if ((_proofPath == null || _proofPath!.isEmpty) &&
        (_proofUrl == null || _proofUrl!.isEmpty)) {
      _toast('Upload proof image');
      return;
    }

    setState(() => _submitting = true);
    String finalProofUrl = _proofUrl ?? '';
    if (_proofPath != null && _proofPath!.isNotEmpty) {
      final upload = await ApiService.uploadV1MatchProofImage(_proofPath!);
      if (!mounted) return;
      if (upload['error'] != null) {
        setState(() => _submitting = false);
        _toast(upload['error'].toString());
        return;
      }
      finalProofUrl = (upload['proofUrl'] ?? '').toString();
      if (finalProofUrl.isEmpty) {
        setState(() => _submitting = false);
        _toast('Proof upload failed');
        return;
      }
    }

    setState(() {
      _proofUrl = finalProofUrl;
    });

    final res = await ApiService.submitV1MatchResult(
      matchId: _match.id,
      winnerUserId: _selectedWinnerUserId!,
      proofUrl: finalProofUrl,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['error'] != null) {
      _toast(res['error'].toString());
      return;
    }
    setState(() {
      _submittedLocalWaiting = true;
      _resubmitMode = false;
      _proofPath = null; // Clear local proof path
      _selectedWinnerUserId = null; // Clear selection
    });
    _toast('Result submitted successfully!');
    
    // Small delay to ensure backend has processed
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Refresh to get updated result claims
    await _refresh();
    
    // Don't close the screen - let users see both submissions
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _nameById(String userId) {
    if (userId == _match.creatorUserId) return _match.creatorName;
    if (userId == _match.joinerUserId) return _match.joinerName;
    return 'Pending';
  }

  String _avatarById(String userId) {
    if (userId == _match.creatorUserId) return _match.creatorAvatar;
    if (userId == _match.joinerUserId) return _match.joinerAvatar;
    return '';
  }

  bool get _isRejectedByAdmin =>
      _match.resultSubmissionStatus.toUpperCase() == 'REJECTED';

  Widget _winnerProfileCard({
    required String userId,
    required String title,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    final name = _nameById(userId);
    final avatar = _avatarById(userId);
    final isNetwork = avatar.startsWith('http');

    return InkWell(
      onTap: () => _showPlayerProfile(userId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? Colors.grey[300]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.yellow[100],
              backgroundImage: isNetwork ? NetworkImage(avatar) : null,
              child: isNetwork
                  ? null
                  : Text(
                      _nameInitials(name),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    userId == _match.creatorUserId ? 'Creator' : 'Joiner',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.info_outline,
              size: 18,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  String _nameInitials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _reportIssue() async {
    final reasons = <Map<String, dynamic>>[
      {'icon': Icons.flag_rounded, 'label': 'Cheating or hack use'},
      {
        'icon': Icons.outlined_flag_rounded,
        'label': 'Using panel or unfair tools',
      },
      {
        'icon': Icons.report_gmailerrorred_rounded,
        'label': 'Unbecoming behavior or abuse',
      },
      {'icon': Icons.warning_amber_rounded, 'label': 'Wrong result claim'},
      {'icon': Icons.info_outline_rounded, 'label': 'Other issue'},
    ];

    String? selectedReason;
    final chooseReason = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report this match result',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...reasons.map(
                    (item) => RadioListTile<String>(
                      dense: true,
                      value: item['label'].toString(),
                      groupValue: selectedReason,
                      onChanged: (value) =>
                          setSheetState(() => selectedReason = value),
                      title: Text(item['label'].toString()),
                      secondary: Icon(
                        item['icon'] as IconData,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedReason == null
                          ? null
                          : () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red[600],
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chooseReason != true || selectedReason == null) return;

    _reportDetailsCtrl.clear();
    final addMore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Want to tell us more? It's optional"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sharing a few details can help us understand the issue. Please don't include personal info or questions.",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reportDetailsCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Add details...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (addMore == null) return;

    final details = _reportDetailsCtrl.text.trim();
    final reason = selectedReason ?? '';
    if (reason.length < 3) {
      _toast('Please choose a valid reason');
      return;
    }

    final res = await ApiService.reportV1MatchIssue(
      matchId: _match.id,
      reason: reason,
      details: details,
      proofUrl: _proofUrl,
    );
    if (!mounted) return;
    if (res['error'] != null) {
      _toast(res['error'].toString());
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thanks for helping our community'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your report helps us protect the community from harmful content.',
              ),
              SizedBox(height: 8),
              Text(
                'If you think someone is in immediate danger, please contact local law enforcement.',
              ),
              SizedBox(height: 12),
              Text(
                'What you can expect',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                "We'll let you know if we remove this or limit who can see it.",
              ),
              SizedBox(height: 6),
              Text(
                'If this channel has serious or repeated violations, we may permanently remove it.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomMatchReportsScreen()),
    );
  }

  Widget _matchInfoCard() {
    final joinerName = _match.joinerName.isEmpty ? 'Joiner' : _match.joinerName;
    final roomTypeLabel = _match.roomType == 'LONE_WOLF'
        ? 'Lone Wolf'
        : 'Custom Room';
    final statusLabel = _match.status.name.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: Colors.yellow[100]!)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.summarize_rounded,
                  color: Colors.orange[800],
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Match Summary',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.yellow[200]!),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        label: 'Game',
                        value: _match.gameName,
                        icon: Icons.sports_esports_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryTile(
                        label: 'Mode',
                        value: '$roomTypeLabel • ${_match.matchType}',
                        icon: Icons.tune_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        label: 'Entry Fee',
                        value: 'Rs ${_match.entryFee.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryTile(
                        label: 'Prize Pool',
                        value: 'Rs ${_match.prizePool.toStringAsFixed(0)}',
                        icon: Icons.emoji_events_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      _playerPill(_match.creatorName, true),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _playerPill(joinerName, false),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Match ID: ${_match.id.substring(0, _match.id.length > 10 ? 10 : _match.id.length)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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

  Widget _playerPill(String name, bool isCreator) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isCreator ? Colors.yellow[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isCreator ? Colors.yellow[200]! : Colors.blue[200]!,
          ),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  Widget _proofPreviewCard() {
    final local = _proofPath;
    final remote = _proofUrl ?? _match.submittedProofUrl;
    if ((local == null || local.isEmpty) && remote.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _viewFullImage(local, remote),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[100],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            local != null && local.isNotEmpty
                ? Image.file(File(local), fit: BoxFit.cover)
                : Image.network(
                    remote,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        'Proof image available',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(String? localPath, String remotePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Proof Image',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: localPath != null && localPath.isNotEmpty
                  ? Image.file(File(localPath))
                  : Image.network(
                      remotePath,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _reportIssue,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red[300]!),
            foregroundColor: Colors.red[700],
          ),
          icon: const Icon(Icons.report_gmailerrorred_rounded),
          label: const Text(
            'Report',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _dualSubmissionView(ResultClaim mySubmission, ResultClaim otherSubmission, String currentUserId, bool canSubmit) {
    final hasMySubmission = mySubmission.id.isNotEmpty;
    final hasOtherSubmission = otherSubmission.id.isNotEmpty;
    final bothSubmitted = hasMySubmission && hasOtherSubmission;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Both players can submit their match results',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (bothSubmitted) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for Winner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Admin is verifying results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Verification in progress...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Both players have submitted their results.\nThe winner will be announced soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _submissionColumn(
                title: _match.isCreator ? 'My Submission' : 'Creator\'s Submission',
                submission: _match.isCreator ? mySubmission : otherSubmission,
                isCurrentUser: _match.isCreator,
                canSubmit: _match.isCreator && canSubmit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _submissionColumn(
                title: _match.isCreator ? 'Joiner\'s Submission' : 'My Submission',
                submission: _match.isCreator ? otherSubmission : mySubmission,
                isCurrentUser: !_match.isCreator,
                canSubmit: !_match.isCreator && canSubmit,
              ),
            ),
          ],
        ),
        if (bothSubmitted) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reportIssue,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red[300]!),
                foregroundColor: Colors.red[700],
              ),
              icon: const Icon(Icons.report_gmailerrorred_rounded),
              label: const Text(
                'Report Issue with Result',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _submissionColumn({
    required String title,
    required ResultClaim submission,
    required bool isCurrentUser,
    required bool canSubmit,
  }) {
    final hasSubmission = submission.id.isNotEmpty;
    final isRejected = submission.status.toUpperCase() == 'REJECTED';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? Colors.yellow[300]! : Colors.grey[300]!,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isCurrentUser ? Colors.orange[900] : Colors.grey[800],
                  ),
                ),
              ),
              if (isCurrentUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'YOU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasSubmission) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.pending_outlined, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 6),
                  Text(
                    isCurrentUser ? 'Submit your result below' : 'Not submitted yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRejected ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRejected ? Colors.red[200]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRejected ? Icons.cancel : Icons.check_circle,
                        size: 16,
                        color: isRejected ? Colors.red[700] : Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isRejected ? 'Rejected' : 'Submitted',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isRejected ? Colors.red[900] : Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Winner: ${submission.claimedWinnerName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (submission.proofUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _viewFullImage(null, submission.proofUrl),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              submission.proofUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image, color: Colors.grey[400]),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.zoom_in, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (isRejected && submission.rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${submission.rejectionReason}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (isCurrentUser && isRejected && canSubmit) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _resubmitMode = true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          'Resubmit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _match.status == MatchStatus.completed;
    
    // Get current user ID
    final currentUserId = _match.isCreator ? _match.creatorUserId : _match.joinerUserId;
    
    // Check if current user has submitted
    final mySubmission = _match.resultClaims.firstWhere(
      (claim) => claim.submittedBy == currentUserId,
      orElse: () => ResultClaim(
        id: '',
        submittedBy: '',
        submitterName: '',
        submitterAvatar: '',
        claimedWinnerId: '',
        claimedWinnerName: '',
        claimedWinnerAvatar: '',
        proofUrl: '',
        note: '',
        status: '',
        rejectionReason: '',
        createdAt: DateTime.now(),
      ),
    );
    
    final hasMySubmission = mySubmission.id.isNotEmpty;
    final mySubmissionRejected = mySubmission.status.toUpperCase() == 'REJECTED';
    
    // Check if other player has submitted
    final otherUserId = _match.isCreator ? _match.joinerUserId : _match.creatorUserId;
    final otherSubmission = _match.resultClaims.firstWhere(
      (claim) => claim.submittedBy == otherUserId,
      orElse: () => ResultClaim(
        id: '',
        submittedBy: '',
        submitterName: '',
        submitterAvatar: '',
        claimedWinnerId: '',
        claimedWinnerName: '',
        claimedWinnerAvatar: '',
        proofUrl: '',
        note: '',
        status: '',
        rejectionReason: '',
        createdAt: DateTime.now(),
      ),
    );
    
    final hasOtherSubmission = otherSubmission.id.isNotEmpty;
    
    final canSubmit = _match.status == MatchStatus.confirmed && 
                      (!hasMySubmission || mySubmissionRejected);
    
    final showDualView = _match.status == MatchStatus.confirmed && 
                         (hasMySubmission || hasOtherSubmission);
    
    final submittedWaiting =
        !isCompleted &&
        (_match.resultSubmittedForVerification || _submittedLocalWaiting) &&
        !_isRejectedByAdmin &&
        !_resubmitMode;
    final rejectedAndPendingResubmit =
        !isCompleted && _isRejectedByAdmin && !_resubmitMode;

    final verifiedWinnerName = _match.verifiedWinnerUserId.isNotEmpty
        ? _nameById(_match.verifiedWinnerUserId)
        : (isCompleted
              ? (_match.winnerName.isEmpty ? 'Pending' : _match.winnerName)
              : '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Match Result'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _matchInfoCard(),
            if (showDualView) _dualSubmissionView(mySubmission, otherSubmission, currentUserId, canSubmit),
            if (canSubmit && !hasMySubmission) _submissionCard(),
            if (rejectedAndPendingResubmit) _rejectedCard(),
            if (submittedWaiting && !showDualView) _waitingCard(),
            if (isCompleted) _finalResultCard(verifiedWinnerName),
          ],
        ),
      ),
    );
  }

  Widget _submissionCard() {
    final title = _resubmitMode
        ? 'Resubmit Match Result'
        : 'Stop Match & Submit Result';
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.stop_circle_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Select who won this match:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _playerSelectionCard(
            userId: _match.creatorUserId,
            name: _match.creatorName,
            avatar: _match.creatorAvatar,
            role: 'Creator',
            isSelected: _selectedWinnerUserId == _match.creatorUserId,
            onTap: () => setState(() => _selectedWinnerUserId = _match.creatorUserId),
          ),
          const SizedBox(height: 8),
          _playerSelectionCard(
            userId: _match.joinerUserId,
            name: _match.joinerName.isEmpty ? 'Joiner' : _match.joinerName,
            avatar: _match.joinerAvatar,
            role: 'Joiner',
            isSelected: _selectedWinnerUserId == _match.joinerUserId,
            onTap: () => setState(() => _selectedWinnerUserId = _match.joinerUserId),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickProof,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              (_proofPath == null && (_proofUrl == null || _proofUrl!.isEmpty))
                  ? 'Upload Proof Image'
                  : 'Change Proof Image',
            ),
          ),
          if (_proofPath != null ||
              (_proofUrl != null && _proofUrl!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _viewFullImage(_proofPath, _proofUrl ?? ''),
              child: Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _proofPath != null
                        ? Image.file(File(_proofPath!), fit: BoxFit.cover)
                        : Image.network(
                            _proofUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                'Proof image selected',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black87,
              ),
              child: Text(
                _submitting
                    ? 'Submitting...'
                    : (_resubmitMode
                          ? 'Resubmit for Admin Verification'
                          : 'Submit for Admin Verification'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerSelectionCard({
    required String userId,
    required String name,
    required String avatar,
    required String role,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isNetwork = avatar.startsWith('http');
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellow[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showPlayerProfile(userId),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.yellow[100],
                backgroundImage: isNetwork ? NetworkImage(avatar) : null,
                child: isNetwork
                    ? null
                    : Text(
                        _nameInitials(name),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showPlayerProfile(userId),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tap to view profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Radio<String>(
              value: userId,
              groupValue: _selectedWinnerUserId,
              onChanged: (v) => setState(() => _selectedWinnerUserId = v),
              activeColor: Colors.yellow[700],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlayerProfile(String userId) async {
    if (userId.isEmpty) {
      _toast('Player information not available');
      return;
    }

    // Get basic info from match data
    final userName = _nameById(userId);
    final userAvatar = _avatarById(userId);
    final isNetwork = userAvatar.startsWith('http');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getUserProfileById(userId),
            initialData: {
              'user': {
                'name': userName,
                'avatar': userAvatar,
                'gameIds': [],
              }
            },
            builder: (context, snapshot) {
              final user = snapshot.data?['user'] is Map
                  ? Map<String, dynamic>.from(snapshot.data!['user'] as Map)
                  : {'name': userName, 'avatar': userAvatar, 'gameIds': []};

              final displayName = (user['name'] ?? userName).toString();
              final displayAvatar = (user['avatar'] ?? userAvatar).toString();
              
              // Parse gameIds array to get Free Fire game details
              final gameIds = user['gameIds'] is List
                  ? List<Map<String, dynamic>>.from(
                      (user['gameIds'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
                  : <Map<String, dynamic>>[];
              
              // Find Free Fire game details
              final freeFireGame = gameIds.firstWhere(
                (game) => (game['gameName'] ?? '').toString().toLowerCase().contains('free fire'),
                orElse: () => <String, dynamic>{},
              );
              
              final gameId = freeFireGame.isNotEmpty 
                  ? (freeFireGame['gameId'] ?? 'Not set').toString()
                  : 'Not set';
              final gameInGameName = freeFireGame.isNotEmpty
                  ? (freeFireGame['inGameName'] ?? 'Not set').toString()
                  : 'Not set';
              
              final isNetworkAvatar = displayAvatar.startsWith('http');
              final isLoading = snapshot.connectionState == ConnectionState.waiting && 
                                snapshot.data?['user'] == null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.yellow[100],
                        backgroundImage: isNetworkAvatar ? NetworkImage(displayAvatar) : null,
                        child: isNetworkAvatar
                            ? null
                            : Text(
                                _nameInitials(displayName),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                      ),
                      if (isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _profileDetailRow(
                    icon: Icons.games_rounded,
                    label: 'Game ID',
                    value: gameId,
                    isLoading: isLoading && gameId == 'Not set',
                  ),
                  const SizedBox(height: 10),
                  _profileDetailRow(
                    icon: Icons.person_rounded,
                    label: 'In-Game Name',
                    value: gameInGameName,
                    isLoading: isLoading && gameInGameName == 'Not set',
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Some details could not be loaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.orange[900]),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                isLoading
                    ? SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedCard() {
    final winnerName = _match.submittedWinnerUserId.isEmpty
        ? 'Not selected'
        : _nameById(_match.submittedWinnerUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_gmailerrorred_rounded, color: Colors.red[800]),
              const SizedBox(width: 8),
              Text(
                'Submission Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Previous claimed winner: $winnerName'),
          if (_match.resultSubmissionNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${_match.resultSubmissionNote}',
              style: TextStyle(
                color: Colors.red[900],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _resubmitMode = true;
                  _submittedLocalWaiting = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black87,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Resubmit Result',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingCard() {
    final winnerName = _match.submittedWinnerUserId.isEmpty
        ? 'Pending'
        : _nameById(_match.submittedWinnerUserId);
    final winnerId = _match.submittedWinnerUserId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.orange[800]),
              const SizedBox(width: 8),
              Text(
                'Waiting for admin verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Submitted by: ${_match.resultSubmittedByName.isEmpty ? 'Player' : _match.resultSubmittedByName}',
          ),
          Text('Claimed winner: $winnerName'),
          if (winnerId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _winnerProfileCard(
              userId: winnerId,
              title: 'Selected Winner',
              borderColor: Colors.orange[200],
              backgroundColor: Colors.white,
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Both players will see final result after admin verifies.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          _proofPreviewCard(),
          _reportButton(),
        ],
      ),
    );
  }

  Widget _finalResultCard(String winnerName) {
    final winnerUserId = _match.verifiedWinnerUserId.isNotEmpty
        ? _match.verifiedWinnerUserId
        : (_match.winnerName == _match.creatorName
              ? _match.creatorUserId
              : _match.joinerUserId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 54, color: Colors.amber[700]),
          const SizedBox(height: 8),
          Text(
            'Winner: $winnerName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _winnerProfileCard(
            userId: winnerUserId,
            title: 'Verified Winner',
            borderColor: Colors.green[200],
            backgroundColor: Colors.green[50],
          ),
          const SizedBox(height: 6),
          Text('Prize: Rs ${_match.prizePool.toStringAsFixed(0)}'),
          Text('Entry Fee: Rs ${_match.entryFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Admin verified result',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          _proofPreviewCard(),
          _reportButton(),
        ],
      ),
    );
  }
}

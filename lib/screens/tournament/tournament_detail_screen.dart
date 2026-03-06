import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/api_service.dart';
import '../wallet/wallet_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String title;
  final String prize;
  final String startTime;
  final String participants;
  final String mode;
  final String entryFee;
  final bool isRegistered;
  final String? tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.title,
    required this.prize,
    required this.startTime,
    required this.participants,
    required this.mode,
    required this.entryFee,
    required this.isRegistered,
    this.tournamentId,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late bool _isRegistered;
  bool _isSubmitting = false;
  bool _isLobbyLoading = false;
  bool _isTournamentLoading = false;
  List<Map<String, dynamic>> _lobbyMatches = [];
  String? _tournamentRoomId;
  String? _tournamentRoomPassword;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
    _loadLobby();
    _loadTournamentDetails();
  }

  Future<void> _loadTournamentDetails() async {
    if (widget.tournamentId == null || widget.tournamentId!.isEmpty) return;
    setState(() => _isTournamentLoading = true);
    final res = await ApiService.getTournamentDetails(widget.tournamentId!);
    if (!mounted) return;
    final tournament = (res['tournament'] is Map)
        ? Map<String, dynamic>.from(res['tournament'])
        : <String, dynamic>{};
    setState(() {
      _tournamentRoomId = (tournament['roomId'] ?? '').toString();
      _tournamentRoomPassword = (tournament['roomPassword'] ?? '').toString();
      // Update isRegistered from the API response
      final apiIsRegistered = tournament['isRegistered'] == true;
      if (apiIsRegistered) {
        _isRegistered = true;
      }
      _isTournamentLoading = false;
    });
  }

  Future<void> _loadLobby() async {
    if (widget.tournamentId == null || widget.tournamentId!.isEmpty) return;
    setState(() => _isLobbyLoading = true);
    final res = await ApiService.getTournamentLobby(widget.tournamentId!);
    if (!mounted) return;
    final matches = (res['matches'] is List)
        ? List<Map<String, dynamic>>.from(
            (res['matches'] as List).whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
          )
        : <Map<String, dynamic>>[];
    setState(() {
      _lobbyMatches = matches;
      _isLobbyLoading = false;
    });
  }

  Future<void> _register() async {
    final tournamentProvider = context.read<TournamentProvider>();

    if (_isSubmitting || _isRegistered) return;
    if (widget.tournamentId == null || widget.tournamentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament ID missing. Please refresh and try again.'),
        ),
      );
      return;
    }

    final feeText = widget.entryFee.replaceAll(RegExp(r'[^0-9.]'), '');
    final entryFee = double.tryParse(feeText) ?? 0.0;

    final balanceRes = await ApiService.getWalletBalance();
    if (!mounted) return;
    if (balanceRes['error'] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(balanceRes['error'].toString())));
      return;
    }

    final balance = (balanceRes['balance'] is num)
        ? (balanceRes['balance'] as num).toDouble()
        : 0.0;
    if (balance < entryFee) {
      final goToWallet = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Entry fee is Rs ${entryFee.toStringAsFixed(0)}, but your wallet has Rs ${balance.toStringAsFixed(0)}.\n\nPlease add money first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Money'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (goToWallet == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Registration'),
        content: Text(
          'Rs ${entryFee.toStringAsFixed(0)} will be deducted from your wallet.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    final success = await tournamentProvider.joinTournament(
      widget.tournamentId!,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      final msg = tournamentProvider.error ?? 'Failed to register';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() => _isRegistered = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Successfully registered!')));
    
    // Reload tournament details to get updated registration status
    await _loadTournamentDetails();
    await _loadLobby();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadTournamentDetails(),
      _loadLobby(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      _heroCard(),
                      const SizedBox(height: 16),
                      _infoRow(),
                      const SizedBox(height: 16),
                      _detailsCard(),
                      const SizedBox(height: 16),
                      _roomAndResultCard(),
                      const SizedBox(height: 16),
                      _rulesCard(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Tournament Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.yellow[700]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 42),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prize Pool: ${widget.prize}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow() {
    return Row(
      children: [
        Expanded(
          child: _infoTile('Starts', widget.startTime, Icons.access_time),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoTile('Players', widget.participants, Icons.groups),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.yellow[700]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Mode', widget.mode),
          _detailRow('Entry Fee', widget.entryFee),
          _detailRow('Status', _isRegistered ? 'Registered' : 'Open'),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 10),
          _rule('Join before start time.'),
          _rule('No cheating allowed.'),
          _rule('Results are reviewed by admins.'),
        ],
      ),
    );
  }

  Widget _roomAndResultCard() {
    // Show loading if either is loading
    if (_isLobbyLoading || _isTournamentLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const LinearProgressIndicator(minHeight: 4),
      );
    }

    // Check if we have room details from tournament
    final hasRoomDetails = _tournamentRoomId != null && 
                           _tournamentRoomId!.isNotEmpty &&
                           _tournamentRoomPassword != null &&
                           _tournamentRoomPassword!.isNotEmpty;

    // If no room details and no lobby matches
    if (!hasRoomDetails && _lobbyMatches.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          _isRegistered
              ? 'Room details will appear here when admin starts the tournament.'
              : 'Register to see room details and result updates.',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      );
    }

    // Get winner info from lobby if available
    String winnerName = '';
    if (_lobbyMatches.isNotEmpty) {
      final first = _lobbyMatches.first;
      final match = (first['match'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(first['match'])
          : <String, dynamic>{};
      final winner = (match['winner'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(match['winner'])
          : null;
      winnerName = winner != null
          ? (winner['name'] ?? 'Unknown').toString()
          : '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasRoomDetails 
            ? LinearGradient(
                colors: [Colors.green[50]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasRoomDetails ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRoomDetails ? Colors.green[300]! : Colors.grey[200]!,
          width: hasRoomDetails ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRoomDetails ? Icons.meeting_room : Icons.info_outline,
                color: hasRoomDetails ? Colors.green[700] : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Room & Result',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasRoomDetails ? Colors.green[900] : Colors.grey[900],
                ),
              ),
              if (hasRoomDetails) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (hasRoomDetails) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Room ID',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SelectableText(
                        _tournamentRoomId!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SelectableText(
                        _tournamentRoomPassword!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _detailRow('Room ID', 'Not started yet'),
            _detailRow('Room Password', 'Not started yet'),
          ],
          _detailRow(
            'Winner',
            winnerName.isEmpty ? 'Result pending' : winnerName,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.entryFee,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isRegistered || _isSubmitting ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistered
                      ? Colors.green[600]
                      : Colors.yellow[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.green[600],
                  disabledForegroundColor: Colors.white,
                ),
                child: Text(
                  _isSubmitting
                      ? 'Registering...'
                      : _isRegistered
                      ? 'Joined ✓'
                      : 'Register Now',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


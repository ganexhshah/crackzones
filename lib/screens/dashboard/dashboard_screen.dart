import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/custom_header.dart';
import '../../widgets/custom_navbar.dart';
import '../../widgets/wallet_card.dart';
import '../../services/api_service.dart';
import '../../services/custom_match_socket_service.dart';
import '../custom_match/custom_match_components.dart';
import '../custom_match/custom_match_details_screen.dart';
import '../custom_match/custom_match_home_screen.dart';
import '../custom_match/custom_match_result_screen.dart';
import '../custom_match/custom_match_ui_models.dart';
import '../more/more_screen.dart';
import '../tournament/tournament_detail_screen.dart';
import '../tournament/tournament_screen.dart';
import '../wallet/wallet_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool showBottomNav;

  const DashboardScreen({super.key, this.showBottomNav = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _tournamentAlerts = [];
  bool _alertsLoading = false;
  bool _customMatchesLoading = false;
  bool _customMatchesRefreshing = false;
  List<CustomMatchUiModel> _dashboardCustomMatches = [];
  String _currentUserId = '';
  StreamSubscription<MatchSocketEvent>? _socketSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadProfile();
      Provider.of<UserProvider>(context, listen: false).loadWalletBalance();
      Provider.of<UserProvider>(context, listen: false).loadStats();
      Provider.of<TournamentProvider>(context, listen: false).loadTournaments();
      _loadTournamentAlerts();
      _loadDashboardCustomMatches();
      _initSocket();
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
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
      _loadDashboardCustomMatches(silent: true);
      return;
    }
    if (event.type == 'wallet.updated') {
      context.read<UserProvider>().loadWalletBalance();
      return;
    }
    final matchId = event.matchId;
    if (matchId == null || matchId.isEmpty) return;
    _applySocketPatch(event);
    _refreshDashboardMatchById(matchId);
  }

  void _applySocketPatch(MatchSocketEvent event) {
    final matchId = event.matchId;
    if (matchId == null || matchId.isEmpty) return;
    final rawStatus = (event.payload['status'] ?? '').toString();
    if (rawStatus.isEmpty) return;
    final status = parseBackendStatus(rawStatus);

    setState(() {
      _dashboardCustomMatches = _dashboardCustomMatches.map((m) {
        if (m.id != matchId) return m;
        return m.copyWith(
          status: status,
          chatEnabled: status == MatchStatus.confirmed,
          roomId: event.type == 'match.room_ready'
              ? (event.payload['roomIdMasked'] ?? m.roomId).toString()
              : m.roomId,
          roomPassword: event.type == 'match.room_ready'
              ? (event.payload['roomPasswordMasked'] ?? m.roomPassword)
                    .toString()
              : m.roomPassword,
        );
      }).toList();
    });
  }

  Future<void> _refreshDashboardMatchById(String matchId) async {
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
    final row = matchFromApi(
      raw: raw,
      role: isCreator ? MatchRole.creator : MatchRole.joiner,
      currentUserId: _currentUserId,
    );

    setState(() {
      final list = List<CustomMatchUiModel>.from(_dashboardCustomMatches);
      final idx = list.indexWhere((m) => m.id == row.id);
      final keep =
          (row.status == MatchStatus.open ||
              row.status == MatchStatus.requested ||
              row.status == MatchStatus.confirmed) &&
          row.resultClaims.length < 2; // Hide if both players submitted

      if (idx >= 0) {
        if (keep) {
          list[idx] = row;
        } else {
          list.removeAt(idx);
        }
      } else if (keep) {
        list.insert(0, row);
      }
      _dashboardCustomMatches = list.take(2).toList();
    });
  }

  void _openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    );
  }

  void _openTournaments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TournamentScreen()),
    );
  }

  void _openCustomMatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomMatchHomeScreen(
          showBottomNav: false,
          showBackButton: true,
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    final userProvider = context.read<UserProvider>();
    final tournamentProvider = context.read<TournamentProvider>();

    await Future.wait([
      userProvider.loadProfile(),
      userProvider.loadWalletBalance(),
      userProvider.loadStats(),
      tournamentProvider.loadTournaments(),
      _loadTournamentAlerts(),
      _loadDashboardCustomMatches(),
    ]);
  }

  Future<void> _loadTournamentAlerts() async {
    if (_alertsLoading) return;
    setState(() => _alertsLoading = true);
    final res = await ApiService.getTournamentAlerts();
    if (!mounted) return;

    if (res['alerts'] is List) {
      final alerts = List<Map<String, dynamic>>.from(
        (res['alerts'] as List).whereType<Map>().map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
      setState(() {
        _tournamentAlerts = alerts;
        _alertsLoading = false;
      });
      return;
    }

    setState(() {
      _tournamentAlerts = [];
      _alertsLoading = false;
    });
  }

  Future<void> _loadDashboardCustomMatches({bool silent = false}) async {
    if (_customMatchesLoading || _customMatchesRefreshing) return;
    if (silent) {
      _customMatchesRefreshing = true;
    } else {
      setState(() => _customMatchesLoading = true);
    }
    try {
      final profileRes = await ApiService.getProfile();
      final user = profileRes['user'] is Map
          ? Map<String, dynamic>.from(profileRes['user'] as Map)
          : <String, dynamic>{};
      final userId = (user['id'] ?? '').toString();
      _currentUserId = userId;

      final matchesRes = await ApiService.getV1Matches(limit: 20);
      if (!mounted) return;

      if (userId.isEmpty || matchesRes['error'] != null) {
        setState(() {
          if (!silent) {
            _dashboardCustomMatches = [];
          }
          _customMatchesLoading = false;
        });
        return;
      }

      final rows = (matchesRes['matches'] is List)
          ? List<Map<String, dynamic>>.from(
              (matchesRes['matches'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : <Map<String, dynamic>>[];

      final cards = rows
          .where((m) {
            final creatorId = (m['creatorId'] ?? '').toString();
            final joinerId = (m['joinerId'] ?? '').toString();
            final status = (m['status'] ?? '').toString().toUpperCase();

            // Show user's own matches (as creator or joiner)
            final isMyMatch = creatorId == userId || joinerId == userId;

            // Show open matches created by others (joinable)
            final isJoinable = status == 'OPEN' && creatorId != userId;

            return isMyMatch || isJoinable;
          })
          .map((m) {
            final creatorId = (m['creatorId'] ?? '').toString();
            final isCreator = creatorId == userId;
            return matchFromApi(
              raw: m,
              role: isCreator ? MatchRole.creator : MatchRole.joiner,
              currentUserId: userId,
            );
          })
          .where((m) {
            // Filter by status
            final isActiveStatus =
                m.status == MatchStatus.open ||
                m.status == MatchStatus.requested ||
                m.status == MatchStatus.confirmed;

            if (!isActiveStatus) return false;

            // Hide matches where both players have submitted results
            if (m.resultClaims.length >= 2) {
              return false;
            }

            return true;
          })
          .take(2)
          .toList();

      setState(() {
        _dashboardCustomMatches = cards;
        _customMatchesLoading = false;
      });
    } finally {
      _customMatchesRefreshing = false;
    }
  }

  Future<void> _openDashboardCustomMatchDetails(CustomMatchUiModel m) async {
    final resultPending =
        m.status == MatchStatus.confirmed &&
        m.resultSubmittedForVerification &&
        m.resultSubmissionStatus.toUpperCase() != 'REJECTED';
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => (m.status == MatchStatus.completed || resultPending)
            ? CustomMatchResultScreen(match: m)
            : CustomMatchDetailsScreen(match: m),
      ),
    );
    if (changed == true) {
      await _loadDashboardCustomMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.yellow[50]!,
              const Color(0xFFF6F7FB),
              const Color(0xFFF6F7FB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.24, 1],
          ),
        ),
        child: Column(
          children: [
            const CustomHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTournamentAlertTop(),
                          if (_alertsLoading || _tournamentAlerts.isNotEmpty)
                            SizedBox(height: isTablet ? 20 : 16),
                          _buildWalletSection(isTablet),
                          SizedBox(height: isTablet ? 28 : 24),
                          _buildCustomMatchesSection(),
                          SizedBox(height: isTablet ? 28 : 24),
                          _buildTournamentsSection(isTablet),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 1) {
                  _openTournaments();
                } else if (index == 2) {
                  _openCustomMatch();
                } else if (index == 3) {
                  _openWallet();
                } else if (index == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MoreScreen()),
                  );
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
            )
          : null,
    );
  }

  Widget _buildWalletSection(bool isTablet) {
    final stats = context.watch<UserProvider>().stats;
    final winningAmount = ((stats?['totalEarnings'] ?? 0) as num).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        WalletCard(
          winningAmount: winningAmount,
          onAddMoney: _openWallet,
          onWithdraw: _openWallet,
        ),
      ],
    );
  }

  Widget _buildCustomMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Custom Matches',
          subtitle: 'Fast 1v1 rooms with live status',
          actionLabel: 'View All',
          onActionTap: _openCustomMatch,
        ),
        const SizedBox(height: 8),
        if (_customMatchesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_customMatchesLoading && _dashboardCustomMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 48,
                    color: Colors.yellow[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Custom Matches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new match or join an existing one\nto start playing with other players!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openCustomMatch,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Browse Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[600],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        if (!_customMatchesLoading && _dashboardCustomMatches.isNotEmpty)
          ..._dashboardCustomMatches.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomMatchCard(
                match: m,
                actionLabel:
                    (m.status == MatchStatus.completed ||
                        (m.status == MatchStatus.confirmed &&
                            m.resultSubmittedForVerification &&
                            m.resultSubmissionStatus.toUpperCase() !=
                                'REJECTED'))
                    ? 'Open Result'
                    : (m.isCreator ? 'Manage' : 'Open'),
                onAction: () => _openDashboardCustomMatchDetails(m),
                onTap: () => _openDashboardCustomMatchDetails(m),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTournamentAlertTop() {
    if (_alertsLoading && _tournamentAlerts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const LinearProgressIndicator(minHeight: 4),
      );
    }

    if (_tournamentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeRoomAlert = _tournamentAlerts.firstWhere(
      (a) =>
          (a['roomId'] ?? '').toString().isNotEmpty &&
          (a['roomPass'] ?? '').toString().isNotEmpty,
      orElse: () => _tournamentAlerts.first,
    );

    final winner = activeRoomAlert['winner'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(activeRoomAlert['winner'])
        : null;
    final roomId = (activeRoomAlert['roomId'] ?? '').toString();
    final roomPass = (activeRoomAlert['roomPass'] ?? '').toString();
    final title = (activeRoomAlert['tournamentTitle'] ?? 'Tournament')
        .toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(
                Icons.notifications_active,
                color: Colors.orange[800],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tournament Update: $title',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          if (roomId.isNotEmpty && roomPass.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Room ID: $roomId',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Password: $roomPass',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ],
          if (winner != null) ...[
            const SizedBox(height: 8),
            Text(
              'Winner: ${(winner['name'] ?? 'Unknown').toString()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.green[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentsSection(bool isTablet) {
    final tournamentProvider = context.watch<TournamentProvider>();
    final cards = tournamentProvider.tournaments
        .whereType<Map>()
        .map((e) => _DashboardTournament.fromApi(Map<String, dynamic>.from(e)))
        .where((t) => t.status == 'upcoming')
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Upcoming Tournaments',
          actionLabel: 'View All',
          onActionTap: _openTournaments,
        ),
        const SizedBox(height: 8),
        if (tournamentProvider.isLoading && cards.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!tournamentProvider.isLoading && tournamentProvider.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tournamentProvider.error!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<TournamentProvider>().loadTournaments(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (!tournamentProvider.isLoading &&
            tournamentProvider.error == null &&
            cards.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.orange[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Upcoming Tournaments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tournaments available right now.\nNew tournaments will appear here soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        if (!tournamentProvider.isLoading &&
            tournamentProvider.error == null &&
            cards.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final canUseGrid = isTablet && constraints.maxWidth > 800;
              if (canUseGrid) {
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: (constraints.maxWidth - 14) / 2,
                          child: _buildTournamentCard(card),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTournamentCard(card),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTournamentCard(_DashboardTournament t) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailScreen(
                title: t.title,
                prize: 'Rs ${t.prizePool.toStringAsFixed(0)}',
                startTime: _formatTournamentStart(t.startTime),
                participants: '${t.currentPlayers}/${t.maxPlayers} players',
                mode: t.modeLabel,
                entryFee: 'Rs ${t.entryFee.toStringAsFixed(0)}',
                isRegistered: false,
                tournamentId: t.id,
              ),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: t.accent[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(t.icon, color: t.accent[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatTournamentStart(t.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTournamentMetaCard(
                      'Prize Pool',
                      'Rs ${t.prizePool.toStringAsFixed(0)}',
                      t.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTournamentMetaCard(
                      'Mode',
                      t.modeLabel,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t.currentPlayers}/${t.maxPlayers} players',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.accent[50],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t.isFull ? 'Full' : 'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.accent[700],
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

  String _formatTournamentStart(DateTime dt) {
    return 'Starts ${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildTournamentMetaCard(
    String label,
    String value,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.yellow[800],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.yellow[200]!),
              ),
              backgroundColor: Colors.yellow[50],
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardTournament {
  final String id;
  final String title;
  final String mode;
  final double entryFee;
  final double prizePool;
  final int currentPlayers;
  final int maxPlayers;
  final DateTime startTime;
  final String status;

  const _DashboardTournament({
    required this.id,
    required this.title,
    required this.mode,
    required this.entryFee,
    required this.prizePool,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.startTime,
    required this.status,
  });

  bool get isFull => currentPlayers >= maxPlayers;

  String get modeLabel {
    final m = mode.trim().toLowerCase();
    if (m == 'duo') return 'Duo';
    if (m == 'squad') return 'Squad';
    return 'Solo';
  }

  MaterialColor get accent {
    if (modeLabel == 'Duo') return Colors.deepOrange;
    if (modeLabel == 'Squad') return Colors.teal;
    return Colors.indigo;
  }

  IconData get icon {
    if (modeLabel == 'Duo') return Icons.people;
    if (modeLabel == 'Squad') return Icons.groups;
    return Icons.emoji_events;
  }

  factory _DashboardTournament.fromApi(Map<String, dynamic> raw) {
    final startRaw = (raw['startTime'] ?? '').toString();
    return _DashboardTournament(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Tournament').toString(),
      mode: (raw['mode'] ?? 'SOLO').toString(),
      entryFee: ((raw['entryFee'] ?? 0) as num).toDouble(),
      prizePool: ((raw['prizePool'] ?? 0) as num).toDouble(),
      currentPlayers: ((raw['currentPlayers'] ?? 0) as num).toInt(),
      maxPlayers: ((raw['maxPlayers'] ?? 0) as num).toInt(),
      startTime: DateTime.tryParse(startRaw)?.toLocal() ?? DateTime.now(),
      status: (raw['status'] ?? 'upcoming').toString().toLowerCase(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_navbar.dart';
import 'tournament_detail_screen.dart';
import '../wallet/wallet_screen.dart';

class TournamentScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const TournamentScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 1;
  late TabController _tabController;
  String _selectedFilter = 'All';
  bool _showFilters = true;
  String? _joiningTournamentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournaments();
    });
  }

  Future<void> _refreshTournaments() async {
    await context.read<TournamentProvider>().loadTournaments();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournaments = provider.tournaments
        .whereType<Map>()
        .map((raw) => _TournamentRow.fromApi(Map<String, dynamic>.from(raw)))
        .toList();

    final filteredByMode = _selectedFilter == 'All'
        ? tournaments
        : tournaments
              .where(
                (t) => t.mode.toLowerCase() == _selectedFilter.toLowerCase(),
              )
              .toList();

    final upcoming = filteredByMode
        .where((t) => t.status == 'upcoming')
        .toList();
    final live = filteredByMode.where((t) => t.status == 'live').toList();
    final completed = filteredByMode
        .where((t) => t.status == 'completed' || t.status == 'cancelled')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _showFilters
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildFilterChips(),
              secondChild: const SizedBox.shrink(),
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTournamentList(
                    rows: upcoming,
                    loading: provider.isLoading,
                    error: provider.error,
                    emptyText: 'No upcoming tournaments found.',
                    onRefresh: _refreshTournaments,
                  ),
                  _buildTournamentList(
                    rows: live,
                    loading: provider.isLoading,
                    error: provider.error,
                    emptyText: 'No live tournaments right now.',
                    onRefresh: _refreshTournaments,
                  ),
                  _buildTournamentList(
                    rows: completed,
                    loading: provider.isLoading,
                    error: provider.error,
                    emptyText: 'No completed tournaments yet.',
                    onRefresh: _refreshTournaments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index != 1) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Tournaments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? Colors.yellow[700] : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _refreshTournaments,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Solo', 'Squad', 'Duo'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.yellow[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[700],
        indicator: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Live'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTournamentList({
    required List<_TournamentRow> rows,
    required bool loading,
    required String? error,
    required String emptyText,
    required Future<void> Function() onRefresh,
  }) {
    if (loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: error != null && rows.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(error, style: TextStyle(color: Colors.red[700])),
                ),
              ],
            )
          : rows.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    emptyText,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final t = rows[index];
                final joining = _joiningTournamentId == t.id;
                return _buildTournamentCard(t, joining: joining);
              },
            ),
    );
  }

  Widget _buildTournamentCard(_TournamentRow t, {required bool joining}) {
    final isLive = t.status == 'live';
    final canJoin = t.status == 'upcoming' && !t.isFull;
    final statusColor = _getStatusMaterialColor(t.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: statusColor[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.game} • ${t.mode.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: statusColor[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        t.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info boxes
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Entry Fee',
                        value: 'Rs ${t.entryFee.toStringAsFixed(0)}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoBox(
                        icon: Icons.emoji_events_outlined,
                        label: 'Prize Pool',
                        value: 'Rs ${t.prizePool.toStringAsFixed(0)}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Details grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Players: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${t.currentPlayers}/${t.maxPlayers}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: t.isFull
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.isFull ? 'FULL' : 'OPEN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: t.isFull
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatStart(t.startTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openDetails(t),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canJoin && !joining && !t.isRegistered
                            ? () => _joinTournament(t)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.isRegistered
                              ? Colors.green[600]
                              : isLive
                              ? Colors.green[600]
                              : Colors.yellow[700],
                          foregroundColor: (isLive || t.isRegistered) ? Colors.white : Colors.black,
                          elevation: 0,
                          disabledBackgroundColor: t.isRegistered 
                              ? Colors.green[600]
                              : Colors.grey[300],
                          disabledForegroundColor: t.isRegistered
                              ? Colors.white
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          joining
                              ? 'Joining...'
                              : t.isRegistered
                              ? 'Joined ✓'
                              : isLive
                              ? 'Watch Live'
                              : t.isFull
                              ? 'Full'
                              : t.status == 'completed'
                              ? 'Ended'
                              : 'Join Now',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[900],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinTournament(_TournamentRow t) async {
    final tournamentProvider = context.read<TournamentProvider>();

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
    if (balance < t.entryFee) {
      final goToWallet = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Entry fee is Rs ${t.entryFee.toStringAsFixed(0)}, but your wallet has Rs ${balance.toStringAsFixed(0)}.\n\nPlease add money to join this tournament.',
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
        title: const Text('Confirm Join'),
        content: Text(
          'Rs ${t.entryFee.toStringAsFixed(0)} will be deducted from your wallet to join this tournament.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _joiningTournamentId = t.id);
    final success = await tournamentProvider.joinTournament(t.id);
    if (!mounted) return;
    setState(() => _joiningTournamentId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Joined tournament successfully'
              : 'Failed to join tournament',
        ),
      ),
    );
  }

  void _openDetails(_TournamentRow t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(
          title: t.title,
          prize: 'Rs ${t.prizePool.toStringAsFixed(0)}',
          startTime: _formatStart(t.startTime),
          participants: '${t.currentPlayers}/${t.maxPlayers} players',
          mode: t.mode,
          entryFee: 'Rs ${t.entryFee.toStringAsFixed(0)}',
          isRegistered: t.isRegistered,
          tournamentId: t.id,
        ),
      ),
    );
  }

  String _formatStart(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else if (diff.inSeconds > 0) {
      return 'Starting soon';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  MaterialColor _getStatusMaterialColor(String status) {
    switch (status) {
      case 'live':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _TournamentRow {
  final String id;
  final String title;
  final String game;
  final String mode;
  final double entryFee;
  final double prizePool;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime startTime;
  final String status;
  final bool isRegistered;

  const _TournamentRow({
    required this.id,
    required this.title,
    required this.game,
    required this.mode,
    required this.entryFee,
    required this.prizePool,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.startTime,
    required this.status,
    this.isRegistered = false,
  });

  bool get isFull => currentPlayers >= maxPlayers;

  factory _TournamentRow.fromApi(Map<String, dynamic> raw) {
    final mode = (raw['mode'] ?? 'SOLO').toString().toLowerCase();
    final status = (raw['status'] ?? 'upcoming').toString().toLowerCase();
    final startRaw = (raw['startTime'] ?? '').toString();
    final isRegistered = (raw['isRegistered'] == true);
    return _TournamentRow(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Tournament').toString(),
      game: (raw['game'] ?? 'Game').toString(),
      mode: mode.isEmpty ? 'solo' : mode,
      entryFee: ((raw['entryFee'] ?? 0) as num).toDouble(),
      prizePool: ((raw['prizePool'] ?? 0) as num).toDouble(),
      maxPlayers: ((raw['maxPlayers'] ?? 0) as num).toInt(),
      currentPlayers: ((raw['currentPlayers'] ?? 0) as num).toInt(),
      startTime: DateTime.tryParse(startRaw)?.toLocal() ?? DateTime.now(),
      status: status,
      isRegistered: isRegistered,
    );
  }
}

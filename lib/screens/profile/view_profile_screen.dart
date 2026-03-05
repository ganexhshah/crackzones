import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _user;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await ApiService.getUserProfileById(widget.userId);
    if (!mounted) return;
    if (res['error'] != null) {
      setState(() {
        _error = res['error'].toString();
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _user = (res['user'] is Map)
          ? Map<String, dynamic>.from(res['user'] as Map)
          : null;
      _activities = (res['recentActivities'] is List)
          ? List<dynamic>.from(res['recentActivities'] as List)
          : [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Player Profile',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTopCard(),
                  const SizedBox(height: 14),
                  _buildGameIdsCard(),
                  const SizedBox(height: 14),
                  _buildStatsCard(),
                  const SizedBox(height: 14),
                  _buildActivityCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildTopCard() {
    final name = (_user?['name'] ?? 'User').toString();
    final email = (_user?['email'] ?? '').toString();
    final avatar = (_user?['avatar'] ?? '').toString();
    final activityCount = _activities.length;
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[500]!, Colors.indigo[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? 'No email available' : email,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _infoPill(
                  icon: Icons.bolt_rounded,
                  label: 'Activities',
                  value: '$activityCount',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _infoPill(
                  icon: Icons.sports_esports_rounded,
                  label: 'Games',
                  value:
                      '${(_user?['gameIds'] is List) ? (_user?['gameIds'] as List).length : 0}',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color[100]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color[900],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameIdsCard() {
    final gameIds = (_user?['gameIds'] is List)
        ? List<dynamic>.from(_user!['gameIds'] as List)
        : <dynamic>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game IDs',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (gameIds.isEmpty)
            Text('No game id added', style: TextStyle(color: Colors.grey[600]))
          else
            ...gameIds.map((g) {
              final row = (g is Map)
                  ? Map<String, dynamic>.from(g)
                  : <String, dynamic>{};
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (row['gameName'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Game ID: ${(row['gameId'] ?? '-').toString()}'),
                    Text(
                      'In-game Name: ${(row['inGameName'] ?? '-').toString()}',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = (_user?['stats'] is Map)
        ? Map<String, dynamic>.from(_user!['stats'] as Map)
        : <String, dynamic>{};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Created',
                  value: '${stats['customMatchesCreated'] ?? 0}',
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  label: 'Played',
                  value: '${stats['customMatchesPlayed'] ?? 0}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  label: 'Activity',
                  value: '${stats['totalActivities'] ?? 0}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color[900],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color[700], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (_activities.isEmpty)
            Text('No activities yet', style: TextStyle(color: Colors.grey[600]))
          else
            ..._activities.map((a) {
              final row = (a is Map)
                  ? Map<String, dynamic>.from(a)
                  : <String, dynamic>{};
              final type = (row['type'] ?? '').toString();
              final amount = (row['amount'] is num)
                  ? (row['amount'] as num).toDouble()
                  : 0;
              final status = (row['status'] ?? '').toString();
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bolt, color: Colors.orange[700]),
                title: Text(type.replaceAll('_', ' ')),
                subtitle: Text(status),
                trailing: Text('Rs ${amount.abs().toStringAsFixed(0)}'),
              );
            }),
        ],
      ),
    );
  }
}

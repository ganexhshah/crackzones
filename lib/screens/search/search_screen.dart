import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<Map<String, dynamic>> _bannerItems = const [
    {
      'title': 'Hot Tournaments',
      'subtitle': 'Find active paid matches quickly',
      'icon': Icons.local_fire_department,
      'start': Color(0xFFFB923C),
      'end': Color(0xFFF97316),
    },
    {
      'title': 'Custom Rooms',
      'subtitle': 'Create or join private rooms',
      'icon': Icons.sports_esports,
      'start': Color(0xFF60A5FA),
      'end': Color(0xFF2563EB),
    },
    {
      'title': 'Wallet & Rewards',
      'subtitle': 'Track coins, gifts, and bonuses',
      'icon': Icons.account_balance_wallet,
      'start': Color(0xFF34D399),
      'end': Color(0xFF059669),
    },
  ];

  bool _isLoading = false;
  List<Map<String, String>> _quickSearches = const [];
  List<Map<String, String>> _recentSearches = const [];
  List<Map<String, String>> _results = const [];

  @override
  void initState() {
    super.initState();
    _loadSearchData('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchData(String query) async {
    setState(() => _isLoading = true);
    final res = await ApiService.search(query);
    if (!mounted) return;

    if (res['error'] != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    List<Map<String, String>> toRows(dynamic rows) {
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map(
            (e) => <String, String>{
              'title': (e['title'] ?? '').toString(),
              'subtitle': (e['subtitle'] ?? '').toString(),
              'type': (e['type'] ?? '').toString(),
              'id': (e['id'] ?? '').toString(),
            },
          )
          .where((e) => (e['title'] ?? '').isNotEmpty)
          .toList();
    }

    setState(() {
      _quickSearches = toRows(res['quickSearches']);
      _recentSearches = toRows(res['recentSearches']);
      _results = toRows(res['results']);
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadSearchData(value.trim());
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        title: Text(
          'Search',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            _buildSearchInput(),
            const SizedBox(height: 16),
            _buildScrollableBanner(),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Quick Search',
              subtitle: 'From backend shortcuts',
              child: _isLoading
                  ? _buildQuickSearchSkeleton()
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _quickSearches
                          .map((item) => _buildQuickChip(item['title']!))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Recent Searches',
              subtitle: 'From your recent backend activity',
              child: _isLoading
                  ? _buildResultSkeletonList()
                  : Column(
                      children: _recentSearches.isEmpty
                          ? [
                              Text(
                                'No recent activity yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ]
                          : _recentSearches
                              .map(
                                (item) => _buildResultTile(
                                  icon: Icons.history,
                                  title: item['title']!,
                                  subtitle: item['subtitle']!,
                                ),
                              )
                              .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Search Results',
              subtitle: 'Live results from backend',
              child: _isLoading
                  ? _buildResultSkeletonList()
                  : Column(
                      children: _results.isEmpty
                          ? [
                              Text(
                                _searchController.text.trim().isEmpty
                                    ? 'Type to search tournaments and custom rooms'
                                    : 'No results found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ]
                          : _results
                              .map(
                                (item) => _buildResultTile(
                                  icon: _iconForType(item['type'] ?? ''),
                                  title: item['title']!,
                                  subtitle: item['subtitle']!,
                                ),
                              )
                              .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'tournament':
        return Icons.emoji_events_outlined;
      case 'custom_match':
        return Icons.sports_esports_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.search;
    }
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search rooms, tournaments, wallet, profile...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildScrollableBanner() {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _bannerItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _bannerItems[index];
          return Container(
            width: 270,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [item['start'] as Color, item['end'] as Color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item['end'] as Color).withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickSearchSkeleton() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        6,
        (index) => _skeletonBox(
          width: 70 + ((index % 3) * 22).toDouble(),
          height: 30,
          radius: 999,
        ),
      ),
    );
  }

  Widget _buildResultSkeletonList() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _skeletonBox(width: 36, height: 36, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(
                      width: double.infinity,
                      height: 12,
                    ),
                    const SizedBox(height: 6),
                    _skeletonBox(width: 180, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({
    double? width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.yellow[50],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.yellow[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.orange[800],
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _searchController.text = title;
          _onSearchChanged(title);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.grey[700]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_west, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}


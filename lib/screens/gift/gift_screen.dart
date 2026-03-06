import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../profile/view_profile_screen.dart';
import 'gift_history_screen.dart';
import 'rewards_screen.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<dynamic> _users = [];
  bool _isLoading = true;
  bool _isRefreshingUsers = false;
  Timer? _searchDebounce;
  String _lastUsersQuery = '';
  String _lastUsersFilter = '';
  int _usersRequestId = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll(initial: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({
    bool showFullLoader = false,
    bool force = false,
  }) async {
    final query = _searchController.text.trim();
    final filter = _selectedFilter.trim();
    if (!force && query == _lastUsersQuery && filter == _lastUsersFilter) {
      return;
    }
    _lastUsersQuery = query;
    _lastUsersFilter = filter;
    final requestId = ++_usersRequestId;

    setState(() {
      if (showFullLoader || _users.isEmpty) {
        _isLoading = true;
        _isRefreshingUsers = false;
      } else {
        _isRefreshingUsers = true;
      }
    });

    try {
      final response = await ApiService.getGiftUsers(
        search: query,
        filter: filter,
        forceRefresh: force,
      );
      if (!mounted || requestId != _usersRequestId) return;

      if (response['error'] == null && response['users'] != null) {
        setState(() {
          _users = response['users'];
          _isLoading = false;
          _isRefreshingUsers = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
          _isRefreshingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!mounted || requestId != _usersRequestId) return;
      setState(() {
        _isLoading = false;
        _isRefreshingUsers = false;
      });
    }
  }

  Future<void> _refreshAll({bool initial = false}) async {
    await Future.wait([_loadUsers(showFullLoader: initial, force: true)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Send Gift',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GiftHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 350),
                        () => _loadUsers(),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All'),
                      const SizedBox(width: 8),
                      _filterChip('Friends'),
                      const SizedBox(width: 8),
                      _filterChip('Recent'),
                      const SizedBox(width: 8),
                      _filterChip('Top Players'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading && _users.isEmpty
                ? _buildUsersSkeletonList()
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: Column(
                      children: [
                        if (_isRefreshingUsers)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _userCard(
                                  userId: user['id'] ?? '',
                                  name: user['name'] ?? 'User',
                                  username: user['username'] ?? '@user',
                                  avatar: user['avatar'],
                                  level: user['level'] ?? 'Beginner',
                                  isOnline: user['isOnline'] ?? false,
                                ),
                              );
                            },
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

  Widget _buildUsersSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _skeletonBox(
                  width: 56,
                  height: 56,
                  radius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(width: 150, height: 14),
                      const SizedBox(height: 8),
                      _skeletonBox(width: 90, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _skeletonBox(
                  width: 48,
                  height: 48,
                  radius: 12,
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _loadUsers(force: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black87 : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _userCard({
    required String userId,
    required String name,
    required String username,
    String? avatar,
    required String level,
    required bool isOnline,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewProfileScreen(userId: userId)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(14),
                    image: (avatar != null && avatar.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(avatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (avatar == null || avatar.isEmpty)
                      ? Icon(Icons.person, size: 28, color: Colors.yellow[700])
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green[500],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Send Gift Button
            InkWell(
              onTap: () {
                _showGiftDialog(userId, name);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: Colors.pink[600],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftDialog(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftBottomSheet(
        userId: userId,
        userName: userName,
        onGiftSent: () {
          // Refresh wallet balance
          Provider.of<UserProvider>(context, listen: false).loadProfile();
          Provider.of<UserProvider>(context, listen: false).loadWalletBalance();
        },
      ),
    );
  }
}

class GiftBottomSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback onGiftSent;

  const GiftBottomSheet({
    super.key,
    required this.userId,
    required this.userName,
    required this.onGiftSent,
  });

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  double _selectedAmount = 50;
  String _selectedSourceBalance = 'added';
  bool _isLoadingBalances = true;
  double _withdrawableBalance = 0;
  double _addedBalance = 0;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  final List<double> _quickAmounts = [10, 50, 100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    _loadGiftBalanceSources();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadGiftBalanceSources() async {
    setState(() => _isLoadingBalances = true);
    try {
      final response = await ApiService.getGiftBalanceSources();
      if (!mounted) return;
      if (response['error'] == null) {
        setState(() {
          _withdrawableBalance = ((response['withdrawableBalance'] ?? 0) as num)
              .toDouble();
          _addedBalance = ((response['addedBalance'] ?? 0) as num).toDouble();
          _isLoadingBalances = false;
        });
      } else {
        setState(() => _isLoadingBalances = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBalances = false);
    }
  }

  Future<void> _sendGift() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final response = await ApiService.sendGift(
        recipientId: widget.userId,
        amount: _selectedAmount,
        sourceBalance: _selectedSourceBalance,
        message: _messageController.text,
      );

      if (!mounted) return;

      if (response['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'].toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSending = false;
        });
        return;
      }

      Navigator.pop(context);
      widget.onGiftSent();
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send gift: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[400]!, Colors.purple[400]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Gift',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'to ${widget.userName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Balance Source Selection
                  Text(
                    'Select Source Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingBalances)
                    Row(
                      children: [
                        Expanded(child: _balanceSourceSkeleton()),
                        const SizedBox(width: 10),
                        Expanded(child: _balanceSourceSkeleton()),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _sourceTile(
                            title: 'Added',
                            subtitle: 'Rs ${_addedBalance.toStringAsFixed(2)}',
                            value: 'added',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sourceTile(
                            title: 'Withdrawable',
                            subtitle:
                                'Rs ${_withdrawableBalance.toStringAsFixed(2)}',
                            value: 'withdrawable',
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Amount Selection
                  Text(
                    'Select Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAmounts.map((amount) {
                      final isSelected = _selectedAmount == amount;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAmount = amount;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.yellow[700]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.yellow[700]!
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                size: 16,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rs ${amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Message
                  Text(
                    'Add Message (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendGift,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black87,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Rs ${_selectedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _sourceTile({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = _selectedSourceBalance == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedSourceBalance = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey[300]!,
            width: 1.3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.green[800] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceSourceSkeleton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 90,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gift Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your gift has been sent to ${widget.userName}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



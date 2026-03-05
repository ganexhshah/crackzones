import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'data/shop_catalog.dart';
import 'models/shop_models.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/shop_notifications_screen.dart';
import 'screens/shop_policies_screen.dart';
import 'screens/shop_support_screen.dart';
import 'screens/shop_wallet_screen.dart';
import 'screens/store_home_view.dart';
import 'widgets/shop_bottom_navbar.dart';
import 'widgets/shop_header.dart';

class GameShopScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const GameShopScreen({super.key, this.initialCategory, this.initialQuery});

  @override
  State<GameShopScreen> createState() => _GameShopScreenState();
}

class _GameShopScreenState extends State<GameShopScreen> {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _openedInitialFilter = false;

  String _profileName = 'Player';
  String _profileEmail = '';
  String? _profileAvatar;

  final List<Map<String, dynamic>> _cart = [
    {'id': 'C-1', 'item': 'Free Fire Diamonds', 'amountCoins': 50000},
  ];

  late final List<ShopOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _buildMockOrders();
    _loadProfile();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController.text = _query;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openInitialFilteredListIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShopOrder> _buildMockOrders() {
    final ff = ShopCatalog.products.first;
    final pubg = ShopCatalog.products[1];
    return [
      ShopOrder(
        orderId: 'ORD-101',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        product: ff,
        pack: ff.packs[0],
        inputs: const {'Free Fire UID': '123456789', 'Server': 'Global'},
        fee: 0,
        total: ff.packs[0].price,
        paymentMethod: 'eSewa',
        status: OrderStatus.processing,
      ),
      ShopOrder(
        orderId: 'ORD-100',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        product: pubg,
        pack: pubg.packs[0],
        inputs: const {'PUBG Player ID': '99887766', 'Region': 'Asia'},
        fee: 0,
        total: pubg.packs[0].price,
        paymentMethod: 'Khalti',
        status: OrderStatus.completed,
      ),
    ];
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.getProfile();
    if (!mounted) return;

    if (response['error'] == null && response['user'] is Map) {
      final user = Map<String, dynamic>.from(response['user'] as Map);
      setState(() {
        _profileName = (user['name'] ?? 'Player').toString();
        _profileEmail = (user['email'] ?? '').toString();
        _profileAvatar = user['avatar']?.toString();
      });
    }
  }

  void _openInitialFilteredListIfNeeded() {
    if (_openedInitialFilter) return;
    final initialCategory = widget.initialCategory?.trim() ?? '';
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialCategory.isEmpty && initialQuery.isEmpty) return;

    _openedInitialFilter = true;
    final category = _mapCategory(initialCategory);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          category: category,
          initialQuery: initialQuery.isEmpty ? null : initialQuery,
        ),
      ),
    );
  }

  ShopCategory _mapCategory(String raw) {
    final val = raw.toLowerCase();
    if (val.contains('gift')) return ShopCategory.giftCards;
    if (val.contains('sub')) return ShopCategory.subscriptions;
    return ShopCategory.gameTopups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            const ShopHeader(),
            Expanded(child: _buildTabBody()),
          ],
        ),
      ),
      bottomNavigationBar: ShopBottomNavbar(
        currentIndex: _currentTab,
        onChanged: (i) => setState(() => _currentTab = i),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case 1:
        return _ordersTab();
      case 2:
        return _cartTab();
      case 3:
        return _accountTab();
      case 0:
      default:
        return StoreHomeView(
          search: _query,
          searchController: _searchController,
          onSearch: (v) => setState(() => _query = v.trim()),
          onOpenCategory: (category) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  category: category,
                  initialQuery: _query.isEmpty ? null : _query,
                ),
              ),
            );
          },
          onOpenProduct: (product) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          },
        );
    }
  }

  Widget _ordersTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'My Orders',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._orders.map((order) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'Rs ${order.total}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Order ${order.orderId}'),
                Text('Status: ${orderStatusLabel(order.status)}'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(order: order),
                        ),
                      );
                    },
                    child: const Text('Track Order'),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _cartTab() {
    final total = _cart.fold<int>(
      0,
      (sum, item) => sum + ((item['amountCoins'] as num?)?.toInt() ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'My Cart',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._cart.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (item['item'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${item['amountCoins']}'),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              if (ShopCatalog.products.isEmpty) return;
              final p = ShopCatalog.products.first;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p),
                ),
              );
            },
            child: const Text('Checkout'),
          ),
        ),
      ],
    );
  }

  Widget _accountTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'My Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (_profileAvatar != null && _profileAvatar!.isNotEmpty)
                    ? NetworkImage(_profileAvatar!)
                    : null,
                child: (_profileAvatar == null || _profileAvatar!.isEmpty)
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                _profileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(_profileEmail.isEmpty ? 'No email' : _profileEmail),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _accountMenuTile(
          'Wallet',
          Icons.account_balance_wallet_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopWalletScreen()),
          ),
        ),
        _accountMenuTile(
          'Notifications',
          Icons.notifications_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopNotificationsScreen()),
          ),
        ),
        _accountMenuTile(
          'Help / Support',
          Icons.support_agent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopSupportScreen()),
          ),
        ),
        _accountMenuTile(
          'Policies',
          Icons.description_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopPoliciesScreen()),
          ),
        ),
      ],
    );
  }

  Widget _accountMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        tileColor: Colors.white,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

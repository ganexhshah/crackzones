import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/account_restricted_screen.dart';
import '../../services/in_app_popup_notification_service.dart';
import '../../widgets/custom_navbar.dart';
import '../custom_match/custom_match_home_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../more/more_screen.dart';
import '../tournament/tournament_screen.dart';
import '../wallet/wallet_screen.dart';

class AppShellScreen extends StatefulWidget {
  final int initialIndex;

  const AppShellScreen({super.key, this.initialIndex = 0});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _currentIndex;

  late final List<Widget> _tabs = [
    const DashboardScreen(showBottomNav: false),
    const TournamentScreen(showBottomNav: false, showBackButton: false),
    const CustomMatchHomeScreen(showBottomNav: false),
    const WalletScreen(showBottomNav: false, showBackButton: false),
    const MoreScreen(showBottomNav: false, showBackButton: false),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _guardRestrictedAccount();
      InAppPopupNotificationService.instance.showLatestPopupIfNeeded(context);
    });
  }

  Future<void> _guardRestrictedAccount() async {
    final profile = await ApiService.getProfile();
    if (!mounted) return;
    final status = profile['accountStatus'];
    if (status is Map<String, dynamic>) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccountRestrictedScreen(accountStatus: status),
        ),
        (route) => false,
      );
      return;
    }
    final error = (profile['error'] ?? '').toString().toLowerCase();
    if (error.contains('blocked') || error.contains('suspend')) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccountRestrictedScreen(
            accountStatus: {
              'status': error.contains('suspend') ? 'SUSPENDED' : 'BLOCKED',
              'reason': profile['error'] ?? 'Restricted by admin',
              'canRequestUnblock': true,
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        managedByParent: true,
        onTap: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}


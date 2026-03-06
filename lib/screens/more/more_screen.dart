import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_navbar.dart';
import '../activities/activities_screen.dart';
import '../auth/login_screen.dart';
import '../custom_match/custom_match_reports_screen.dart';
import '../wallet/wallet_reports_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';

class MoreScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const MoreScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final int _currentIndex = 4;
  bool _showMenuSections = true;

  Future<void> _refreshMore() async {
    await context.read<UserProvider>().loadProfile();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMore,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        if (_showMenuSections) ...[
                          _buildMenuSection('Account', [
                            {
                              'icon': Icons.person_outline,
                              'title': 'Edit Profile',
                              'subtitle': 'Update your information',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.security,
                              'title': 'Privacy & Security',
                              'subtitle': 'Manage your privacy settings',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacySecurityScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.local_activity_outlined,
                              'title': 'Activities',
                              'subtitle':
                                  'View your recent wallet and game activities',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ActivitiesScreen(),
                                ),
                              ),
                            },
                          ]),
                          SizedBox(height: 16),
                          _buildMenuSection('Support', [
                            {
                              'icon': Icons.help_outline,
                              'title': 'Help & Support',
                              'subtitle': 'Get help with your account',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.flag_outlined,
                              'title': 'Match Reports',
                              'subtitle':
                                  'View your submitted custom match reports',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CustomMatchReportsScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.account_balance_wallet_outlined,
                              'title': 'Wallet Reports',
                              'subtitle': 'View your wallet report tickets',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WalletReportsScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.description_outlined,
                              'title': 'Terms & Conditions',
                              'subtitle': 'Read our terms',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.privacy_tip_outlined,
                              'title': 'Privacy Policy',
                              'subtitle': 'Read our privacy policy',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              ),
                            },
                          ]),
                          SizedBox(height: 16),
                          _buildMenuSection('App', [
                            {
                              'icon': Icons.info_outline,
                              'title': 'About',
                              'subtitle': 'Version 1.0.0',
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.share,
                              'title': 'Share App',
                              'subtitle': 'Share with friends',
                              'onTap': () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Share functionality coming soon!',
                                    ),
                                  ),
                                );
                              },
                            },
                            {
                              'icon': Icons.star_outline,
                              'title': 'Rate Us',
                              'subtitle': 'Rate us on Play Store',
                              'onTap': () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening Play Store...'),
                                  ),
                                );
                              },
                            },
                          ]),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              'Menu sections are hidden by filter.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        SizedBox(height: 24),
                        _buildLogoutButton(),
                        SizedBox(height: 20),
                      ],
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
                if (index != 4) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      height: kToolbarHeight,
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          SizedBox(width: 8),
          Text(
            'More',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(
              _showMenuSections ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showMenuSections ? Colors.yellow[700] : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _showMenuSections = !_showMenuSections;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final profile = userProvider.profile;
        final name = profile?['name'] ?? 'User';
        final email = profile?['email'] ?? '';
        final avatar = profile?['avatar'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow[100]!, Colors.yellow[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.yellow[200]!, width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.yellow[700],
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? const Icon(Icons.person, color: Colors.white, size: 35)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile?['isVerified'] == true
                              ? 'Verified'
                              : 'Pro Player',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return _buildMenuItem(
                item['icon'] as IconData,
                item['title'] as String,
                item['subtitle'] as String,
                isLast,
                item['onTap'] as VoidCallback,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    bool isLast,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.grey[700], size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirmed == true && mounted) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            await authProvider.logout();

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        icon: Icon(Icons.logout, color: Colors.red[600]),
        label: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red[600],
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red[300]!, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

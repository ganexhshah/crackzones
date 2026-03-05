import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'navigation/app_shell_screen.dart';
import 'auth/account_restricted_screen.dart';
import 'auth/login_screen.dart';
import 'profile/complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restored = await authProvider.restoreSession();
    if (!mounted) return;

    if (restored) {
      final complete = await ApiService.isProfileComplete();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              complete ? const AppShellScreen() : const CompleteProfileScreen(),
        ),
      );
      return;
    }

    if (authProvider.accountStatus != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccountRestrictedScreen(
            accountStatus: authProvider.accountStatus!,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/Red Simple Modern Typographic G Letter Logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'crackzone',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'account_restricted_screen.dart';
import '../navigation/app_shell_screen.dart';
import '../profile/complete_profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red[600] : Colors.green[600],
      ),
    );
  }

  Future<void> _routeAfterAuth() async {
    final complete = await ApiService.isProfileComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            complete ? const AppShellScreen() : const CompleteProfileScreen(),
      ),
    );
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please fill all fields', error: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _showMessage('Login successful');
      await _routeAfterAuth();
    } else if (mounted) {
      if (authProvider.accountStatus != null ||
          (authProvider.error ?? '').toLowerCase().contains('blocked') ||
          (authProvider.error ?? '').toLowerCase().contains('suspend')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountRestrictedScreen(
              accountStatus: authProvider.accountStatus ??
                  {
                    'status': (authProvider.error ?? '')
                            .toLowerCase()
                            .contains('suspend')
                        ? 'SUSPENDED'
                        : 'BLOCKED',
                    'reason': authProvider.error ?? 'Restricted by admin',
                    'canRequestUnblock': true,
                  },
              email: _emailController.text.trim(),
            ),
          ),
        );
        return;
      }
      _showMessage(authProvider.error ?? 'Incorrect email or password', error: true);
    }
  }

  void _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleSignIn();

    if (success && mounted) {
      _showMessage('Google login successful');
      await _routeAfterAuth();
    } else if (mounted) {
      if (authProvider.accountStatus != null ||
          (authProvider.error ?? '').toLowerCase().contains('blocked') ||
          (authProvider.error ?? '').toLowerCase().contains('suspend')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountRestrictedScreen(
              accountStatus: authProvider.accountStatus ??
                  {
                    'status': (authProvider.error ?? '')
                            .toLowerCase()
                            .contains('suspend')
                        ? 'SUSPENDED'
                        : 'BLOCKED',
                    'reason': authProvider.error ?? 'Restricted by admin',
                    'canRequestUnblock': true,
                  },
            ),
          ),
        );
        return;
      }
      _showMessage(authProvider.error ?? 'Google sign in failed', error: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: authProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Text(
                              'crackzone',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow[700],
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[600],
                              ),
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.yellow[700]!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey[600],
                              ),
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.yellow[700]!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.g_mobiledata,
                                  size: 24,
                                  color: Colors.red,
                                ),
                              ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Don\'t have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(
                                        color: Colors.yellow[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

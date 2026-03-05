import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../services/in_app_chat_popup_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _accountStatus;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get accountStatus => _accountStatus;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _setupTokenRefreshListener();
  }

  void _setupTokenRefreshListener() {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (_user != null) {
          // Only register if user is logged in
          try {
            await ApiService.registerPushToken(
              token: newToken,
              platform: _pushPlatform(),
            );
            print('AuthProvider: Token refresh registered successfully');
          } catch (e) {
            print('AuthProvider: Token refresh registration failed: $e');
          }
        }
      });
    } catch (e) {
      // Messaging can be unavailable depending on browser/environment.
      print('AuthProvider: Push token refresh listener not available: $e');
    }
  }

  String _pushPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }

  Future<void> _registerPushTokenForCurrentUser() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        print('AuthProvider: FCM token null/empty, skipping register');
        return;
      }
      final res = await ApiService.registerPushToken(
        token: fcmToken,
        platform: _pushPlatform(),
      );
      print('AuthProvider: registerPushToken response: $res');
    } catch (_) {
      // Keep auth flow uninterrupted if push registration fails.
      print('AuthProvider: registerPushToken failed');
    }
  }

  Future<bool> restoreSession() async {
    _isLoading = true;
    _error = null;
    _accountStatus = null;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = await ApiService.getProfile();
      if (profile['error'] != null || profile['user'] == null) {
        _accountStatus = profile['accountStatus'] is Map<String, dynamic>
            ? profile['accountStatus'] as Map<String, dynamic>
            : null;
        await ApiService.clearToken();
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = profile['user'];
      await _registerPushTokenForCurrentUser();
      await InAppChatPopupService.instance.reconnect();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      await ApiService.clearToken();
      _user = null;
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    String? phone,
    String? name,
  }) async {
    print('AuthProvider: Starting signup for $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signup(
        email: email,
        password: password,
        phone: phone,
        name: name,
      );

      print('AuthProvider: Signup result: $result');

      if (result['error'] != null) {
        _error = result['error'];
        _accountStatus = result['accountStatus'] is Map<String, dynamic>
            ? result['accountStatus'] as Map<String, dynamic>
            : null;
        _isLoading = false;
        notifyListeners();
        print('AuthProvider: Signup error: $_error');
        return false;
      }

      _isLoading = false;
      _accountStatus = null;
      notifyListeners();
      print('AuthProvider: Signup successful');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Signup exception: $e');
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    _isLoading = true;
    _error = null;
    _accountStatus = null;
    notifyListeners();

    try {
      final result = await ApiService.verifyOtp(email: email, otp: otp);

      if (result['error'] != null) {
        _error = result['error'];
        _accountStatus = result['accountStatus'] is Map<String, dynamic>
            ? result['accountStatus'] as Map<String, dynamic>
            : null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = result['user'];
      _accountStatus = null;
      await _registerPushTokenForCurrentUser();
      await InAppChatPopupService.instance.reconnect();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    print('AuthProvider: Starting login for $email');
    _isLoading = true;
    _error = null;
    _accountStatus = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email: email, password: password);

      print('AuthProvider: Login result: $result');

      if (result['error'] != null) {
        _error = result['error'];
        _accountStatus = result['accountStatus'] is Map<String, dynamic>
            ? result['accountStatus'] as Map<String, dynamic>
            : null;
        _isLoading = false;
        notifyListeners();
        print('AuthProvider: Login error: $_error');
        return false;
      }

      _user = result['user'];
      _accountStatus = null;
      await _registerPushTokenForCurrentUser();
      await InAppChatPopupService.instance.reconnect();
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Login successful');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Login exception: $e');
      return false;
    }
  }

  Future<bool> googleSignIn() async {
    _isLoading = true;
    _error = null;
    _accountStatus = null;
    notifyListeners();

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (result == null || result['error'] != null) {
        _error = result?['error'] ?? 'Sign in cancelled';
        _accountStatus = result?['accountStatus'] is Map<String, dynamic>
            ? result!['accountStatus'] as Map<String, dynamic>
            : null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = result['user'];
      _accountStatus = null;
      await _registerPushTokenForCurrentUser();
      await InAppChatPopupService.instance.reconnect();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (result['user'] != null) {
        _user = result['user'];
        await InAppChatPopupService.instance.reconnect();
        notifyListeners();
      }
    } catch (e) {
      print('Load profile error: $e');
    }
  }

  Future<void> logout() async {
    await GoogleAuthService.signOut();
    InAppChatPopupService.instance.dispose();
    _user = null;
    _accountStatus = null;
    notifyListeners();
  }
}

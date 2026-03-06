import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GoogleAuthService {
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['openid', 'email'],
    clientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
    serverClientId:
        _googleServerClientId.isEmpty ? null : _googleServerClientId,
  );

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    if (kIsWeb && _googleWebClientId.trim().isEmpty) {
      return {'error': 'Google web client ID is not configured.'};
    }
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Failed to get Google token');
      }

      final result = await ApiService.googleSignIn(
        idToken: idToken,
        accessToken: accessToken,
      );
      return result;
    } on PlatformException catch (e) {
      final detail = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (detail.contains('10') ||
          detail.contains('developer_error') ||
          detail.contains('clientconfigurationerror')) {
        return {
          'error':
              'Google Sign-In is not configured for this Play Store build. Please update Play signing SHA keys in Firebase.',
        };
      }
      if (detail.contains('canceled') || detail.contains('cancelled')) {
        return {'error': 'Sign in cancelled'};
      }
      if (kDebugMode) {
        debugPrint('Google Sign In Platform Error: code=${e.code}, message=${e.message}');
      }
      return {'error': 'Google sign in failed (${e.code})'};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Sign In Error: $e');
      }
      final message = e.toString();
      if (message.contains('people.googleapis.com') ||
          message.contains('People API')) {
        return {
          'error':
              'Google People API is disabled for this project. Enable People API in Google Cloud and retry after a few minutes.',
        };
      }
      return {'error': 'Google sign in failed: ${e.toString()}'};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await ApiService.clearToken();
  }
}


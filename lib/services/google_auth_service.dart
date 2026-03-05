import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GoogleAuthService {
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '678569739060-g59eu4uo402cmbactl80b4b7b9pti7qm.apps.googleusercontent.com',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['openid', 'email', 'profile'],
    clientId: _googleWebClientId,
    serverClientId:
        '678569739060-g59eu4uo402cmbactl80b4b7b9pti7qm.apps.googleusercontent.com',
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
      print('Google Sign In Platform Error: code=${e.code}, message=${e.message}');
      return {'error': 'Google sign in failed (${e.code})'};
    } catch (e) {
      print('Google Sign In Error: $e');
      return {'error': 'Google sign in failed: ${e.toString()}'};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await ApiService.clearToken();
  }
}

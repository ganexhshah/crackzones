import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _ApiCacheEntry {
  const _ApiCacheEntry({
    required this.data,
    required this.expiresAt,
  });

  final Map<String, dynamic> data;
  final DateTime expiresAt;
}

class ApiService {
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _localBaseUrl = 'http://192.168.18.13:3001/api';
  static const List<String> _reportFallbackBaseUrls = [
    'http://192.168.18.13:3001/api',
    'http://10.0.2.2:3001/api',
    'http://127.0.0.1:3001/api',
  ];
  static const String _productionBaseUrl = 'https://app.crackzones.xyz/api';
  static final Map<String, _ApiCacheEntry> _responseCache = {};
  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;
    if (kDebugMode) return _localBaseUrl;
    return _appEnv.toLowerCase() == 'prod' ? _productionBaseUrl : _localBaseUrl;
  }

  static String get baseUrlV1 => '$baseUrl/v1';
  static const Duration timeout = Duration(seconds: 60);

  static bool _shouldRetryOnLocalFallback(Map<String, dynamic> result) {
    final error = (result['error'] ?? '').toString().toLowerCase();
    return error.contains('server error 404') ||
        error.contains('non-json response') ||
        error.contains('unexpected response format');
  }

  static bool _isConnectionError(Map<String, dynamic> result) {
    final error = (result['error'] ?? '').toString().toLowerCase();
    return error.contains('cannot connect to server') ||
        error.contains('network connection') ||
        error.contains('socketexception');
  }

  static bool _shouldTryAlternateBase(Map<String, dynamic> result) {
    return _shouldRetryOnLocalFallback(result) || _isConnectionError(result);
  }

  static Future<Map<String, dynamic>> _retryReportRequestOnFallbacks({
    required Map<String, dynamic> primary,
    required Future<Map<String, dynamic>> Function(String apiBaseUrl) perform,
  }) async {
    if (!_shouldTryAlternateBase(primary)) return primary;

    final tried = <String>{baseUrl};
    for (final candidate in _reportFallbackBaseUrls) {
      if (tried.contains(candidate)) continue;
      tried.add(candidate);
      final result = await perform(candidate);
      if (_shouldTryAlternateBase(result)) continue;
      return result;
    }
    return primary;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, dynamic>> _handleRequest(
    Future<http.Response> Function() request, {
    String? debugUrl,
  }) async {
    try {
      if (debugUrl != null) {
        print('API Request: $debugUrl');
      }
      final response = await request().timeout(timeout);
      print('Response status: ${response.statusCode}');
      if (response.statusCode >= 400) {
        print('Response URL: ${response.request?.url}');
      }
      print('Response body: ${response.body}');

      final contentType = response.headers['content-type'] ?? '';
      final isJson = contentType.toLowerCase().contains('application/json');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isJson) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return {
          'error':
              'Unexpected response format from server (expected JSON, got $contentType).',
        };
      } else {
        if (isJson) {
          final error = jsonDecode(response.body);
          if (error is Map<String, dynamic>) {
            return {
              ...error,
              'statusCode': response.statusCode,
              'error': error['error'] ?? 'Request failed',
            };
          }
          return {'error': 'Request failed', 'statusCode': response.statusCode};
        }
        final shortBody = response.body.length > 120
            ? '${response.body.substring(0, 120)}...'
            : response.body;
        return {
          'error':
              'Server error ${response.statusCode}. Non-JSON response received: $shortBody',
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return {
        'error': 'Cannot connect to server. Check your network connection.',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return {'error': 'Connection timeout. Server is not responding.'};
    } catch (e) {
      print('Error: $e');
      return {'error': 'An error occurred: ${e.toString()}'};
    }
  }

  static String _cacheKey(String endpoint, [Map<String, String>? query]) {
    if (query == null || query.isEmpty) return endpoint;
    final sorted = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '$endpoint?$qs';
  }

  static Map<String, dynamic> _cloneMap(Map<String, dynamic> input) {
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(input)) as Map);
  }

  static Map<String, dynamic>? _getCachedResponse(String key) {
    final entry = _responseCache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _responseCache.remove(key);
      return null;
    }
    return _cloneMap(entry.data);
  }

  static void _setCachedResponse(
    String key,
    Map<String, dynamic> value, {
    required Duration ttl,
  }) {
    if (value['error'] != null) return;
    _responseCache[key] = _ApiCacheEntry(
      data: _cloneMap(value),
      expiresAt: DateTime.now().add(ttl),
    );
  }

  static void _invalidateCachePrefix(String prefix) {
    final keys = _responseCache.keys
        .where((key) => key.startsWith(prefix))
        .toList();
    for (final key in keys) {
      _responseCache.remove(key);
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? phone,
    String? name,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'phone': phone,
          'name': name,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ),
    );

    if (result['token'] != null) {
      await saveToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );

    if (result['token'] != null) {
      await saveToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final result = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      ),
    );

    if (result['token'] != null) {
      await saveToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> requestUnblock({
    required String email,
    String? message,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/auth/unblock-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getUserProfileById(String userId) async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/user/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static bool isProfileCompleteFromUser(Map<String, dynamic> user) {
    final gameIdsRaw = user['gameIds'];
    if (gameIdsRaw is! List) return false;
    for (final item in gameIdsRaw) {
      if (item is Map) {
        final gameId = (item['gameId'] ?? '').toString().trim();
        if (RegExp(r'^\d{7,10}$').hasMatch(gameId)) {
          return true;
        }
      }
    }
    return false;
  }

  static Future<bool> isProfileComplete() async {
    final profileRes = await getProfile();
    if (profileRes['error'] != null || profileRes['user'] is! Map) {
      return false;
    }
    final user = Map<String, dynamic>.from(profileRes['user'] as Map);
    return isProfileCompleteFromUser(user);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'phone': phone}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getWalletBalance() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/wallet/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getWalletLedger({int limit = 50}) async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/v1/wallet/ledger?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getTournaments() async {
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/tournaments'),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  static Future<Map<String, dynamic>> getTournamentDetails(
    String tournamentId,
  ) async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getTournamentLobby(
    String tournamentId,
  ) async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId/lobby'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getTournamentAlerts() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/tournaments/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> joinTournament(
    String tournamentId,
  ) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/tournaments/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tournamentId': tournamentId}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getGameIds() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/user/game-ids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> saveGameId({
    required String gameName,
    required String gameId,
    String? inGameName,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/user/game-ids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameName': gameName,
          'gameId': gameId,
          if (inGameName != null && inGameName.isNotEmpty)
            'inGameName': inGameName,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> deleteGameId(String id) async {
    final token = await getToken();
    return _handleRequest(
      () => http.delete(
        Uri.parse('$baseUrl/user/game-ids?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> completeProfileSetup({
    required String gameName,
    required String gameId,
    required String inGameName,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/user/profile-setup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameName': gameName,
          'gameId': gameId,
          'inGameName': inGameName,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final token = await getToken();
    return _handleRequest(
      () => http.delete(
        Uri.parse('$baseUrl/user/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getPaymentQR(String method) async {
    final normalizedMethod = method.trim().toLowerCase();
    final uri = Uri.parse(
      '$baseUrl/wallet/payment-qr',
    ).replace(queryParameters: {'method': normalizedMethod});

    return _handleRequest(
      () => http.get(uri, headers: {'Content-Type': 'application/json'}),
    );
  }

  static Future<Map<String, dynamic>> submitDeposit({
    required double amount,
    required String method,
    required String screenshotPath,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/wallet/deposit'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['amount'] = amount.toString();
      request.fields['method'] = method;
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', screenshotPath),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Deposit response status: ${response.statusCode}');
      print('Deposit response body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Deposit error: $e');
      return {'error': 'Deposit failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitWithdrawal({
    required double amount,
    required String method,
    required String accountName,
    required String accountNumber,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/wallet/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'accountName': accountName,
          'accountNumber': accountNumber,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getTransactions() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/wallet/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> uploadAvatar(String imagePath) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/upload-avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Upload error: $e');
      return {'error': 'Upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCustomMatches({
    bool mine = false,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/custom-matches',
    ).replace(queryParameters: mine ? {'mine': '1'} : null);
    return _handleRequest(
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> createCustomMatch({
    required String roomType,
    required String mode,
    required int rounds,
    required double entryFee,
    required bool throwableLimit,
    required bool characterSkill,
    required bool allSkillsAllowed,
    required List<String> selectedSkills,
    required bool headshotOnly,
    required bool gunAttributes,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/custom-matches'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomType': roomType,
          'mode': mode,
          'rounds': rounds,
          'entryFee': entryFee,
          'throwableLimit': throwableLimit,
          'characterSkill': characterSkill,
          'allSkillsAllowed': allSkillsAllowed,
          'selectedSkills': selectedSkills,
          'headshotOnly': headshotOnly,
          'gunAttributes': gunAttributes,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getCreatedCustomMatches() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/custom-matches/created'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> joinCustomMatch(String matchId) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/custom-matches/$matchId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> reviewCustomMatchJoinRequest({
    required String matchId,
    required String requestId,
    required bool accepted,
    String? roomId,
    String? roomPassword,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse(
          '$baseUrl/custom-matches/$matchId/requests/$requestId/review',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': accepted ? 'accept' : 'reject',
          if (accepted) 'roomId': roomId,
          if (accepted) 'roomPassword': roomPassword,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> cancelCustomMatch(String matchId) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/custom-matches/$matchId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> uploadCustomMatchProofImage(
    String imagePath,
  ) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/custom-matches/proof-upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', imagePath),
      );
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Proof upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitCustomMatchResult({
    required String matchId,
    required String winnerUserId,
    required String proofUrl,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/custom-matches/$matchId/result'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'winnerUserId': winnerUserId, 'proofUrl': proofUrl}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getAdminCustomMatchResults({
    String status = 'PENDING',
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/admin/custom-matches/results',
    ).replace(queryParameters: {'status': status});
    return _handleRequest(
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> reviewAdminCustomMatchResult({
    required String submissionId,
    required bool approved,
    String? note,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/admin/custom-matches/results/$submissionId/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': approved ? 'accept' : 'reject',
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getCustomMatchHistory() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/custom-matches/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/user/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getSystemSettings() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> search(String query) async {
    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/search',
    ).replace(queryParameters: {'q': query});
    return _handleRequest(
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getCustomMatchAlerts() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/custom-matches/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> getBroadcastNotifications() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/notifications/broadcast'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> dismissBroadcastPopup(
    String broadcastId,
  ) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/notifications/broadcast/dismiss'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'broadcastId': broadcastId}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getNotifications({
    bool unreadOnly = false,
    int take = 50,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: {'unreadOnly': unreadOnly ? '1' : '0', 'take': '$take'},
    );
    return _handleRequest(
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> markNotificationRead({
    String? notificationId,
    bool markAll = false,
    bool clearAll = false,
  }) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/notifications/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (notificationId != null && notificationId.isNotEmpty)
            'notificationId': notificationId,
          'markAll': markAll,
          'clearAll': clearAll,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> registerPushToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    final authToken = await getToken();
    if (authToken == null || authToken.isEmpty) {
      return {'error': 'Not authenticated'};
    }

    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/user/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': platform,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        }),
      ),
    );
  }

  // Gift APIs
  static Future<Map<String, dynamic>> getGiftUsers({
    String search = '',
    String filter = 'All',
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    final query = {
      if (search.isNotEmpty) 'search': search,
      'filter': filter,
    };
    final cacheKey = _cacheKey('gift/users', query);
    if (!forceRefresh) {
      final cached = _getCachedResponse(cacheKey);
      if (cached != null) return cached;
    }

    final uri = Uri.parse('$baseUrl/gift/users').replace(queryParameters: query);
    final response = await _handleRequest(
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _setCachedResponse(
      cacheKey,
      response,
      ttl: const Duration(seconds: 30),
    );
    return response;
  }

  static Future<Map<String, dynamic>> sendGift({
    required String recipientId,
    required double amount,
    required String sourceBalance,
    String? message,
  }) async {
    final token = await getToken();
    final response = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/gift/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipientId': recipientId,
          'amount': amount,
          'sourceBalance': sourceBalance,
          if (message != null && message.isNotEmpty) 'message': message,
        }),
      ),
    );
    if (response['error'] == null) {
      _invalidateCachePrefix('gift/users');
      _invalidateCachePrefix('gift/balance-sources');
      _invalidateCachePrefix('gift/history');
    }
    return response;
  }

  static Future<Map<String, dynamic>> getGiftBalanceSources({
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    const cacheKey = 'gift/balance-sources';
    if (!forceRefresh) {
      final cached = _getCachedResponse(cacheKey);
      if (cached != null) return cached;
    }

    final response = await _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/gift/balance-sources'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _setCachedResponse(
      cacheKey,
      response,
      ttl: const Duration(seconds: 20),
    );
    return response;
  }

  static Future<Map<String, dynamic>> getGiftHistory() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/gift/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  // Reward APIs
  static Future<Map<String, dynamic>> getRewardsStatus({
    bool forceRefresh = false,
  }) async {
    final token = await getToken();
    const cacheKey = 'rewards/status';
    if (!forceRefresh) {
      final cached = _getCachedResponse(cacheKey);
      if (cached != null) return cached;
    }

    final response = await _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/rewards/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _setCachedResponse(
      cacheKey,
      response,
      ttl: const Duration(seconds: 30),
    );
    return response;
  }

  static Future<Map<String, dynamic>> claimDailyReward() async {
    final token = await getToken();
    final response = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/rewards/daily-claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response['error'] == null) {
      _invalidateCachePrefix('rewards/status');
    }
    return response;
  }

  static Future<Map<String, dynamic>> spinRewardWheel({
    String? clientSeed,
  }) async {
    final token = await getToken();
    final response = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/rewards/spin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (clientSeed != null && clientSeed.isNotEmpty)
            'clientSeed': clientSeed,
        }),
      ),
    );
    if (response['error'] == null) {
      _invalidateCachePrefix('rewards/status');
    }
    return response;
  }

  static Future<Map<String, dynamic>> withdrawRewardCoins({
    required int coins,
  }) async {
    final token = await getToken();
    final response = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/rewards/withdraw-coins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'coins': coins}),
      ),
    );
    if (response['error'] == null) {
      _invalidateCachePrefix('rewards/status');
    }
    return response;
  }

  static Future<Map<String, dynamic>> getRewardWithdrawHistory() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/rewards/withdraw-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  // -------------------------------
  // v1 Custom Match APIs
  // -------------------------------
  static Future<Map<String, String>> _authJsonHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getV1Matches({
    String? status,
    int limit = 50,
  }) async {
    final headers = await _authJsonHeaders();
    final normalizedStatus = status?.trim();
    final shouldSendStatus =
        normalizedStatus != null &&
        normalizedStatus.isNotEmpty &&
        normalizedStatus.toLowerCase() != 'null' &&
        normalizedStatus.toLowerCase() != 'undefined';
    final uri = Uri.parse('$baseUrlV1/matches').replace(
      queryParameters: {
        if (shouldSendStatus) 'status': normalizedStatus,
        'limit': '$limit',
      },
    );
    return _handleRequest(() => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> getV1MatchDetails(String matchId) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () =>
          http.get(Uri.parse('$baseUrlV1/matches/$matchId'), headers: headers),
    );
  }

  static Future<Map<String, dynamic>> getV1MatchOdds() async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.get(Uri.parse('$baseUrlV1/matches/odds'), headers: headers),
    );
  }

  static Future<Map<String, dynamic>> createV1Match({
    required double entryFee,
    String gameName = 'Free Fire',
    String matchType = '1v1',
    String roomType = 'CUSTOM_ROOM',
    int rounds = 7,
    int defaultCoin = 9950,
    bool throwableLimit = false,
    bool characterSkill = false,
    bool allSkillsAllowed = true,
    List<String> selectedSkills = const [],
    bool headshotOnly = true,
    bool gunAttributes = false,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches'),
        headers: headers,
        body: jsonEncode({
          'entryFee': entryFee,
          'gameName': gameName,
          'roomType': roomType,
          'matchType': matchType,
          'rounds': rounds,
          'defaultCoin': defaultCoin,
          'throwableLimit': throwableLimit,
          'characterSkill': characterSkill,
          'allSkillsAllowed': allSkillsAllowed,
          'selectedSkills': selectedSkills,
          'headshotOnly': headshotOnly,
          'gunAttributes': gunAttributes,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> joinV1Match(String matchId) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/join'),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> cancelV1Match(String matchId) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/cancel'),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> acceptV1MatchRequest(
    String matchId,
  ) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/accept'),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> rejectV1MatchRequest(
    String matchId,
  ) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/reject'),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> submitV1MatchRoom({
    required String matchId,
    required String roomId,
    required String roomPassword,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/room'),
        headers: headers,
        body: jsonEncode({'roomId': roomId, 'roomPassword': roomPassword}),
      ),
    );
  }

  static Future<Map<String, dynamic>> submitV1MatchResult({
    required String matchId,
    required String winnerUserId,
    String? note,
    String? proofUrl,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/result'),
        headers: headers,
        body: jsonEncode({
          'winnerUserId': winnerUserId,
          if (note != null && note.isNotEmpty) 'note': note,
          if (proofUrl != null && proofUrl.isNotEmpty) 'proofUrl': proofUrl,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> reportV1MatchIssue({
    required String matchId,
    required String reason,
    String? details,
    String? proofUrl,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/report'),
        headers: headers,
        body: jsonEncode({
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
          if (proofUrl != null && proofUrl.isNotEmpty) 'proofUrl': proofUrl,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1CustomMatchReports() async {
    final headers = await _authJsonHeaders();
    final primary = await _handleRequest(
      () => http.get(
        Uri.parse('$baseUrlV1/reports/custom-matches'),
        headers: headers,
      ),
    );
    return _retryReportRequestOnFallbacks(
      primary: primary,
      perform: (apiBaseUrl) => _handleRequest(
        () => http.get(
          Uri.parse('$apiBaseUrl/v1/reports/custom-matches'),
          headers: headers,
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1AdminCustomMatchReports({
    String status = 'ALL',
  }) async {
    final headers = await _authJsonHeaders();
    final uri = Uri.parse(
      '$baseUrlV1/admin/reports/custom-matches',
    ).replace(queryParameters: {'status': status});
    return _handleRequest(() => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> reviewV1AdminCustomMatchReport({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.patch(
        Uri.parse('$baseUrlV1/admin/reports/custom-matches/$reportId'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> createV1WalletReport({
    required String transactionId,
    required String reason,
    String? details,
  }) async {
    final headers = await _authJsonHeaders();
    final primary = await _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/wallet/reports'),
        headers: headers,
        body: jsonEncode({
          'transactionId': transactionId,
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        }),
      ),
    );
    return _retryReportRequestOnFallbacks(
      primary: primary,
      perform: (apiBaseUrl) => _handleRequest(
        () => http.post(
          Uri.parse('$apiBaseUrl/v1/wallet/reports'),
          headers: headers,
          body: jsonEncode({
            'transactionId': transactionId,
            'reason': reason,
            if (details != null && details.isNotEmpty) 'details': details,
          }),
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1WalletReports() async {
    final headers = await _authJsonHeaders();
    final primary = await _handleRequest(
      () => http.get(Uri.parse('$baseUrlV1/wallet/reports'), headers: headers),
    );
    return _retryReportRequestOnFallbacks(
      primary: primary,
      perform: (apiBaseUrl) => _handleRequest(
        () => http.get(
          Uri.parse('$apiBaseUrl/v1/wallet/reports'),
          headers: headers,
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1AdminWalletReports({
    String status = 'ALL',
  }) async {
    final headers = await _authJsonHeaders();
    final uri = Uri.parse(
      '$baseUrlV1/admin/wallet/reports',
    ).replace(queryParameters: {'status': status});
    return _handleRequest(() => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> reviewV1AdminWalletReport({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.patch(
        Uri.parse('$baseUrlV1/admin/wallet/reports/$reportId'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1MatchLedger(String matchId) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrlV1/matches/$matchId/ledger'),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> getV1Wallet() async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.get(Uri.parse('$baseUrlV1/wallet'), headers: headers),
    );
  }

  static Future<Map<String, dynamic>> getV1WalletLedger({
    int limit = 50,
  }) async {
    final headers = await _authJsonHeaders();
    final uri = Uri.parse(
      '$baseUrlV1/wallet/ledger',
    ).replace(queryParameters: {'limit': '$limit'});
    return _handleRequest(() => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> getV1MatchChat({
    required String matchId,
    String? cursor,
    int limit = 30,
  }) async {
    final headers = await _authJsonHeaders();
    final uri = Uri.parse('$baseUrlV1/matches/$matchId/chat').replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': '$limit',
      },
    );
    return _handleRequest(() => http.get(uri, headers: headers));
  }

  static Future<Map<String, dynamic>> sendV1MatchChat({
    required String matchId,
    required String message,
  }) async {
    final headers = await _authJsonHeaders();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrlV1/matches/$matchId/chat'),
        headers: headers,
        body: jsonEncode({'message': message}),
      ),
    );
  }

  static Future<Map<String, dynamic>> uploadV1MatchProofImage(
    String imagePath,
  ) async {
    final token = await getToken();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlV1/matches/proof-upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', imagePath),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      return {'error': parsed['error'] ?? 'Proof upload failed'};
    } catch (e) {
      return {'error': 'Proof upload failed: ${e.toString()}'};
    }
  }
}

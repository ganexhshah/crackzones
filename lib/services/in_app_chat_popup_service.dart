import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/custom_match/custom_match_chat_screen.dart';
import 'api_service.dart';
import 'custom_match_socket_service.dart';

class InAppChatPopupService {
  InAppChatPopupService._();

  static final InAppChatPopupService instance = InAppChatPopupService._();

  StreamSubscription<MatchSocketEvent>? _socketSub;
  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  final Set<String> _seenMessageIds = <String>{};
  String _currentUserId = '';
  bool _initialized = false;

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _navigatorKey = navigatorKey;
    _messengerKey = messengerKey;

    if (_initialized) return;
    _initialized = true;

    await _refreshCurrentUserId();
    await CustomMatchSocketService.instance.connect();

    _socketSub = CustomMatchSocketService.instance.events.listen(_onSocketEvent);
  }

  Future<void> _refreshCurrentUserId() async {
    final profile = await ApiService.getProfile();
    if (profile['user'] is Map) {
      _currentUserId = ((profile['user'] as Map)['id'] ?? '').toString();
    }
  }

  void _onSocketEvent(MatchSocketEvent event) {
    if (event.type == 'socket.connected' || event.type == 'socket.reconnected') {
      _refreshCurrentUserId();
      return;
    }
    if (event.type != 'chat.message') return;

    final messageMap = event.payload['message'] is Map
        ? Map<String, dynamic>.from(event.payload['message'] as Map)
        : <String, dynamic>{};
    final matchId = (event.payload['matchId'] ?? '').toString();
    final messageId = (messageMap['id'] ?? '').toString();
    final senderId = (messageMap['senderId'] ?? '').toString();
    final text = (messageMap['message'] ?? '').toString().trim();

    if (matchId.isEmpty || messageId.isEmpty || text.isEmpty) return;
    if (_seenMessageIds.contains(messageId)) return;
    _seenMessageIds.add(messageId);
    if (_currentUserId.isNotEmpty && senderId == _currentUserId) return;

    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Text(
          text.length > 80 ? '${text.substring(0, 80)}...' : text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _openQuickChat(matchId),
        ),
      ),
    );
  }

  void _openQuickChat(String matchId) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: CustomMatchChatScreen(
          isEnabled: true,
          matchId: matchId,
        ),
      ),
    );
  }

  Future<void> reconnect() async {
    if (!_initialized && _navigatorKey != null && _messengerKey != null) {
      await init(
        navigatorKey: _navigatorKey!,
        messengerKey: _messengerKey!,
      );
      return;
    }
    await _refreshCurrentUserId();
    await CustomMatchSocketService.instance.connect();
  }

  void dispose() {
    _socketSub?.cancel();
    _socketSub = null;
    CustomMatchSocketService.instance.dispose();
    _initialized = false;
    _seenMessageIds.clear();
    _currentUserId = '';
  }
}

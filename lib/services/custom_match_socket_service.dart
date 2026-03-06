import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';

class MatchSocketEvent {
  final String type;
  final String? matchId;
  final Map<String, dynamic> payload;

  const MatchSocketEvent({
    required this.type,
    required this.matchId,
    required this.payload,
  });
}

class CustomMatchSocketService {
  CustomMatchSocketService._();

  static final CustomMatchSocketService instance = CustomMatchSocketService._();

  static const List<String> _eventNames = <String>[
    'match.created',
    'match.requested',
    'match.accepted',
    'match.rejected',
    'match.expired',
    'match.room_ready',
    'match.completed',
    'wallet.updated',
    'chat.message',
    'chat.typing',
  ];

  io.Socket? _socket;
  final StreamController<MatchSocketEvent> _events =
      StreamController<MatchSocketEvent>.broadcast();

  Stream<MatchSocketEvent> get events => _events.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket != null) {
      if (_socket!.connected != true) {
        _socket!.connect();
      }
      return;
    }

    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return;

    final socketBase = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final socket = io.io(
      socketBase,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth(<String, dynamic>{'token': 'Bearer $token'})
          .build(),
    );

    for (final eventName in _eventNames) {
      socket.on(eventName, (payload) {
        final map = payload is Map
            ? Map<String, dynamic>.from(payload)
            : <String, dynamic>{};
        final matchIdRaw = map['matchId'] ?? map['id'];
        final matchId = matchIdRaw?.toString();
        _events.add(
          MatchSocketEvent(type: eventName, matchId: matchId, payload: map),
        );
      });
    }

    socket.onConnect((_) {
      _events.add(
        const MatchSocketEvent(
          type: 'socket.connected',
          matchId: null,
          payload: <String, dynamic>{},
        ),
      );
    });

    socket.onReconnect((_) {
      _events.add(
        const MatchSocketEvent(
          type: 'socket.reconnected',
          matchId: null,
          payload: <String, dynamic>{},
        ),
      );
    });

    socket.onDisconnect((_) {
      _events.add(
        const MatchSocketEvent(
          type: 'socket.disconnected',
          matchId: null,
          payload: <String, dynamic>{},
        ),
      );
    });

    _socket = socket;
    socket.connect();
  }

  void subscribeMatch(String matchId) {
    if (matchId.trim().isEmpty) return;
    _socket?.emit('match:subscribe', <String, dynamic>{'matchId': matchId});
  }

  void unsubscribeMatch(String matchId) {
    if (matchId.trim().isEmpty) return;
    _socket?.emit('match:unsubscribe', <String, dynamic>{'matchId': matchId});
  }

  void emitTyping({
    required String matchId,
    required bool isTyping,
  }) {
    if (matchId.trim().isEmpty) return;
    _socket?.emit(
      'chat:typing',
      <String, dynamic>{'matchId': matchId, 'isTyping': isTyping},
    );
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}


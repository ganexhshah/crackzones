import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/custom_match_socket_service.dart';
import 'custom_match_components.dart';

class CustomMatchChatScreen extends StatefulWidget {
  final bool isEnabled;
  final String matchId;

  const CustomMatchChatScreen({
    super.key,
    required this.isEnabled,
    required this.matchId,
  });

  @override
  State<CustomMatchChatScreen> createState() => _CustomMatchChatScreenState();
}

class _CustomMatchChatScreenState extends State<CustomMatchChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = <String>{};
  String? _myUserId;
  bool _loading = true;
  bool _socketConnected = false;
  StreamSubscription<MatchSocketEvent>? _socketSub;
  bool _isTypingEmitted = false;
  String? _typingUserId;
  DateTime? _typingAt;
  Timer? _typingTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _stopTyping();
    CustomMatchSocketService.instance.unsubscribeMatch(widget.matchId);
    _socketSub?.cancel();
    _typingTimer?.cancel();
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() => _loading = true);
    final profileRes = await ApiService.getProfile();
    final chatRes = await ApiService.getV1MatchChat(matchId: widget.matchId, limit: 50);
    if (!mounted) return;

    if (chatRes['error'] != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatRes['error'].toString())),
      );
      return;
    }

    final userId = (profileRes['user'] is Map)
        ? ((profileRes['user'] as Map)['id'] ?? '').toString()
        : '';

    final rows = (chatRes['messages'] is List)
        ? List<Map<String, dynamic>>.from(
            (chatRes['messages'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];

    rows.sort(
      (a, b) => (a['createdAt'] ?? '').toString().compareTo((b['createdAt'] ?? '').toString()),
    );

    setState(() {
      _myUserId = userId;
      _messages
        ..clear()
        ..addAll(rows);
      _messageIds
        ..clear()
        ..addAll(
          rows
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
      _loading = false;
    });

    await _initSocket();
  }

  Future<void> _refreshChat() async {
    final chatRes = await ApiService.getV1MatchChat(matchId: widget.matchId, limit: 50);
    if (!mounted) return;

    if (chatRes['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatRes['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rows = (chatRes['messages'] is List)
        ? List<Map<String, dynamic>>.from(
            (chatRes['messages'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];

    rows.sort(
      (a, b) => (a['createdAt'] ?? '').toString().compareTo((b['createdAt'] ?? '').toString()),
    );

    setState(() {
      _messages
        ..clear()
        ..addAll(rows);
      _messageIds
        ..clear()
        ..addAll(
          rows
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
    });
  }

  Future<void> _initSocket() async {
    if (_socketSub != null || _myUserId == null || _myUserId!.isEmpty) return;
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return;

    await CustomMatchSocketService.instance.connect();
    CustomMatchSocketService.instance.subscribeMatch(widget.matchId);
    setState(() {
      _socketConnected = CustomMatchSocketService.instance.isConnected;
    });

    _socketSub = CustomMatchSocketService.instance.events.listen((event) {
      if (!mounted) return;
      if (event.type == 'socket.connected' || event.type == 'socket.reconnected') {
        setState(() => _socketConnected = true);
        CustomMatchSocketService.instance.subscribeMatch(widget.matchId);
        return;
      }
      if (event.type == 'socket.disconnected') {
        setState(() => _socketConnected = false);
        return;
      }
      if (event.type == 'chat.message') {
        if ((event.payload['matchId'] ?? '').toString() != widget.matchId) return;
        final message = event.payload['message'] is Map
            ? Map<String, dynamic>.from(event.payload['message'] as Map)
            : <String, dynamic>{};
        if (message.isEmpty) return;
        _appendMessage(message);
        return;
      }
      if (event.type == 'chat.typing') {
        if ((event.payload['matchId'] ?? '').toString() != widget.matchId) return;
        final userId = (event.payload['userId'] ?? '').toString();
        if (userId.isEmpty || userId == _myUserId) return;
        final isTyping = event.payload['isTyping'] == true;
        setState(() {
          _typingUserId = isTyping ? userId : null;
          _typingAt = isTyping ? DateTime.now() : null;
        });
        _typingTimer?.cancel();
        if (isTyping) {
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            final last = _typingAt;
            if (last != null &&
                DateTime.now().difference(last) >= const Duration(seconds: 3)) {
              setState(() => _typingUserId = null);
            }
          });
        }
      }
    });
  }

  void _appendMessage(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    if (id.isNotEmpty && _messageIds.contains(id)) return;
    setState(() {
      _messages.add(row);
      _messages.sort(
        (a, b) =>
            (a['createdAt'] ?? '').toString().compareTo(
              (b['createdAt'] ?? '').toString(),
            ),
      );
      if (id.isNotEmpty) _messageIds.add(id);
    });
    
    // Auto-scroll to bottom when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _emitTyping(bool isTyping) {
    if (!_socketConnected) return;
    CustomMatchSocketService.instance.emitTyping(
      matchId: widget.matchId,
      isTyping: isTyping,
    );
  }

  void _onInputChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText && !_isTypingEmitted) {
      _isTypingEmitted = true;
      _emitTyping(true);
    }
    if (!hasText && _isTypingEmitted) {
      _stopTyping();
      return;
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1200), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTypingEmitted) {
      _emitTyping(false);
      _isTypingEmitted = false;
    }
    _typingTimer?.cancel();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Optimistic UI update - add message immediately
    final tempMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'message': text,
      'senderId': _myUserId ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'pending': true,
    };
    
    _appendMessage(tempMessage);
    _ctrl.clear();
    _stopTyping();

    final res = await ApiService.sendV1MatchChat(matchId: widget.matchId, message: text);
    
    if (!mounted) return;
    
    setState(() => _isSending = false);

    if (res['error'] != null) {
      // Remove temp message on error
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempMessage['id']);
        _messageIds.remove(tempMessage['id']);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Replace temp message with real one from server
    final row = (res['message'] is Map)
        ? Map<String, dynamic>.from(res['message'] as Map)
        : <String, dynamic>{};
    
    if (row.isNotEmpty) {
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempMessage['id']);
        _messageIds.remove(tempMessage['id']);
      });
      _appendMessage(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Chat'), backgroundColor: Colors.white),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Chat unlocks after match is CONFIRMED.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Match Chat'),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _socketConnected ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _socketConnected ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Text(
                  _socketConnected ? 'Live' : 'Sync',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _socketConnected ? Colors.green[800] : Colors.orange[900],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshChat,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start the conversation!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Pull down to refresh',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshChat,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final row = _messages[i];
                            final senderId = (row['senderId'] ?? '').toString();
                            final isPending = row['pending'] == true;
                            return Opacity(
                              opacity: isPending ? 0.6 : 1.0,
                              child: ChatBubble(
                                isMine: senderId.isNotEmpty && senderId == _myUserId,
                                text: (row['message'] ?? '').toString(),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (_typingUserId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Opponent is typing...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _onInputChanged,
                      decoration: InputDecoration(
                        hintText: 'Type message',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: _isSending ? Colors.grey[300] : Colors.yellow[700],
                      foregroundColor: _isSending ? Colors.grey[600] : Colors.black87,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


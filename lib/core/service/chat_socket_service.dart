import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';

class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  final _pusher = PusherChannelsFlutter.getInstance();
  Future<void>? _connectFuture;
  bool _wasDisconnected = false;
  int _counter = 0;

  // channelName → { listenerId → callback }
  final Map<String, Map<String, void Function(Map<String, dynamic>)>>
      _listeners = {};

  // ── Local unread tracking (independent of backend unread_count) ──
  final Map<int, int> _unreadCounts = {};
  final _unreadController = StreamController<int>.broadcast();

  /// Fires after the socket reconnects following a drop. Pusher re-subscribes
  /// channels automatically, but events missed while offline are lost —
  /// listeners must refetch their data when this fires.
  final _reconnectController = StreamController<void>.broadcast();

  Stream<int> get unreadStream => _unreadController.stream;
  Stream<void> get reconnectStream => _reconnectController.stream;
  int get totalUnread => _unreadCounts.values.fold(0, (a, b) => a + b);
  int unreadFor(int conversationId) => _unreadCounts[conversationId] ?? 0;

  void resetUnread(int conversationId) {
    if (_unreadCounts.containsKey(conversationId)) {
      _unreadCounts.remove(conversationId);
      _unreadController.add(totalUnread);
    }
  }

  /// Safe to call concurrently: all callers share the same connect attempt.
  Future<void> connect() => _connectFuture ??= _doConnect();

  Future<void> _doConnect() async {
    try {
      await _pusher.init(
        apiKey: '28fa324491dc6542b0fb',
        cluster: 'ap2',
        useTLS: true,
        onAuthorizer: _authorizer,
        onConnectionStateChange: _onConnectionStateChange,
        onError: (message, code, error) =>
            debugPrint('[Pusher] error $code: $message | $error'),
      );
      await _pusher.connect();
    } catch (e) {
      // Allow the next connect() call to retry instead of caching the failure.
      _connectFuture = null;
      rethrow;
    }
  }

  void _onConnectionStateChange(dynamic current, dynamic previous) {
    debugPrint('[Pusher] state: $previous → $current');
    final state = '$current'.toUpperCase();
    if (state == 'CONNECTED') {
      if (_wasDisconnected) {
        _wasDisconnected = false;
        _reconnectController.add(null);
      }
    } else if (state == 'DISCONNECTED' || state == 'RECONNECTING') {
      _wasDisconnected = true;
    }
  }

  Future<dynamic> _authorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
      final token = mytoken();
      final response = await Dio().post(
        ApiEndPoint.broadcastAuth,
        data: FormData.fromMap({
          'channel_name': channelName,
          'socket_id': socketId,
        }),
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );
      return response.data;
    } catch (e) {
      debugPrint('[Pusher] Auth FAILED: $e');
      rethrow;
    }
  }

  /// Registers a listener for messages on a conversation channel.
  /// Returns a [listenerId] that must be passed to [removeMessageListener].
  Future<String> addMessageListener(
    int conversationId,
    void Function(Map<String, dynamic> data) callback,
  ) async {
    await connect();
    final channel = 'private-conversation.$conversationId';
    final listenerId = '${++_counter}';

    if (!_listeners.containsKey(channel)) {
      _listeners[channel] = {};
      try {
        await _pusher.subscribe(
          channelName: channel,
          onEvent: (event) => _dispatch(channel, conversationId, event),
        );
      } catch (e) {
        _listeners.remove(channel);
        rethrow;
      }
    }
    _listeners[channel]![listenerId] = callback;
    return listenerId;
  }

  void removeMessageListener(int conversationId, String listenerId) {
    final channel = 'private-conversation.$conversationId';
    _listeners[channel]?.remove(listenerId);
    if (_listeners[channel]?.isEmpty ?? false) {
      _pusher.unsubscribe(channelName: channel);
      _listeners.remove(channel);
    }
  }

  void _dispatch(String channel, int conversationId, PusherEvent event) {
    final name = event.eventName;
    if (name != 'MessageSent' &&
        name != 'App\\Events\\MessageSent' &&
        name != 'new-message') {
      return;
    }

    debugPrint('[Pusher] Event received → name: $name | data: ${event.data}');
    try {
      final raw = event.data;
      final outer = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final msgMap = outer['message'] is Map
          ? outer['message'] as Map<String, dynamic>
          : outer;

      // The channel echoes our own messages back — they must not count
      // as unread.
      if (!_isOwnMessage(msgMap)) {
        _unreadCounts[conversationId] =
            (_unreadCounts[conversationId] ?? 0) + 1;
        _unreadController.add(totalUnread);
      }

      for (final cb in List.from(_listeners[channel]?.values ?? [])) {
        cb(msgMap);
      }
    } catch (e) {
      debugPrint('[Pusher] Dispatch parse error: $e');
    }
  }

  bool _isOwnMessage(Map<String, dynamic> msgMap) {
    int? senderId;
    final sender = msgMap['sender'];
    if (sender is Map && sender['id'] is int) {
      senderId = sender['id'] as int;
    } else if (msgMap['sender_id'] is int) {
      senderId = msgMap['sender_id'] as int;
    }
    return senderId != null && senderId == myid();
  }

  /// Must be called on logout so the next user starts with a clean slate.
  Future<void> disconnect() async {
    _listeners.clear();
    _unreadCounts.clear();
    _unreadController.add(0);
    _wasDisconnected = false;
    _connectFuture = null;
    try {
      await _pusher.disconnect();
    } catch (e) {
      debugPrint('[Pusher] disconnect error: $e');
    }
  }
}

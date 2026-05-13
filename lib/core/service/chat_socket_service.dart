import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';

class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  final _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;
  int _counter = 0;

  // channelName → { listenerId → callback }
  final Map<String, Map<String, void Function(Map<String, dynamic>)>>
      _listeners = {};

  // ── Local unread tracking (independent of backend unread_count) ──
  final Map<int, int> _unreadCounts = {};
  final _unreadController = StreamController<int>.broadcast();

  Stream<int> get unreadStream => _unreadController.stream;
  int get totalUnread => _unreadCounts.values.fold(0, (a, b) => a + b);

  void resetUnread(int conversationId) {
    if (_unreadCounts.containsKey(conversationId)) {
      _unreadCounts.remove(conversationId);
      _unreadController.add(totalUnread);
    }
  }

  Future<void> connect() async {
    if (_initialized) return;
    await _pusher.init(
      apiKey: '28fa324491dc6542b0fb',
      cluster: 'ap2',
      useTLS: true,
      onAuthorizer: _authorizer,
      onConnectionStateChange: (current, previous) =>
          debugPrint('[Pusher] state: $previous → $current'),
      onError: (message, code, error) =>
          debugPrint('[Pusher] error $code: $message | $error'),
    );
    await _pusher.connect();
    _initialized = true;
  }

  Future<dynamic> _authorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = mytoken();
    final response = await Dio().post(
      ApiEndPoint.broadcastAuth,
      data: {'channel_name': channelName, 'socket_id': socketId},
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }),
    );
    return response.data;
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
      await _pusher.subscribe(
        channelName: channel,
        onEvent: (event) => _dispatch(channel, conversationId, event),
      );
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

    try {
      final raw = event.data;
      final outer = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final msgMap = outer['message'] is Map
          ? outer['message'] as Map<String, dynamic>
          : outer;

      // Increment local unread count for this conversation
      _unreadCounts[conversationId] =
          (_unreadCounts[conversationId] ?? 0) + 1;
      _unreadController.add(totalUnread);

      // Notify all registered listeners
      for (final cb in List.from(_listeners[channel]?.values ?? [])) {
        cb(msgMap);
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
    _listeners.clear();
    _unreadCounts.clear();
    _initialized = false;
  }
}

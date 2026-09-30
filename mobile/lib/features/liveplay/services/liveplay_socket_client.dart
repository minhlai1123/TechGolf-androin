import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/liveplay_models.dart';

abstract class ILivePlaySocketClient {
  Stream<LivePlayConnectionStatus> get statusStream;
  Stream<Map<String, dynamic>> get eventStream;
  LivePlayConnectionStatus get status;

  Future<void> connect(String wsUrl, {String? token});
  Future<void> joinRound(String roundId, {String? token});
  Future<void> leaveRound(String roundId);
  Future<void> sendScoreUpdate(Map<String, dynamic> scorePayload);
  void disconnect();
  void dispose();
}

class LivePlaySocketClient implements ILivePlaySocketClient {
  WebSocket? _socket;
  final StreamController<LivePlayConnectionStatus> _statusController =
      StreamController<LivePlayConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  LivePlayConnectionStatus _status = LivePlayConnectionStatus.disconnected;
  String? _currentWsUrl;
  String? _authToken;
  String? _activeRoundId;
  bool _isExplicitDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  @override
  Stream<LivePlayConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  @override
  LivePlayConnectionStatus get status => _status;

  void _setStatus(LivePlayConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  @override
  Future<void> connect(String wsUrl, {String? token}) async {
    _currentWsUrl = wsUrl;
    _authToken = token;
    _isExplicitDisconnect = false;
    _reconnectTimer?.cancel();

    _setStatus(
      _reconnectAttempts > 0
          ? LivePlayConnectionStatus.reconnecting
          : LivePlayConnectionStatus.connecting,
    );

    try {
      final uri = Uri.parse(wsUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      if (token != null) {
        queryParams['token'] = token;
      }
      final targetUri = uri.replace(queryParameters: queryParams);

      // Clean up previous socket if any
      await _cleanupSocket();

      final headers = <String, dynamic>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      _socket = await WebSocket.connect(
        targetUri.toString(),
        headers: headers,
      ).timeout(const Duration(seconds: 8));

      _reconnectAttempts = 0;
      _setStatus(LivePlayConnectionStatus.connected);

      _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      // If there was an active round, auto-join on reconnect
      if (_activeRoundId != null) {
        await joinRound(_activeRoundId!, token: _authToken);
      }
    } catch (e) {
      _setStatus(LivePlayConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      if (raw is String) {
        final Map<String, dynamic> data = jsonDecode(raw);
        if (!_eventController.isClosed) {
          _eventController.add(data);
        }
      }
    } catch (_) {}
  }

  void _onError(dynamic error) {
    _setStatus(LivePlayConnectionStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (!_isExplicitDisconnect) {
      _setStatus(LivePlayConnectionStatus.disconnected);
      _scheduleReconnect();
    } else {
      _setStatus(LivePlayConnectionStatus.disconnected);
    }
  }

  void _scheduleReconnect() {
    if (_isExplicitDisconnect || _currentWsUrl == null) return;

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Exponential backoff: 1s, 2s, 4s, up to 10s max
    final delaySeconds = (_reconnectAttempts <= 4) ? (1 << (_reconnectAttempts - 1)) : 10;

    _setStatus(LivePlayConnectionStatus.reconnecting);

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isExplicitDisconnect && _currentWsUrl != null) {
        connect(_currentWsUrl!, token: _authToken);
      }
    });
  }

  @override
  Future<void> joinRound(String roundId, {String? token}) async {
    _activeRoundId = roundId;
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      final payload = <String, dynamic>{'roundId': roundId};
      if (token != null) {
        payload['token'] = token;
      }
      final msg = jsonEncode({
        'event': 'liveplay:join',
        'data': payload,
      });
      _socket!.add(msg);
    }
  }

  @override
  Future<void> leaveRound(String roundId) async {
    _activeRoundId = null;
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      final msg = jsonEncode({
        'event': 'liveplay:leave',
        'data': {'roundId': roundId},
      });
      _socket!.add(msg);
    }
  }

  @override
  Future<void> sendScoreUpdate(Map<String, dynamic> scorePayload) async {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      final msg = jsonEncode({
        'event': 'score:update',
        'data': scorePayload,
      });
      _socket!.add(msg);
    }
  }

  Future<void> _cleanupSocket() async {
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (_) {}
      _socket = null;
    }
  }

  @override
  void disconnect() {
    _isExplicitDisconnect = true;
    _reconnectTimer?.cancel();
    _activeRoundId = null;
    _cleanupSocket();
    _setStatus(LivePlayConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _eventController.close();
  }
}

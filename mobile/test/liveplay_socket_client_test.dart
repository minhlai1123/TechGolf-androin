import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/liveplay/models/liveplay_models.dart';
import 'package:mobile/features/liveplay/services/liveplay_socket_client.dart';

class MockLivePlaySocketClient implements ILivePlaySocketClient {
  final StreamController<LivePlayConnectionStatus> _statusCtrl =
      StreamController<LivePlayConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _eventCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  LivePlayConnectionStatus _currentStatus = LivePlayConnectionStatus.disconnected;
  final List<String> joinedRounds = [];
  final List<String> leftRounds = [];
  final List<Map<String, dynamic>> sentScores = [];
  bool isDisconnected = false;

  @override
  Stream<LivePlayConnectionStatus> get statusStream => _statusCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventCtrl.stream;

  @override
  LivePlayConnectionStatus get status => _currentStatus;

  void emitStatus(LivePlayConnectionStatus newStatus) {
    _currentStatus = newStatus;
    _statusCtrl.add(newStatus);
  }

  void emitEvent(String event, Map<String, dynamic> data) {
    _eventCtrl.add({
      'event': event,
      'data': data,
    });
  }

  @override
  Future<void> connect(String wsUrl, {String? token}) async {
    emitStatus(LivePlayConnectionStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 10));
    emitStatus(LivePlayConnectionStatus.connected);
  }

  @override
  Future<void> joinRound(String roundId, {String? token}) async {
    joinedRounds.add(roundId);
  }

  @override
  Future<void> leaveRound(String roundId) async {
    leftRounds.add(roundId);
  }

  @override
  Future<void> sendScoreUpdate(Map<String, dynamic> scorePayload) async {
    sentScores.add(scorePayload);
  }

  @override
  void disconnect() {
    isDisconnected = true;
    emitStatus(LivePlayConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    _statusCtrl.close();
    _eventCtrl.close();
  }
}

void main() {
  group('LivePlay Socket Client Tests', () {
    late MockLivePlaySocketClient mockSocket;

    setUp(() {
      mockSocket = MockLivePlaySocketClient();
    });

    tearDown(() {
      mockSocket.dispose();
    });

    test('Mock socket transitions through connection lifecycle', () async {
      final statuses = <LivePlayConnectionStatus>[];
      final sub = mockSocket.statusStream.listen(statuses.add);

      expect(mockSocket.status, LivePlayConnectionStatus.disconnected);

      await mockSocket.connect('ws://localhost:3000/liveplay', token: 'jwt-token-123');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(statuses, [
        LivePlayConnectionStatus.connecting,
        LivePlayConnectionStatus.connected,
      ]);
      expect(mockSocket.status, LivePlayConnectionStatus.connected);

      mockSocket.disconnect();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(mockSocket.isDisconnected, isTrue);
      expect(mockSocket.status, LivePlayConnectionStatus.disconnected);

      await sub.cancel();
    });

    test('Mock socket joins and leaves round rooms', () async {
      await mockSocket.joinRound('round-101', token: 'jwt-token');
      expect(mockSocket.joinedRounds, contains('round-101'));

      await mockSocket.leaveRound('round-101');
      expect(mockSocket.leftRounds, contains('round-101'));
    });

    test('Mock socket sends score update and receives broadcast events', () async {
      final receivedEvents = <Map<String, dynamic>>[];
      final sub = mockSocket.eventStream.listen(receivedEvents.add);

      final scoreUpdate = {
        'roundId': 'round-101',
        'playerId': 'player-1',
        'holeId': 'hole-1',
        'grossScore': 4,
        'putts': 2,
        'penalties': 0,
      };

      await mockSocket.sendScoreUpdate(scoreUpdate);
      expect(mockSocket.sentScores, [scoreUpdate]);

      // Simulate incoming event from server
      mockSocket.emitEvent('score:updated', {
        'roundId': 'round-101',
        'score': scoreUpdate,
      });

      // Allow microtask to flush
      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedEvents.length, 1);
      expect(receivedEvents.first['event'], 'score:updated');
      expect(receivedEvents.first['data']['roundId'], 'round-101');

      await sub.cancel();
    });

    test('Mock socket handles reconnecting status stream', () async {
      final statuses = <LivePlayConnectionStatus>[];
      final sub = mockSocket.statusStream.listen(statuses.add);

      mockSocket.emitStatus(LivePlayConnectionStatus.reconnecting);
      mockSocket.emitStatus(LivePlayConnectionStatus.connected);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(statuses, [
        LivePlayConnectionStatus.reconnecting,
        LivePlayConnectionStatus.connected,
      ]);

      await sub.cancel();
    });
  });
}

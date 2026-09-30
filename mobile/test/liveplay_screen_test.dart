import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/liveplay/models/liveplay_models.dart';
import 'package:mobile/features/liveplay/screens/liveplay_screen.dart';
import 'package:mobile/features/liveplay/services/liveplay_socket_client.dart';
import 'package:mobile/features/rounds/models/round_models.dart';

class MockTestSocketClient implements ILivePlaySocketClient {
  final StreamController<LivePlayConnectionStatus> _statusCtrl =
      StreamController<LivePlayConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _eventCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  LivePlayConnectionStatus _currentStatus = LivePlayConnectionStatus.connected;
  final List<String> joinedRounds = [];
  final List<String> leftRounds = [];

  @override
  Stream<LivePlayConnectionStatus> get statusStream => _statusCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventCtrl.stream;

  @override
  LivePlayConnectionStatus get status => _currentStatus;

  void emitStatus(LivePlayConnectionStatus s) {
    _currentStatus = s;
    _statusCtrl.add(s);
  }

  void emitEvent(String event, Map<String, dynamic> data) {
    _eventCtrl.add({'event': event, 'data': data});
  }

  @override
  Future<void> connect(String wsUrl, {String? token}) async {
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
  Future<void> sendScoreUpdate(Map<String, dynamic> scorePayload) async {}

  @override
  void disconnect() {
    _currentStatus = LivePlayConnectionStatus.disconnected;
  }

  @override
  void dispose() {
    _statusCtrl.close();
    _eventCtrl.close();
  }
}

class MockTestApiClient extends ApiClient {
  final LivePlayStateModel? initialLivePlayState;
  final bool shouldThrow;

  MockTestApiClient({
    this.initialLivePlayState,
    this.shouldThrow = false,
  });

  @override
  Future<LivePlayStateModel> getLivePlayState(String roundId) async {
    if (shouldThrow) {
      throw Exception('Network connection failed');
    }
    if (initialLivePlayState != null) {
      return initialLivePlayState!;
    }
    throw Exception('No state');
  }

  @override
  String get livePlayWsUrl => 'ws://localhost:3000/liveplay';

  @override
  String? get authToken => 'mock-jwt-token';
}

void main() {
  group('LivePlayScreen Widget Tests', () {
    late LivePlayStateModel testState;

    setUp(() {
      testState = const LivePlayStateModel(
        roundId: 'round-101',
        courseName: 'Championship Golf Links',
        gameMode: GameMode.strokePlay,
        roundStatus: 'IN_PROGRESS',
        currentHole: 3,
        players: [
          RoundPlayerModel(
            id: 'p-1',
            roundId: 'round-101',
            playerName: 'Tiger Woods',
            playerOrder: 1,
          ),
          RoundPlayerModel(
            id: 'p-2',
            roundId: 'round-101',
            playerName: 'Rory McIlroy',
            playerOrder: 2,
          ),
        ],
        holes: [
          LivePlayHole(id: 'h-1', holeNumber: 1, par: 4, handicapIndex: 3),
          LivePlayHole(id: 'h-2', holeNumber: 2, par: 5, handicapIndex: 1),
          LivePlayHole(id: 'h-3', holeNumber: 3, par: 3, handicapIndex: 5),
        ],
        scores: [
          LivePlayScore(id: 's-1', playerId: 'p-1', holeId: 'h-1', grossScore: 4, putts: 2),
          LivePlayScore(id: 's-2', playerId: 'p-2', holeId: 'h-1', grossScore: 5, putts: 2),
        ],
        playerSummaries: [
          LivePlayPlayerSummary(
            playerId: 'p-1',
            playerName: 'Tiger Woods',
            playerOrder: 1,
            grossScore: 4,
            toPar: 0,
            thru: '1',
            holesCompleted: 1,
          ),
          LivePlayPlayerSummary(
            playerId: 'p-2',
            playerName: 'Rory McIlroy',
            playerOrder: 2,
            grossScore: 5,
            toPar: 1,
            thru: '1',
            holesCompleted: 1,
          ),
        ],
        leaderboard: {
          'standings': [
            {'playerId': 'p-1', 'rank': 1, 'toPar': 0, 'grossScore': 4},
            {'playerId': 'p-2', 'rank': 2, 'toPar': 1, 'grossScore': 5},
          ]
        },
      );
    });

    testWidgets('renders LivePlayScreen header, leaderboard and score matrix', (tester) async {
      final mockSocket = MockTestSocketClient();
      final mockApi = MockTestApiClient(initialLivePlayState: testState);

      await tester.pumpWidget(
        MaterialApp(
          home: LivePlayScreen(
            roundId: 'round-101',
            apiClient: mockApi,
            socketClient: mockSocket,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('LIVEPLAY'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget); // Connected badge

      // Check Header Card
      expect(find.text('Championship Golf Links'), findsOneWidget);
      expect(find.text('Stroke Play'), findsOneWidget);
      expect(find.text('Hole 3'), findsOneWidget);

      // Check Leaderboard Section
      expect(find.text('Realtime Leaderboard'), findsOneWidget);
      expect(find.text('Tiger Woods'), findsWidgets);
      expect(find.text('Rory McIlroy'), findsWidgets);
      expect(find.text('E'), findsWidgets); // Even par for Tiger
      expect(find.text('+1'), findsWidgets); // +1 for Rory

      // Check Hole Scores Matrix
      expect(find.text('Hole Scores (Live Sync)'), findsOneWidget);
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('H3'), findsOneWidget);
    });

    testWidgets('updates leaderboard dynamically upon receiving leaderboard:updated socket event', (tester) async {
      final mockSocket = MockTestSocketClient();
      final mockApi = MockTestApiClient(initialLivePlayState: testState);

      await tester.pumpWidget(
        MaterialApp(
          home: LivePlayScreen(
            roundId: 'round-101',
            apiClient: mockApi,
            socketClient: mockSocket,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rory makes eagle on hole 2 (-1 toPar total, taking lead)
      mockSocket.emitEvent('leaderboard:updated', {
        'currentHole': 4,
        'playerSummaries': [
          {
            'playerId': 'p-2',
            'playerName': 'Rory McIlroy',
            'playerOrder': 2,
            'grossScore': 8,
            'toPar': -1,
            'thru': '2',
            'holesCompleted': 2,
          },
          {
            'playerId': 'p-1',
            'playerName': 'Tiger Woods',
            'playerOrder': 1,
            'grossScore': 9,
            'toPar': 0,
            'thru': '2',
            'holesCompleted': 2,
          },
        ],
        'leaderboard': {
          'standings': [
            {'playerId': 'p-2', 'rank': 1, 'toPar': -1, 'grossScore': 8},
            {'playerId': 'p-1', 'rank': 2, 'toPar': 0, 'grossScore': 9},
          ],
        },
      });

      await tester.pumpAndSettle();

      // Rory is now -1
      expect(find.text('-1'), findsWidgets);
    });

    testWidgets('displays reconnecting banner when connection drops', (tester) async {
      final mockSocket = MockTestSocketClient();
      final mockApi = MockTestApiClient(initialLivePlayState: testState);

      await tester.pumpWidget(
        MaterialApp(
          home: LivePlayScreen(
            roundId: 'round-101',
            apiClient: mockApi,
            socketClient: mockSocket,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate connection drop to reconnecting
      mockSocket.emitStatus(LivePlayConnectionStatus.reconnecting);
      await tester.pumpAndSettle();

      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.text('Connection lost. Reconnecting to LivePlay...'), findsOneWidget);
    });

    testWidgets('renders error view and retry button on fetch failure', (tester) async {
      final mockSocket = MockTestSocketClient();
      final mockApi = MockTestApiClient(shouldThrow: true);

      await tester.pumpWidget(
        MaterialApp(
          home: LivePlayScreen(
            roundId: 'round-101',
            apiClient: mockApi,
            socketClient: mockSocket,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

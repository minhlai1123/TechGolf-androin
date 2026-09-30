import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/handicap/models/handicap_models.dart';
import 'package:mobile/features/handicap/screens/handicap_history_screen.dart';

class MockHandicapApiClient extends ApiClient {
  final HandicapCurrentModel mockHandicap;
  final List<ScoreDifferentialModel> mockDifferentials;
  final List<HandicapHistoryModel> mockHistory;
  bool recalculateTriggered = false;

  MockHandicapApiClient({
    required this.mockHandicap,
    required this.mockDifferentials,
    required this.mockHistory,
  });

  @override
  Future<HandicapCurrentModel> getCurrentHandicap() async => mockHandicap;

  @override
  Future<List<ScoreDifferentialModel>> getScoreDifferentials() async => mockDifferentials;

  @override
  Future<List<HandicapHistoryModel>> getHandicapHistory() async => mockHistory;

  @override
  Future<Map<String, dynamic>> recalculateHandicap() async {
    recalculateTriggered = true;
    return {'status': 'SUCCESS'};
  }
}

void main() {
  group('HandicapHistoryScreen Widget Tests', () {
    late MockHandicapApiClient mockClient;

    setUp(() {
      mockClient = MockHandicapApiClient(
        mockHandicap: const HandicapCurrentModel(
          userId: 'u1',
          handicapIndex: 14.2,
          isEstablished: true,
          roundsCount: 8,
          status: 'ESTABLISHED',
          message: 'Official WHS Handicap Index based on 8 rounds.',
        ),
        mockDifferentials: [
          ScoreDifferentialModel(
            id: 'd1',
            roundId: 'r1',
            courseName: 'Royal Golf Links',
            teeName: 'Blue Championship',
            grossScore: 85,
            adjustedGrossScore: 84,
            courseRating: 72.1,
            slopeRating: 128,
            pccAdjustment: 0.0,
            scoreDifferential: 10.5,
            playedAt: DateTime.parse('2026-09-25T10:00:00Z'),
          ),
        ],
        mockHistory: [
          HandicapHistoryModel(
            id: 'h1',
            previousHandicapIndex: 15.0,
            resultingHandicapIndex: 14.2,
            differentialsUsedCount: 2,
            roundsCount: 8,
            status: 'VALID',
            calculatedAt: DateTime.parse('2026-09-25T12:00:00Z'),
          ),
        ],
      );
    });

    testWidgets('renders handicap header card and score differentials list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HandicapHistoryScreen(apiClient: mockClient),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // Title & Header Card
      expect(find.text('WHS Handicap Index'), findsOneWidget);
      expect(find.text('INDEX'), findsOneWidget);
      expect(find.text('14.2'), findsOneWidget);
      expect(find.text('ESTABLISHED'), findsOneWidget);
      expect(find.text('8 eligible rounds'), findsOneWidget);

      // Differentials Tab Content
      expect(find.text('Royal Golf Links'), findsOneWidget);
      expect(find.text('Tee: Blue Championship'), findsOneWidget);
      expect(find.text('Diff: 10.5'), findsOneWidget);
      expect(find.text('Gross'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('AGS (Net DB)'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
    });

    testWidgets('switches to audit history tab and renders history items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HandicapHistoryScreen(apiClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      // Switch tab
      await tester.tap(find.text('Audit History'));
      await tester.pumpAndSettle();

      expect(find.text('Handicap Index: 14.2'), findsOneWidget);
      expect(find.textContaining('Rounds: 8 | Used: 2 diffs'), findsOneWidget);
    });

    testWidgets('recalculate button calls recalculateHandicap API', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HandicapHistoryScreen(apiClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recalculate WHS'), findsOneWidget);
      await tester.tap(find.text('Recalculate WHS'));
      await tester.pumpAndSettle();

      expect(mockClient.recalculateTriggered, true);
      expect(find.text('Handicap Index recalculated successfully!'), findsOneWidget);
    });
  });
}

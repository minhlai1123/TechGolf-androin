import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/handicap/models/handicap_models.dart';
import 'package:mobile/features/handicap/screens/handicap_history_screen.dart';
import 'package:mobile/features/statistics/models/statistics_models.dart';
import 'package:mobile/features/statistics/screens/stats_dashboard_screen.dart';
import 'package:mobile/features/strokes_gained/models/strokes_gained_models.dart';

class MockStatsApiClient extends ApiClient {
  final HandicapCurrentModel mockHandicap;
  final StatsOverviewModel mockOverview;
  final List<TrendPointModel> mockTrends;
  final StrokesGainedSummaryModel mockStrokesGained;
  final List<ScoreDifferentialModel> mockDifferentials;
  final List<HandicapHistoryModel> mockHistory;
  int? lastLimitRequested;

  MockStatsApiClient({
    required this.mockHandicap,
    required this.mockOverview,
    required this.mockTrends,
    required this.mockStrokesGained,
    this.mockDifferentials = const [],
    this.mockHistory = const [],
  });

  @override
  Future<HandicapCurrentModel> getCurrentHandicap() async => mockHandicap;

  @override
  Future<StatsOverviewModel> getStatsOverview({int? limit}) async {
    lastLimitRequested = limit;
    return mockOverview;
  }

  @override
  Future<List<TrendPointModel>> getStatsTrends({int? limit}) async => mockTrends;

  @override
  Future<StrokesGainedSummaryModel> getStrokesGained({String? roundId}) async => mockStrokesGained;

  @override
  Future<List<ScoreDifferentialModel>> getScoreDifferentials() async => mockDifferentials;

  @override
  Future<List<HandicapHistoryModel>> getHandicapHistory() async => mockHistory;
}

void main() {
  group('StatsDashboardScreen Widget Tests', () {
    late MockStatsApiClient mockClient;

    setUp(() {
      mockClient = MockStatsApiClient(
        mockHandicap: const HandicapCurrentModel(
          userId: 'u1',
          handicapIndex: 14.2,
          isEstablished: true,
          roundsCount: 8,
          status: 'ESTABLISHED',
          message: 'Official WHS Handicap Index based on 8 rounds.',
        ),
        mockOverview: const StatsOverviewModel(
          roundsPlayed: 8,
          totalHolesPlayed: 144,
          scoringAverage: 82.4,
          bestScore: 78,
          fir: FirModel(
            hitCount: 40,
            missLeftCount: 15,
            missRightCount: 15,
            totalOpportunities: 70,
            percentage: 57.1,
          ),
          gir: GirModel(
            hitCount: 45,
            missCount: 45,
            totalOpportunities: 90,
            percentage: 50.0,
          ),
          putts: PuttsModel(
            totalPutts: 160,
            puttsPerHole: 1.78,
            puttsPerGir: 1.65,
            onePuttsCount: 20,
            twoPuttsCount: 60,
            threeOrMorePuttsCount: 10,
            totalHolesWithPutts: 90,
          ),
          scrambling: ScramblingModel(
            successCount: 0,
            opportunitiesCount: 0,
            percentage: null,
            status: 'NO_OPPORTUNITIES',
            message: 'No missed greens data',
          ),
          parBreakdown: ParBreakdownModel(
            par3Average: 3.25,
            par4Average: 4.55,
            par5Average: 5.40,
          ),
          scoreDistribution: ScoreDistributionModel(
            eaglesOrBetter: 0,
            birdies: 5,
            pars: 45,
            bogeys: 30,
            doubleBogeys: 8,
            tripleOrWorse: 2,
          ),
        ),
        mockTrends: [
          TrendPointModel(
            roundId: 'r1',
            roundDate: DateTime.parse('2026-09-20T08:00:00Z'),
            courseName: 'Pebble Links',
            grossScore: 84,
            scoreDifferential: 11.2,
            firPercentage: 60.0,
            girPercentage: 55.0,
            totalPutts: 31,
          ),
        ],
        mockStrokesGained: const StrokesGainedSummaryModel(
          status: 'UNAVAILABLE',
          totalStrokesGained: null,
          categories: {
            'DRIVING': StrokesGainedCategoryModel(
              category: 'DRIVING',
              shotsCount: 28,
              strokesGained: null,
              status: 'UNAVAILABLE',
            ),
            'APPROACH': StrokesGainedCategoryModel(
              category: 'APPROACH',
              shotsCount: 36,
              strokesGained: null,
              status: 'UNAVAILABLE',
            ),
            'SHORT_GAME': StrokesGainedCategoryModel(
              category: 'SHORT_GAME',
              shotsCount: 16,
              strokesGained: null,
              status: 'UNAVAILABLE',
            ),
            'PUTTING': StrokesGainedCategoryModel(
              category: 'PUTTING',
              shotsCount: 64,
              strokesGained: null,
              status: 'UNAVAILABLE',
            ),
          },
          message:
              'Strokes Gained data unavailable: Benchmark reference table (PGA Tour / Mark Broadie) is not supplied in specification. Data cannot be faked with 0.00.',
        ),
      );
    });

    testWidgets('renders stats dashboard with handicap card, core metrics, and strokes gained banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsDashboardScreen(apiClient: mockClient),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Golf Performance & Stats'), findsOneWidget);

      // WHS Handicap Card
      expect(find.text('WHS HANDICAP INDEX'), findsOneWidget);
      expect(find.text('14.2'), findsOneWidget);
      expect(find.text('ESTABLISHED'), findsOneWidget);

      // Scoring Banner
      expect(find.text('Scoring Average'), findsOneWidget);
      expect(find.text('82.4'), findsOneWidget);
      expect(find.text('Best Score'), findsOneWidget);
      expect(find.text('78'), findsOneWidget);

      // FIR Card
      expect(find.text('Fairways (FIR)'), findsOneWidget);
      expect(find.text('57.1%'), findsOneWidget);
      expect(find.text('Par 3s excluded'), findsOneWidget);

      // GIR Card
      expect(find.text('Greens (GIR)'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);

      // Putts Card
      expect(find.text('Putting'), findsOneWidget);
      expect(find.text('1.78'), findsOneWidget);

      // Scrambling Card: Verifies 0 opportunities displays "No opportunities" chip, NOT fake 0.0%
      expect(find.text('Scrambling'), findsOneWidget);
      expect(find.text('No opportunities'), findsOneWidget);
      expect(find.text('No missed greens data'), findsOneWidget);

      // Performance Trends (Scroll down)
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Performance Trends'), findsOneWidget);
      expect(find.text('Pebble Links'), findsOneWidget);
      expect(find.text('Score: 84'), findsOneWidget);
      expect(find.text('Diff: 11.2'), findsOneWidget);

      // Strokes Gained Framework Section (Scroll further)
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Strokes Gained Framework'), findsOneWidget);
      expect(find.textContaining('Benchmark reference table'), findsOneWidget);
      expect(find.textContaining('Data cannot be faked with 0.00'), findsOneWidget);
      expect(find.text('Driving (Off-the-Tee)'), findsOneWidget);
      expect(find.text('28 shots'), findsOneWidget);
      expect(find.text('Unavailable'), findsNWidgets(4)); // 4 categories unavailable
    });

    testWidgets('tapping period chips triggers refresh with appropriate limit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsDashboardScreen(apiClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Last 5' chip
      await tester.tap(find.text('Last 5'));
      await tester.pumpAndSettle();

      expect(mockClient.lastLimitRequested, 5);
    });

    testWidgets('tapping handicap card navigates to HandicapHistoryScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsDashboardScreen(apiClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('WHS HANDICAP INDEX'));
      await tester.pumpAndSettle();

      expect(find.byType(HandicapHistoryScreen), findsOneWidget);
    });
  });
}

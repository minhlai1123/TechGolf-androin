import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/offline_course_storage.dart';
import 'package:mobile/features/courses/models/course_bundle_models.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/health/models/health_models.dart';
import 'package:mobile/features/health/screens/health_dashboard_screen.dart';
import 'package:mobile/features/health/services/health_service.dart';
import 'package:mobile/features/rounds/models/round_models.dart';
import 'package:mobile/features/rounds/screens/round_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSummaryHealthService implements IHealthService {
  final GolfHealthMetrics? metrics;
  final HealthPlatformType platform;

  MockSummaryHealthService({
    this.metrics,
    this.platform = HealthPlatformType.appleHealth,
  });

  @override
  HealthPlatformType get platformType => platform;

  @override
  HealthWorkoutSession? get activeWorkout => null;

  @override
  Stream<HealthWorkoutSession?> get workoutStream => const Stream.empty();

  @override
  Future<bool> isPlatformAvailable() async => true;

  @override
  Future<HealthPermissionStatus> checkPermissions() async => HealthPermissionStatus.granted;

  @override
  Future<HealthPermissionStatus> requestPermissions() async => HealthPermissionStatus.granted;

  @override
  Future<HealthWorkoutSession> startGolfWorkout({required String roundId, required String courseName}) async {
    return HealthWorkoutSession(
      id: 'session-1',
      roundId: roundId,
      courseName: courseName,
      startTime: DateTime.now(),
      state: HealthWorkoutState.inProgress,
      source: platform.displayName,
    );
  }

  @override
  Future<HealthWorkoutSession> endGolfWorkout({required String roundId}) async {
    return HealthWorkoutSession(
      id: 'session-1',
      roundId: roundId,
      courseName: 'Course',
      startTime: DateTime.now(),
      state: HealthWorkoutState.completed,
      source: platform.displayName,
    );
  }

  @override
  Future<GolfHealthMetrics> getRoundHealthMetrics({
    required String roundId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    return metrics ??
        GolfHealthMetrics(
          roundId: roundId,
          steps: 11200,
          walkingDistanceMeters: 8100.0,
          calories: 720.0,
          workoutDuration: const Duration(hours: 3, minutes: 40),
          platformSource: platform.displayName,
        );
  }

  @override
  void dispose() {}
}

void main() {
  group('RoundSummaryScreen Health Integration Tests', () {
    late RoundModel testRound;
    late CourseBundle testBundle;
    late OfflineCourseStorage testStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      testStorage = OfflineCourseStorage(prefs);

      testBundle = CourseBundle(
        course: const CourseInfo(id: 'c1', name: 'Augusta National', holesCount: 2),
        tees: [],
        holes: const [
          HoleData(id: 'h1', courseId: 'c1', holeNumber: 1, par: 4, handicapIndex: 1),
          HoleData(id: 'h2', courseId: 'c1', holeNumber: 2, par: 5, handicapIndex: 3),
        ],
        downloadedAt: DateTime.now(),
      );

      testRound = RoundModel(
        id: 'round-sum-1',
        courseId: 'c1',
        gameMode: GameMode.strokePlay,
        status: RoundStatus.completed,
        currentHole: 2,
        players: const [
          RoundPlayerModel(id: 'p1', roundId: 'round-sum-1', playerName: 'Jon Rahm', playerOrder: 1),
        ],
      );
    });

    testWidgets('renders HEALTH & FITNESS summary card with steps, distance, calories, duration', (tester) async {
      final mockHealth = MockSummaryHealthService();
      final mockApiClient = ApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: RoundSummaryScreen(
            round: testRound,
            bundle: testBundle,
            apiClient: mockApiClient,
            storage: testStorage,
            scoresMap: const {},
            healthService: mockHealth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Health Section Header
      expect(find.text('HEALTH & FITNESS'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Check Health Stats
      expect(find.text('11200'), findsOneWidget);
      expect(find.text('8.10 km'), findsOneWidget);
      expect(find.text('720 kcal'), findsOneWidget);
      expect(find.text('3h 40m'), findsOneWidget);

      // Tapping "Details" navigates to HealthDashboardScreen
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.byType(HealthDashboardScreen), findsOneWidget);
      expect(find.text('HEALTH INTEGRATION'), findsOneWidget);
    });

    testWidgets('renders placeholder dashes when health metrics are unavailable (never fake)', (tester) async {
      final mockHealth = MockSummaryHealthService(
        metrics: GolfHealthMetrics.empty(roundId: 'round-sum-1'),
      );
      final mockApiClient = ApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: RoundSummaryScreen(
            round: testRound,
            bundle: testBundle,
            apiClient: mockApiClient,
            storage: testStorage,
            scoresMap: const {},
            healthService: mockHealth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HEALTH & FITNESS'), findsOneWidget);
      expect(find.text('---'), findsWidgets);
      expect(find.textContaining('Health platform unavailable'), findsOneWidget);
    });
  });
}

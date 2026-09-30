import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health/models/health_models.dart';
import 'package:mobile/features/health/screens/health_dashboard_screen.dart';
import 'package:mobile/features/health/services/health_service.dart';

class MockTestHealthService implements IHealthService {
  HealthPlatformType mockPlatformType;
  bool mockIsAvailable;
  HealthPermissionStatus mockPermissionStatus;
  HealthWorkoutSession? mockActiveWorkout;
  GolfHealthMetrics? mockMetrics;

  final StreamController<HealthWorkoutSession?> _workoutController =
      StreamController<HealthWorkoutSession?>.broadcast();

  bool requestPermissionsCalled = false;
  bool startWorkoutCalled = false;
  bool endWorkoutCalled = false;

  MockTestHealthService({
    this.mockPlatformType = HealthPlatformType.appleHealth,
    this.mockIsAvailable = true,
    this.mockPermissionStatus = HealthPermissionStatus.granted,
    this.mockActiveWorkout,
    this.mockMetrics,
  });

  @override
  HealthPlatformType get platformType => mockPlatformType;

  @override
  HealthWorkoutSession? get activeWorkout => mockActiveWorkout;

  @override
  Stream<HealthWorkoutSession?> get workoutStream => _workoutController.stream;

  @override
  Future<bool> isPlatformAvailable() async => mockIsAvailable;

  @override
  Future<HealthPermissionStatus> checkPermissions() async => mockPermissionStatus;

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    requestPermissionsCalled = true;
    mockPermissionStatus = HealthPermissionStatus.granted;
    return HealthPermissionStatus.granted;
  }

  @override
  Future<HealthWorkoutSession> startGolfWorkout({
    required String roundId,
    required String courseName,
  }) async {
    startWorkoutCalled = true;
    final session = HealthWorkoutSession(
      id: 'session-123',
      roundId: roundId,
      courseName: courseName,
      startTime: DateTime.now(),
      state: HealthWorkoutState.inProgress,
      source: mockPlatformType.displayName,
    );
    mockActiveWorkout = session;
    _workoutController.add(session);
    return session;
  }

  @override
  Future<HealthWorkoutSession> endGolfWorkout({
    required String roundId,
  }) async {
    endWorkoutCalled = true;
    final finished = HealthWorkoutSession(
      id: mockActiveWorkout?.id ?? 'session-123',
      roundId: roundId,
      courseName: mockActiveWorkout?.courseName ?? 'Golf Course',
      startTime: mockActiveWorkout?.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      durationSeconds: 10800,
      totalSteps: 9800,
      walkingDistanceMeters: 7400.0,
      caloriesBurned: 620.0,
      state: HealthWorkoutState.completed,
      source: mockPlatformType.displayName,
    );
    mockActiveWorkout = null;
    _workoutController.add(null);
    return finished;
  }

  @override
  Future<GolfHealthMetrics> getRoundHealthMetrics({
    required String roundId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    return mockMetrics ??
        GolfHealthMetrics(
          roundId: roundId,
          steps: 9800,
          walkingDistanceMeters: 7400.0,
          calories: 620.0,
          workoutDuration: const Duration(hours: 3),
          platformSource: mockPlatformType.displayName,
        );
  }

  @override
  void dispose() {
    _workoutController.close();
  }
}

void main() {
  group('HealthDashboardScreen Widget Tests', () {
    testWidgets('renders platform card, permission status, workout and metrics', (tester) async {
      final mockService = MockTestHealthService(
        mockPlatformType: HealthPlatformType.appleHealth,
        mockPermissionStatus: HealthPermissionStatus.granted,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HealthDashboardScreen(
            healthService: mockService,
            activeRoundId: 'round-101',
            courseName: 'Pebble Beach',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('HEALTH INTEGRATION'), findsOneWidget);

      // Check Platform Card
      expect(find.text('Apple Health (HealthKit)'), findsOneWidget);
      expect(find.text('Granted'), findsOneWidget);

      // Check Workout Card
      expect(find.text('Golf Workout'), findsOneWidget);
      expect(find.text('IDLE'), findsOneWidget);
      expect(find.text('Start Golf Workout'), findsOneWidget);

      // Check Metrics Section
      expect(find.text('HEALTH METRICS'), findsOneWidget);
      expect(find.text('STEPS'), findsOneWidget);
      expect(find.text('9800'), findsOneWidget);
      expect(find.text('DISTANCE'), findsOneWidget);
      expect(find.text('7.40 km'), findsOneWidget);
      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('620 kcal'), findsOneWidget);
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('3h 0m'), findsOneWidget);

      // Check Privacy Notice (scroll down in ListView)
      await tester.scrollUntilVisible(find.textContaining('Privacy & Device Source'), 150);
      expect(find.textContaining('Privacy & Device Source'), findsOneWidget);
    });

    testWidgets('displays request permission button when permission is denied and updates on tap', (tester) async {
      final mockService = MockTestHealthService(
        mockPlatformType: HealthPlatformType.healthConnect,
        mockPermissionStatus: HealthPermissionStatus.denied,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HealthDashboardScreen(
            healthService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health Connect (Android)'), findsOneWidget);
      expect(find.text('Denied'), findsOneWidget);
      expect(find.text('Request Health Permissions'), findsOneWidget);

      // Tap request button
      await tester.tap(find.text('Request Health Permissions'));
      await tester.pumpAndSettle();

      expect(mockService.requestPermissionsCalled, isTrue);
      expect(find.text('Granted'), findsOneWidget);
    });

    testWidgets('allows starting and ending golf workout', (tester) async {
      final mockService = MockTestHealthService(
        mockPlatformType: HealthPlatformType.appleHealth,
        mockPermissionStatus: HealthPermissionStatus.granted,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HealthDashboardScreen(
            healthService: mockService,
            activeRoundId: 'round-101',
            courseName: 'Pebble Beach',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Start Golf Workout
      await tester.tap(find.text('Start Golf Workout'));
      await tester.pumpAndSettle();

      expect(mockService.startWorkoutCalled, isTrue);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Course: Pebble Beach'), findsOneWidget);
      expect(find.text('End Golf Workout'), findsOneWidget);

      // Tap End Golf Workout
      await tester.tap(find.text('End Golf Workout'));
      await tester.pumpAndSettle();

      expect(mockService.endWorkoutCalled, isTrue);
      expect(find.text('IDLE'), findsOneWidget);
    });

    testWidgets('displays unavailable placeholder when metrics are null (never fake numbers)', (tester) async {
      final mockService = MockTestHealthService(
        mockPlatformType: HealthPlatformType.none,
        mockPermissionStatus: HealthPermissionStatus.unavailable,
        mockMetrics: const GolfHealthMetrics(
          roundId: 'round-empty',
          steps: null,
          walkingDistanceMeters: null,
          calories: null,
          workoutDuration: null,
          platformSource: 'Unavailable',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HealthDashboardScreen(
            healthService: mockService,
            activeRoundId: 'round-empty',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Not Supported'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Steps unavailable'), findsOneWidget);
      expect(find.text('Distance unavailable'), findsOneWidget);
      expect(find.text('Calories unavailable'), findsOneWidget);
      expect(find.text('---'), findsWidgets);
    });
  });
}

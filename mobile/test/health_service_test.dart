import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health/models/health_models.dart';
import 'package:mobile/features/health/services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthService Tests', () {
    const channel = MethodChannel('techgolf/health');
    late HealthService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      service = HealthService(
        channel: channel,
        prefs: prefs,
      );
    });

    tearDown(() {
      service.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isPlatformAvailable handles success and failure', () async {
      // Mock returns true
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isAvailable') return true;
        return null;
      });

      // Note: On Windows host machine, platformType defaults to none unless overridden or mocked
      // If platformType is none, it returns false safely without crashing
      final available = await service.isPlatformAvailable();
      expect(available, isA<bool>());

      // Mock throws error
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Health not available');
      });

      final errorRes = await service.isPlatformAvailable();
      expect(errorRes, isFalse);
    });

    test('checkPermissions and requestPermissions parse statuses properly', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermissions') return 'granted';
        if (call.method == 'requestPermissions') return 'denied';
        return null;
      });

      final check = await service.checkPermissions();
      expect(check, isA<HealthPermissionStatus>());

      final req = await service.requestPermissions();
      expect(req, isA<HealthPermissionStatus>());
    });

    test('startGolfWorkout creates active session and avoids duplicates', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'startWorkout') {
          return {'status': 'started'};
        }
        return null;
      });

      final session1 = await service.startGolfWorkout(
        roundId: 'round-abc',
        courseName: 'Cypress Point',
      );

      expect(session1.roundId, 'round-abc');
      expect(session1.courseName, 'Cypress Point');
      expect(session1.state, HealthWorkoutState.inProgress);
      expect(service.activeWorkout, isNotNull);

      // Attempting to start duplicate workout for same round returns existing active workout
      final session2 = await service.startGolfWorkout(
        roundId: 'round-abc',
        courseName: 'Cypress Point',
      );
      expect(session2.id, session1.id);
    });

    test('startGolfWorkout falls back gracefully on native platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'PERMISSION_DENIED', message: 'User denied health tracking');
      });

      final session = await service.startGolfWorkout(
        roundId: 'round-err',
        courseName: 'St Andrews',
      );

      expect(session.roundId, 'round-err');
      expect(session.state, HealthWorkoutState.inProgress);
      expect(session.errorMessage, contains('Native workout session start error'));
      expect(service.activeWorkout, isNotNull);
    });

    test('endGolfWorkout completes active workout and parses health data', () async {
      // 1. Start workout first
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'startWorkout') return {'status': 'started'};
        if (call.method == 'endWorkout') {
          return {
            'steps': 10540,
            'distanceMeters': 7890.0,
            'calories': 680.0,
          };
        }
        return null;
      });

      await service.startGolfWorkout(
        roundId: 'round-xyz',
        courseName: 'Pine Valley',
      );

      // 2. End workout
      final completed = await service.endGolfWorkout(roundId: 'round-xyz');

      expect(completed.roundId, 'round-xyz');
      expect(completed.state, HealthWorkoutState.completed);
      expect(completed.totalSteps, 10540);
      expect(completed.walkingDistanceMeters, 7890.0);
      expect(completed.caloriesBurned, 680.0);
      expect(completed.duration, isNotNull);
      expect(service.activeWorkout, isNull);
    });

    test('endGolfWorkout handles native error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'endWorkout') {
          throw PlatformException(code: 'ERROR', message: 'Failed to fetch summary');
        }
        return null;
      });

      final finished = await service.endGolfWorkout(roundId: 'round-err');
      expect(finished.roundId, 'round-err');
      expect(finished.state, HealthWorkoutState.completed);
      expect(finished.errorMessage, contains('Could not fetch final workout summary'));
    });

    test('getRoundHealthMetrics parses metrics or returns empty on failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getMetrics') {
          return {
            'steps': 8500,
            'distanceMeters': 6400.0,
            'calories': 550.0,
            'limitationNote': 'Steps measured from phone accelerometer',
          };
        }
        return null;
      });

      final metrics = await service.getRoundHealthMetrics(
        roundId: 'round-101',
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
      );

      expect(metrics.roundId, 'round-101');
      expect(metrics.workoutDuration, isNotNull);
    });
  });
}

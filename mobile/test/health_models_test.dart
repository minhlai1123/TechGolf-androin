import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health/models/health_models.dart';

void main() {
  group('Health Models Tests', () {
    test('HealthPlatformType displays proper platform names', () {
      expect(HealthPlatformType.appleHealth.displayName, contains('Apple Health'));
      expect(HealthPlatformType.healthConnect.displayName, contains('Health Connect'));
      expect(HealthPlatformType.none.displayName, contains('Not Supported'));
    });

    test('HealthPermissionStatus handles all permission states', () {
      expect(HealthPermissionStatus.granted.displayName, 'Granted');
      expect(HealthPermissionStatus.granted.isGranted, isTrue);

      expect(HealthPermissionStatus.denied.displayName, 'Denied');
      expect(HealthPermissionStatus.denied.isGranted, isFalse);

      expect(HealthPermissionStatus.restricted.displayName, 'Restricted');
      expect(HealthPermissionStatus.restricted.isGranted, isFalse);

      expect(HealthPermissionStatus.unavailable.displayName, 'Unavailable');
      expect(HealthPermissionStatus.unavailable.isGranted, isFalse);

      expect(HealthPermissionStatus.revoked.displayName, 'Revoked');
      expect(HealthPermissionStatus.revoked.isGranted, isFalse);
    });

    test('HealthWorkoutSession JSON serialization, deserialization, and duration', () {
      final start = DateTime(2026, 9, 30, 9, 0, 0);
      final end = DateTime(2026, 9, 30, 12, 30, 0);

      final session = HealthWorkoutSession(
        id: 'workout-101',
        roundId: 'round-101',
        courseName: 'Pebble Beach',
        startTime: start,
        endTime: end,
        durationSeconds: 12600, // 3.5 hours
        totalSteps: 11450,
        walkingDistanceMeters: 8520.5,
        caloriesBurned: 740.0,
        state: HealthWorkoutState.completed,
        source: 'Health Connect (Android)',
      );

      expect(session.duration?.inMinutes, 210);

      final json = session.toJson();
      expect(json['id'], 'workout-101');
      expect(json['totalSteps'], 11450);
      expect(json['state'], 'completed');

      final fromJson = HealthWorkoutSession.fromJson(json);
      expect(fromJson.id, 'workout-101');
      expect(fromJson.totalSteps, 11450);
      expect(fromJson.walkingDistanceMeters, 8520.5);
      expect(fromJson.caloriesBurned, 740.0);
      expect(fromJson.state, HealthWorkoutState.completed);
      expect(fromJson.source, 'Health Connect (Android)');
    });

    test('GolfHealthMetrics formatting - valid data vs unavailable null data', () {
      // With valid data
      const withData = GolfHealthMetrics(
        roundId: 'round-101',
        steps: 9540,
        walkingDistanceMeters: 7200.0,
        calories: 650.0,
        workoutDuration: Duration(hours: 3, minutes: 15),
        platformSource: 'Apple Health (HealthKit)',
      );

      expect(withData.hasAnyMetric, isTrue);
      expect(withData.formattedSteps, '9540');
      expect(withData.formattedDistanceKm, '7.20 km');
      expect(withData.formattedCalories, '650 kcal');
      expect(withData.formattedDuration, '3h 15m');

      // With null/unavailable data (NEVER fake numbers!)
      final empty = GolfHealthMetrics.empty(roundId: 'round-102');
      expect(empty.hasAnyMetric, isFalse);
      expect(empty.formattedSteps, '---');
      expect(empty.formattedDistanceKm, '---');
      expect(empty.formattedCalories, '---');
      expect(empty.formattedDuration, '---');
      expect(empty.limitationNote, isNotNull);
    });
  });
}

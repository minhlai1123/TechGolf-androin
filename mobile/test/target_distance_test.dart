import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/geo/distance_engine.dart';
import 'package:mobile/features/golf_map/models/golf_map_models.dart';

void main() {
  group('Target Layup Distance Tests', () {
    test('Calculates dual distances: Player -> Target and Target -> Green', () {
      final playerPos = const LatLng(39.79008, -74.97210);
      final targetPos = const LatLng(39.78964, -74.97375);
      final greenPos = const LatLng(39.78920, -74.97540);

      final distToTargetMeters = DistanceEngine.distanceBetweenLatLngMeters(
        playerPos,
        targetPos,
      );
      final distToGreenMeters = DistanceEngine.distanceBetweenLatLngMeters(
        targetPos,
        greenPos,
      );

      final target = TargetLayupPoint(
        position: targetPos,
        distanceFromPlayerMeters: distToTargetMeters,
        distanceToGreenMeters: distToGreenMeters,
      );

      // Distances should be positive and non-zero
      expect(distToTargetMeters, greaterThan(100.0));
      expect(distToGreenMeters, greaterThan(100.0));

      // Check formatting
      final ydToTarget = target.formatPlayerDistance(DistanceUnit.yards);
      final ydToGreen = target.formatGreenDistance(DistanceUnit.yards);
      expect(ydToTarget, isNot('---'));
      expect(ydToGreen, isNot('---'));
      expect(int.parse(ydToTarget), greaterThan(100));
      expect(int.parse(ydToGreen), greaterThan(100));

      final mToTarget = target.formatPlayerDistance(DistanceUnit.meters);
      final mToGreen = target.formatGreenDistance(DistanceUnit.meters);
      expect(int.parse(mToTarget), greaterThan(90));
      expect(int.parse(mToGreen), greaterThan(90));
    });

    test('Handles null player location gracefully without crashing or faking', () {
      final targetPos = const LatLng(39.78964, -74.97375);
      final greenPos = const LatLng(39.78920, -74.97540);

      final distToGreenMeters = DistanceEngine.distanceBetweenLatLngMeters(
        targetPos,
        greenPos,
      );

      final target = TargetLayupPoint(
        position: targetPos,
        distanceFromPlayerMeters: null, // GPS unavailable
        distanceToGreenMeters: distToGreenMeters,
      );

      expect(target.formatPlayerDistance(DistanceUnit.yards), equals('---'));
      expect(target.formatGreenDistance(DistanceUnit.yards), isNot('---'));
    });
  });
}

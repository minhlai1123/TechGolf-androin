import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/geo/distance_engine.dart';

void main() {
  group('DistanceEngine Geodesic Tests', () {
    test('Calculates Haversine distance between known coordinates accurately', () {
      // Known geodesic distance:
      // Point 1: 39.79008, -74.97210 (Pine Valley Hole 1 Tee)
      // Point 2: 39.78920, -74.97540 (Pine Valley Hole 1 Green Center)
      final double distanceMeters = DistanceEngine.distanceBetweenMeters(
        39.79008,
        -74.97210,
        39.78920,
        -74.97540,
      );

      // Distance should be approximately 300 meters (~328 yards)
      expect(distanceMeters, greaterThan(290.0));
      expect(distanceMeters, lessThan(315.0));

      // Same coordinates must yield 0 distance
      final double zeroDist = DistanceEngine.distanceBetweenMeters(
        39.79008,
        -74.97210,
        39.79008,
        -74.97210,
      );
      expect(zeroDist, closeTo(0.0, 0.001));
    });

    test('Converts meters to yards accurately', () {
      // 100 meters should be ~109.36 yards
      final yards = DistanceEngine.metersToYards(100.0);
      expect(yards, closeTo(109.361, 0.01));
    });

    test('Converts yards to meters accurately', () {
      // 150 yards should be exactly 137.16 meters
      final meters150 = DistanceEngine.yardsToMeters(150.0);
      expect(meters150, closeTo(137.16, 0.001));

      // 200 yards should be exactly 182.88 meters
      final meters200 = DistanceEngine.yardsToMeters(200.0);
      expect(meters200, closeTo(182.88, 0.001));

      // 250 yards should be exactly 228.6 meters
      final meters250 = DistanceEngine.yardsToMeters(250.0);
      expect(meters250, closeTo(228.6, 0.001));
    });

    test('Calculates initial bearing correctly', () {
      // Heading directly North (same longitude, increasing latitude)
      final bearingNorth = DistanceEngine.initialBearing(10.0, 10.0, 20.0, 10.0);
      expect(bearingNorth, closeTo(0.0, 0.1));

      // Heading directly East (same latitude, increasing longitude at equator)
      final bearingEast = DistanceEngine.initialBearing(0.0, 10.0, 0.0, 20.0);
      expect(bearingEast, closeTo(90.0, 0.1));

      // Heading directly South
      final bearingSouth = DistanceEngine.initialBearing(20.0, 10.0, 10.0, 10.0);
      expect(bearingSouth, closeTo(180.0, 0.1));
    });

    test('destinationPoint computes point at exact target distance', () {
      final start = const LatLng(39.79008, -74.97210);
      const targetMeters = 182.88; // 200 yards

      final destination = DistanceEngine.destinationPoint(
        start: start,
        bearingDegrees: 45.0,
        distanceMeters: targetMeters,
      );

      final measuredMeters = DistanceEngine.distanceBetweenLatLngMeters(start, destination);
      expect(measuredMeters, closeTo(targetMeters, 0.1));
    });

    test('generateCirclePoints produces equidistant circular ring', () {
      final center = const LatLng(39.79008, -74.97210);
      const radiusMeters = 100.0;

      final circlePoints = DistanceEngine.generateCirclePoints(
        center: center,
        radiusMeters: radiusMeters,
        segments: 16,
      );

      expect(circlePoints.length, equals(17)); // 16 segments + closing point
      for (final pt in circlePoints) {
        final dist = DistanceEngine.distanceBetweenLatLngMeters(center, pt);
        expect(dist, closeTo(radiusMeters, 0.1));
      }
    });
  });
}

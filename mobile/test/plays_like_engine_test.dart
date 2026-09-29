import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';

void main() {
  group('PlaysLikeDistanceEngine Tests', () {
    test('Flat terrain returns actual distance without adjustment', () {
      final result = PlaysLikeDistanceEngine.calculate(
        actualDistance: 150.0,
        startElevationMeters: 10.0,
        targetElevationMeters: 10.0,
        unit: DistanceUnitType.yards,
      );

      expect(result.actualDistance, 150.0);
      expect(result.playsLikeDistance, 150.0);
      expect(result.adjustment, 0.0);
      expect(result.elevationDeltaMeters, 0.0);
      expect(result.hasElevation, isTrue);
    });

    test('Uphill shot increases plays-like distance', () {
      // Start 10m, target 20m -> +10m ~ +10.9 yards
      final result = PlaysLikeDistanceEngine.calculate(
        actualDistance: 150.0,
        startElevationMeters: 10.0,
        targetElevationMeters: 20.0,
        unit: DistanceUnitType.yards,
      );

      expect(result.actualDistance, 150.0);
      expect(result.elevationDeltaMeters, 10.0);
      expect(result.elevationDeltaUnit, closeTo(10.9, 0.1));
      expect(result.adjustment, greaterThan(10.0));
      expect(result.playsLikeDistance, closeTo(160.9, 0.1));
      expect(result.explanation, contains('Uphill'));
    });

    test('Downhill shot decreases plays-like distance', () {
      // Start 25m, target 10m -> -15m
      final result = PlaysLikeDistanceEngine.calculate(
        actualDistance: 150.0,
        startElevationMeters: 25.0,
        targetElevationMeters: 10.0,
        unit: DistanceUnitType.yards,
      );

      expect(result.actualDistance, 150.0);
      expect(result.elevationDeltaMeters, -15.0);
      expect(result.adjustment, lessThan(0.0));
      expect(result.playsLikeDistance, lessThan(150.0));
      expect(result.explanation, contains('Downhill'));
    });

    test('Meters unit computes elevation delta directly in meters', () {
      // 130m actual, +10m elevation gain -> 140m plays like
      final result = PlaysLikeDistanceEngine.calculate(
        actualDistance: 130.0,
        startElevationMeters: 5.0,
        targetElevationMeters: 15.0,
        unit: DistanceUnitType.meters,
      );

      expect(result.actualDistance, 130.0);
      expect(result.elevationDeltaMeters, 10.0);
      expect(result.elevationDeltaUnit, 10.0);
      expect(result.adjustment, 10.0);
      expect(result.playsLikeDistance, 140.0);
      expect(result.unit, DistanceUnitType.meters);
    });

    test('Missing elevation returns hasElevation=false and actual distance', () {
      final res1 = PlaysLikeDistanceEngine.calculate(
        actualDistance: 175.0,
        startElevationMeters: null,
        targetElevationMeters: 20.0,
        unit: DistanceUnitType.yards,
      );
      expect(res1.hasElevation, isFalse);
      expect(res1.playsLikeDistance, 175.0);
      expect(res1.adjustment, 0.0);

      final res2 = PlaysLikeDistanceEngine.calculate(
        actualDistance: 175.0,
        startElevationMeters: 12.0,
        targetElevationMeters: null,
        unit: DistanceUnitType.yards,
      );
      expect(res2.hasElevation, isFalse);
      expect(res2.playsLikeDistance, 175.0);
    });
  });
}

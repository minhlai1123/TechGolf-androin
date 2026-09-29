import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/geo/distance_engine.dart';
import 'package:mobile/features/golf_map/models/golf_map_models.dart';

void main() {
  group('FMB Distance Engine & Models Tests', () {
    test('Calculates F/M/B distances and formats properly in yards', () {
      // 100m, 150m, 200m
      const fmb = FmbDistances(
        frontMeters: 100.0,
        centerMeters: 150.0,
        backMeters: 200.0,
      );

      // Yard equivalents:
      // 100m -> ~109.36y -> 109
      // 150m -> ~164.04y -> 164
      // 200m -> ~218.72y -> 219
      expect(fmb.formatFront(DistanceUnit.yards), equals('109'));
      expect(fmb.formatCenter(DistanceUnit.yards), equals('164'));
      expect(fmb.formatBack(DistanceUnit.yards), equals('219'));
    });

    test('Formats properly in meters', () {
      const fmb = FmbDistances(
        frontMeters: 100.4,
        centerMeters: 150.2,
        backMeters: 199.7,
      );

      expect(fmb.formatFront(DistanceUnit.meters), equals('100'));
      expect(fmb.formatCenter(DistanceUnit.meters), equals('150'));
      expect(fmb.formatBack(DistanceUnit.meters), equals('200'));
    });

    test('Returns "---" when coordinates are missing (NEVER fake numbers)', () {
      const fmb = FmbDistances(
        frontMeters: null,
        centerMeters: 150.0,
        backMeters: null,
      );

      expect(fmb.formatFront(DistanceUnit.yards), equals('---'));
      expect(fmb.formatCenter(DistanceUnit.yards), equals('164'));
      expect(fmb.formatBack(DistanceUnit.yards), equals('---'));

      expect(fmb.formatFront(DistanceUnit.meters), equals('---'));
      expect(fmb.formatBack(DistanceUnit.meters), equals('---'));
    });

    test('Converts raw player coordinate to FMB properly', () {
      const pLat = 39.79000;
      const pLng = -74.97200;

      const fLat = 39.78910;
      const fLng = -74.97500;

      const cLat = 39.78920;
      const cLng = -74.97540;

      const bLat = 39.78930;
      const bLng = -74.97580;

      final frontM = DistanceEngine.distanceBetweenMeters(pLat, pLng, fLat, fLng);
      final centerM = DistanceEngine.distanceBetweenMeters(pLat, pLng, cLat, cLng);
      final backM = DistanceEngine.distanceBetweenMeters(pLat, pLng, bLat, bLng);

      final fmb = FmbDistances(
        frontMeters: frontM,
        centerMeters: centerM,
        backMeters: backM,
      );

      // Verify that back is farther than center, and center is farther than front
      expect(fmb.backMeters!, greaterThan(fmb.centerMeters!));
      expect(fmb.centerMeters!, greaterThan(fmb.frontMeters!));
    });
  });
}

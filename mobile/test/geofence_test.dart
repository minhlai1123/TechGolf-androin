import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/location/location_models.dart';
import 'package:mobile/features/courses/models/course_bundle_models.dart';
import 'package:mobile/features/golf_map/services/hole_geofence_service.dart';

void main() {
  group('HoleGeofenceService Tests', () {
    late HoleGeofenceService service;
    late HoleData hole1;
    late HoleData hole2;

    setUp(() {
      service = HoleGeofenceService(
        greenRadiusMeters: 35.0,
        nextTeeRadiusMeters: 30.0,
        maxAllowedAccuracy: 15.0,
        debounceRequired: 2,
      );

      // Hole 1: Green center at (39.78920, -74.97540)
      hole1 = const HoleData(
        id: 'hole-1',
        courseId: 'course-1',
        holeNumber: 1,
        par: 4,
        greenCenterLat: 39.78920,
        greenCenterLng: -74.97540,
        tees: [
          HoleTee(
            id: 'ht-1',
            holeId: 'hole-1',
            teeId: 'tee-championship',
            teeMarkerLat: 39.79008,
            teeMarkerLng: -74.97210,
          ),
        ],
      );

      // Hole 2: Tee at (39.78915, -74.97590) (~45m west of hole 1 green)
      hole2 = const HoleData(
        id: 'hole-2',
        courseId: 'course-1',
        holeNumber: 2,
        par: 4,
        greenCenterLat: 39.78500,
        greenCenterLng: -74.98000,
        tees: [
          HoleTee(
            id: 'ht-2',
            holeId: 'hole-2',
            teeId: 'tee-championship',
            teeMarkerLat: 39.78915,
            teeMarkerLng: -74.97590,
          ),
        ],
      );
    });

    test('Transitions from playingHole -> onGreen -> exitedGreen -> nextHole', () {
      expect(service.currentState, equals(HoleGeofenceState.playingHole));

      // 1. Player is in fairway (150m away from green)
      final fairwayLoc = LocationPoint(
        latitude: 39.78960,
        longitude: -74.97380,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );
      var result = service.processLocation(
        location: fairwayLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, isNull);
      expect(service.currentState, equals(HoleGeofenceState.playingHole));

      // 2. Player reaches green (within 10m of green center)
      final onGreenLoc = LocationPoint(
        latitude: 39.78920,
        longitude: -74.97545,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );
      result = service.processLocation(
        location: onGreenLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, isNull);
      expect(service.currentState, equals(HoleGeofenceState.onGreen));

      // 3. Player walks away from green (Green Exit - reading 1)
      final exitLoc = LocationPoint(
        latitude: 39.78918,
        longitude: -74.97585,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );
      result = service.processLocation(
        location: exitLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, isNull); // Debounce 1 of 2

      // Reading 2 confirms green exit
      result = service.processLocation(
        location: exitLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, isNull);
      expect(service.currentState, equals(HoleGeofenceState.exitedGreen));

      // 4. Player arrives at Hole 2 Tee box (reading 1)
      final atTeeLoc = LocationPoint(
        latitude: 39.78915,
        longitude: -74.97590,
        accuracy: 3.5,
        timestamp: DateTime.now(),
      );
      result = service.processLocation(
        location: atTeeLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, isNull); // Debounce 1 of 2

      // Reading 2 confirms tee entry -> triggers auto advancement to Hole 2!
      result = service.processLocation(
        location: atTeeLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(result, equals(2));
      // State is reset for new hole
      expect(service.currentState, equals(HoleGeofenceState.playingHole));
    });

    test('Rejects noisy GPS readings with poor accuracy (> 15m)', () {
      expect(service.currentState, equals(HoleGeofenceState.playingHole));

      // Location right on green, but GPS accuracy is terrible (35m)
      final noisyLoc = LocationPoint(
        latitude: 39.78920,
        longitude: -74.97540,
        accuracy: 35.0, // High GPS jitter/noise
        timestamp: DateTime.now(),
      );

      final result = service.processLocation(
        location: noisyLoc,
        currentHole: hole1,
        nextHole: hole2,
      );

      expect(result, isNull);
      // State should remain unchanged
      expect(service.currentState, equals(HoleGeofenceState.playingHole));
    });

    test('Manual reset restores playingHole state', () {
      // Put service into onGreen
      final onGreenLoc = LocationPoint(
        latitude: 39.78920,
        longitude: -74.97545,
        accuracy: 4.0,
        timestamp: DateTime.now(),
      );
      service.processLocation(
        location: onGreenLoc,
        currentHole: hole1,
        nextHole: hole2,
      );
      expect(service.currentState, equals(HoleGeofenceState.onGreen));

      // Trigger reset
      service.reset();
      expect(service.currentState, equals(HoleGeofenceState.playingHole));
    });
  });
}

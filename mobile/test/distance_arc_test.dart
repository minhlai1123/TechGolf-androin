import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/geo/distance_engine.dart';
import 'package:mobile/features/golf_map/services/distance_arc_service.dart';

void main() {
  group('DistanceArcService Tests', () {
    test('Generates standard 150y, 200y, 250y distance arcs', () {
      final playerPos = const LatLng(39.79008, -74.97210);
      final greenPos = const LatLng(39.78920, -74.97540);

      final arcs = DistanceArcService.generateArcs(
        playerPos: playerPos,
        targetPos: greenPos,
      );

      expect(arcs.length, equals(3));

      // 150 yards arc
      expect(arcs[0].distanceYards, equals(150.0));
      expect(arcs[0].distanceMeters, closeTo(137.16, 0.01));
      expect(arcs[0].points.isNotEmpty, isTrue);

      // 200 yards arc
      expect(arcs[1].distanceYards, equals(200.0));
      expect(arcs[1].distanceMeters, closeTo(182.88, 0.01));
      expect(arcs[1].points.isNotEmpty, isTrue);

      // 250 yards arc
      expect(arcs[2].distanceYards, equals(250.0));
      expect(arcs[2].distanceMeters, closeTo(228.6, 0.01));
      expect(arcs[2].points.isNotEmpty, isTrue);

      // Verify that every point on the 150y arc is approximately 137.16m from player
      for (final pt in arcs[0].points) {
        final dist = DistanceEngine.distanceBetweenLatLngMeters(playerPos, pt);
        expect(dist, closeTo(137.16, 0.5));
      }

      // Verify label position distance
      final labelDist = DistanceEngine.distanceBetweenLatLngMeters(playerPos, arcs[0].labelPosition);
      expect(labelDist, closeTo(137.16, 0.5));
    });

    test('Generates 360 degree arcs when targetPos is null', () {
      final playerPos = const LatLng(39.79008, -74.97210);

      final arcs = DistanceArcService.generateArcs(
        playerPos: playerPos,
        targetPos: null,
      );

      expect(arcs.length, equals(3));
      // First and last points should match closely for 360 degree loop
      final firstPt = arcs[0].points.first;
      final lastPt = arcs[0].points.last;
      final dist = DistanceEngine.distanceBetweenLatLngMeters(firstPt, lastPt);
      expect(dist, closeTo(0.0, 0.5));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/geo/distance_engine.dart';

/// Represents a single distance arc (e.g., 150yd, 200yd, 250yd)
class DistanceArc {
  final double distanceYards;
  final double distanceMeters;
  final Color strokeColor;
  final double strokeWidth;
  final List<LatLng> points;
  final LatLng labelPosition;

  const DistanceArc({
    required this.distanceYards,
    required this.distanceMeters,
    required this.strokeColor,
    required this.strokeWidth,
    required this.points,
    required this.labelPosition,
  });
}

/// Service generating concentric distance arcs around player GPS position
class DistanceArcService {
  static const List<double> standardArcYards = [150.0, 200.0, 250.0];

  /// Generate distance arcs around [playerPos] oriented toward [targetPos]
  /// If [targetPos] is provided, an arc segment centered around the bearing is produced;
  /// otherwise full circles are generated.
  static List<DistanceArc> generateArcs({
    required LatLng playerPos,
    LatLng? targetPos,
    List<double> arcYards = standardArcYards,
    int segments = 48,
  }) {
    final List<DistanceArc> arcs = [];

    // Distinct colors for 150y, 200y, 250y
    final Map<double, Color> arcColors = {
      150.0: const Color(0xFFFFD54F), // Gold/Amber
      200.0: const Color(0xFF4FC3F7), // Light Blue/Cyan
      250.0: const Color(0xFFFF8A65), // Deep Orange/Coral
    };

    final double mainBearing = targetPos != null
        ? DistanceEngine.initialBearing(
            playerPos.latitude,
            playerPos.longitude,
            targetPos.latitude,
            targetPos.longitude,
          )
        : 0.0;

    for (final yards in arcYards) {
      final double meters = DistanceEngine.yardsToMeters(yards);
      final List<LatLng> points = [];

      // If we have a target (e.g. green center), create an arc spanning +/- 60 degrees of the bearing
      // This is the classic Hole19 visual arc style
      final double arcSpanDegrees = targetPos != null ? 120.0 : 360.0;
      final double startAngle = targetPos != null
          ? (mainBearing - (arcSpanDegrees / 2.0) + 360.0) % 360.0
          : 0.0;
      final double step = arcSpanDegrees / segments;

      for (int i = 0; i <= segments; i++) {
        final double bearing = (startAngle + (i * step)) % 360.0;
        final LatLng pt = DistanceEngine.destinationPoint(
          start: playerPos,
          bearingDegrees: bearing,
          distanceMeters: meters,
        );
        points.add(pt);
      }

      // Label position at the center of the arc
      final LatLng labelPoint = DistanceEngine.destinationPoint(
        start: playerPos,
        bearingDegrees: mainBearing,
        distanceMeters: meters,
      );

      arcs.add(
        DistanceArc(
          distanceYards: yards,
          distanceMeters: meters,
          strokeColor: arcColors[yards] ?? Colors.white70,
          strokeWidth: 2.0,
          points: points,
          labelPosition: labelPoint,
        ),
      );
    }

    return arcs;
  }
}

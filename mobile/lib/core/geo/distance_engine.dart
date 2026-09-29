import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Geodesic Distance Engine implementing WGS84 spherical Haversine formula
/// and spatial distance transformations for golf courses.
class DistanceEngine {
  /// Earth's mean radius in meters (WGS84 spherical approximation)
  static const double earthRadiusMeters = 6371000.0;

  /// Conversion factor: 1 meter to yards
  static const double metersToYardsFactor = 1.0936132983;

  /// Conversion factor: 1 yard to meters
  static const double yardsToMetersFactor = 0.9144;

  /// Standard Hole19 Distance Arcs in yards
  static const double arc150Yards = 150.0;
  static const double arc200Yards = 200.0;
  static const double arc250Yards = 250.0;

  /// Calculates geodesic distance between two coordinates in meters using Haversine formula.
  static double distanceBetweenMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final double phi1 = _degreesToRadians(lat1);
    final double phi2 = _degreesToRadians(lat2);
    final double deltaPhi = _degreesToRadians(lat2 - lat1);
    final double deltaLambda = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(deltaPhi / 2.0) * math.sin(deltaPhi / 2.0) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2.0) *
            math.sin(deltaLambda / 2.0);

    final double c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates distance in meters between two [LatLng] points.
  static double distanceBetweenLatLngMeters(LatLng point1, LatLng point2) {
    return distanceBetweenMeters(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Converts meters to yards.
  static double metersToYards(double meters) {
    return meters * metersToYardsFactor;
  }

  /// Converts yards to meters.
  static double yardsToMeters(double yards) {
    return yards * yardsToMetersFactor;
  }

  /// Calculates geodesic distance between two coordinates in yards.
  static double distanceBetweenYards(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return metersToYards(distanceBetweenMeters(lat1, lng1, lat2, lng2));
  }

  /// Calculates distance in yards between two [LatLng] points.
  static double distanceBetweenLatLngYards(LatLng point1, LatLng point2) {
    return metersToYards(distanceBetweenLatLngMeters(point1, point2));
  }

  /// Computes the initial bearing from point 1 to point 2 in degrees (0 to 360).
  static double initialBearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final double phi1 = _degreesToRadians(lat1);
    final double phi2 = _degreesToRadians(lat2);
    final double deltaLambda = _degreesToRadians(lng2 - lng1);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = (bearingRad * 180.0 / math.pi + 360.0) % 360.0;
    return bearingDeg;
  }

  /// Computes destination point given start point, initial bearing (degrees), and distance (meters).
  static LatLng destinationPoint({
    required LatLng start,
    required double bearingDegrees,
    required double distanceMeters,
  }) {
    final double delta = distanceMeters / earthRadiusMeters;
    final double theta = _degreesToRadians(bearingDegrees);

    final double phi1 = _degreesToRadians(start.latitude);
    final double lambda1 = _degreesToRadians(start.longitude);

    final double phi2 = math.asin(
      math.sin(phi1) * math.cos(delta) +
          math.cos(phi1) * math.sin(delta) * math.cos(theta),
    );

    final double lambda2 = lambda1 +
        math.atan2(
          math.sin(theta) * math.sin(delta) * math.cos(phi1),
          math.cos(delta) - math.sin(phi1) * math.sin(phi2),
        );

    final double latDeg = phi2 * 180.0 / math.pi;
    final double lngDeg = (lambda2 * 180.0 / math.pi + 540.0) % 360.0 - 180.0;

    return LatLng(latDeg, lngDeg);
  }

  /// Generates a list of [LatLng] forming a circular polygon/polyline
  /// centered at [center] with radius in meters and specified [segments].
  static List<LatLng> generateCirclePoints({
    required LatLng center,
    required double radiusMeters,
    int segments = 64,
  }) {
    final List<LatLng> points = [];
    final double step = 360.0 / segments;

    for (int i = 0; i <= segments; i++) {
      final double bearing = (i * step) % 360.0;
      points.add(destinationPoint(
        start: center,
        bearingDegrees: bearing,
        distanceMeters: radiusMeters,
      ));
    }
    return points;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}

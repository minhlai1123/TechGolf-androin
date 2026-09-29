import 'package:latlong2/latlong.dart';

/// GPS accuracy health status
enum GpsSignalStatus {
  /// GPS signal is accurate (<= 10 meters)
  good,

  /// GPS signal is degraded (> 10 meters)
  poor,

  /// GPS is unavailable (permission denied, disabled, or no satellite fix)
  unavailable,
}

/// Backward compatibility alias
typedef LocationAccuracyStatus = GpsSignalStatus;

/// Normalized location point representation across GPS providers
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final double? altitude;
  final double? heading; // degrees (0-360)
  final double? speed; // m/s
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  /// Evaluates GPS signal accuracy quality based on standard golf requirements
  GpsSignalStatus get accuracyStatus {
    if (accuracy <= 10.0) {
      return GpsSignalStatus.good;
    }
    return GpsSignalStatus.poor;
  }

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  String toString() {
    return 'LocationPoint(lat: $latitude, lng: $longitude, acc: ${accuracy}m, status: $accuracyStatus)';
  }
}

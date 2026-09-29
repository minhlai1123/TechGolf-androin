import 'dart:async';
import '../location/location_models.dart';

/// Abstract Elevation Provider interface for Digital Elevation Models (DEM)
/// or hardware GPS barometric / satellite altitude.
abstract class ElevationProvider {
  /// Asynchronously retrieves elevation in meters above sea level for given coordinates.
  /// Returns null if no elevation data is available for the given point.
  Future<double?> getElevation(double latitude, double longitude);
}

/// Fallback / Null Elevation Provider used when no external DEM service is active.
class NullElevationProvider implements ElevationProvider {
  const NullElevationProvider();

  @override
  Future<double?> getElevation(double latitude, double longitude) async {
    return null;
  }
}

/// Provider that extracts elevation from recent device GPS [LocationPoint.altitude]
class GpsElevationProvider implements ElevationProvider {
  LocationPoint? _lastLocation;

  void updateLocation(LocationPoint location) {
    _lastLocation = location;
  }

  @override
  Future<double?> getElevation(double latitude, double longitude) async {
    if (_lastLocation != null && _lastLocation!.altitude != null) {
      return _lastLocation!.altitude;
    }
    return null;
  }
}

/// Controllable mock elevation provider for unit and widget testing
class MockElevationProvider implements ElevationProvider {
  final Map<String, double> _points = {};
  double? defaultElevation;

  MockElevationProvider({this.defaultElevation});

  void setElevation(double lat, double lng, double elevationMeters) {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    _points[key] = elevationMeters;
  }

  @override
  Future<double?> getElevation(double latitude, double longitude) async {
    final key = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    if (_points.containsKey(key)) {
      return _points[key];
    }
    return defaultElevation;
  }
}

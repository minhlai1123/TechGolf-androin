import 'dart:async';
import 'package:geolocator/geolocator.dart' hide LocationAccuracyStatus;
import 'location_models.dart';

/// Abstract GPS Location Service interface
abstract class LocationService {
  /// Stream of location updates
  Stream<LocationPoint> get locationStream;

  /// Current accuracy status
  LocationAccuracyStatus get currentStatus;

  /// Check whether location services are enabled and permissions granted
  Future<bool> hasPermission();

  /// Request location permissions from OS
  Future<bool> requestPermission();

  /// Retrieve immediate current location fix
  Future<LocationPoint?> getCurrentLocation();

  /// Start streaming location updates
  Future<void> startTracking();

  /// Stop streaming location updates
  Future<void> stopTracking();

  /// Dispose resources
  void dispose();
}

/// Production implementation of [LocationService] wrapping Geolocator
class GeolocatorLocationService implements LocationService {
  final StreamController<LocationPoint> _controller =
      StreamController<LocationPoint>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  LocationAccuracyStatus _status = LocationAccuracyStatus.unavailable;

  @override
  Stream<LocationPoint> get locationStream => _controller.stream;

  @override
  LocationAccuracyStatus get currentStatus => _status;

  @override
  Future<bool> hasPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = LocationAccuracyStatus.unavailable;
      return false;
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = LocationAccuracyStatus.unavailable;
      return false;
    }

    return true;
  }

  @override
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = LocationAccuracyStatus.unavailable;
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _status = LocationAccuracyStatus.unavailable;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _status = LocationAccuracyStatus.unavailable;
      return false;
    }

    return true;
  }

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    final bool ok = await hasPermission();
    if (!ok) {
      final bool granted = await requestPermission();
      if (!granted) {
        _status = LocationAccuracyStatus.unavailable;
        return null;
      }
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final point = _mapPosition(position);
      _status = point.accuracyStatus;
      return point;
    } catch (_) {
      _status = LocationAccuracyStatus.unavailable;
      return null;
    }
  }

  @override
  Future<void> startTracking() async {
    final bool ok = await hasPermission();
    if (!ok) {
      final bool granted = await requestPermission();
      if (!granted) {
        _status = LocationAccuracyStatus.unavailable;
        return;
      }
    }

    await _positionSubscription?.cancel();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final point = _mapPosition(position);
        _status = point.accuracyStatus;
        if (!_controller.isClosed) {
          _controller.add(point);
        }
      },
      onError: (Object error) {
        _status = LocationAccuracyStatus.unavailable;
      },
    );
  }

  @override
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _controller.close();
  }

  LocationPoint _mapPosition(Position p) {
    return LocationPoint(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      altitude: p.altitude,
      heading: p.heading,
      speed: p.speed,
      timestamp: p.timestamp,
    );
  }
}

/// Controllable mock location service for testing and simulated rounds
class MockLocationService implements LocationService {
  final StreamController<LocationPoint> _controller =
      StreamController<LocationPoint>.broadcast();
  LocationAccuracyStatus _status = LocationAccuracyStatus.good;
  LocationPoint? _lastLocation;
  bool permissionGranted = true;

  @override
  Stream<LocationPoint> get locationStream => _controller.stream;

  @override
  LocationAccuracyStatus get currentStatus => _status;

  void emitLocation(LocationPoint point) {
    _lastLocation = point;
    _status = point.accuracyStatus;
    if (!_controller.isClosed) {
      _controller.add(point);
    }
  }

  void emitUnavailable() {
    _status = LocationAccuracyStatus.unavailable;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    if (!permissionGranted || _status == LocationAccuracyStatus.unavailable) {
      return null;
    }
    return _lastLocation;
  }

  @override
  Future<void> startTracking() async {}

  @override
  Future<void> stopTracking() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

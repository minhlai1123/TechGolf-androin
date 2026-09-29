import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/geo/distance_engine.dart';
import '../../../core/location/location_models.dart';
import '../../courses/models/course_bundle_models.dart';

/// States in the automatic hole change workflow
enum HoleGeofenceState {
  playingHole,
  onGreen,
  exitedGreen,
}

/// Service that monitors player location to automate hole progression
class HoleGeofenceService {
  final double greenRadiusMeters;
  final double nextTeeRadiusMeters;
  final double maxAllowedAccuracy;
  final int debounceRequired;

  HoleGeofenceState _currentState = HoleGeofenceState.playingHole;
  int _consecutiveGreenExits = 0;
  int _consecutiveTeeEntries = 0;

  HoleGeofenceService({
    this.greenRadiusMeters = AppConstants.greenExitRadiusMeters,
    this.nextTeeRadiusMeters = AppConstants.nextTeeEntryRadiusMeters,
    this.maxAllowedAccuracy = AppConstants.maxGeofenceAccuracyMeters,
    this.debounceRequired = 2,
  });

  HoleGeofenceState get currentState => _currentState;

  /// Resets geofence state (called on hole change or round start)
  void reset() {
    _currentState = HoleGeofenceState.playingHole;
    _consecutiveGreenExits = 0;
    _consecutiveTeeEntries = 0;
  }

  /// Processes a new location point and determines if a hole transition should occur.
  /// Returns the next hole number if transition criteria are satisfied, or null otherwise.
  int? processLocation({
    required LocationPoint location,
    required HoleData currentHole,
    required HoleData? nextHole,
  }) {
    // Reject location with poor accuracy to prevent GPS jitter trigger
    if (location.accuracy > maxAllowedAccuracy) {
      return null;
    }

    final LatLng playerPos = location.toLatLng();
    final LatLng? greenCenter = currentHole.greenCenter;

    if (greenCenter == null) {
      return null;
    }

    final double distToCurrentGreen = DistanceEngine.distanceBetweenLatLngMeters(
      playerPos,
      greenCenter,
    );

    // State: playingHole -> onGreen
    if (_currentState == HoleGeofenceState.playingHole) {
      if (distToCurrentGreen <= greenRadiusMeters) {
        _currentState = HoleGeofenceState.onGreen;
        _consecutiveGreenExits = 0;
      }
      return null;
    }

    // State: onGreen -> exitedGreen (with debounce)
    if (_currentState == HoleGeofenceState.onGreen) {
      if (distToCurrentGreen > greenRadiusMeters) {
        _consecutiveGreenExits++;
        if (_consecutiveGreenExits >= debounceRequired) {
          _currentState = HoleGeofenceState.exitedGreen;
          _consecutiveTeeEntries = 0;
        }
      } else {
        _consecutiveGreenExits = 0;
      }
      return null;
    }

    // State: exitedGreen -> enteredNextTee -> advance to next hole
    if (_currentState == HoleGeofenceState.exitedGreen) {
      if (nextHole == null) {
        return null; // Round completed or no next hole
      }

      // Find nearest tee marker for next hole
      LatLng? nextTeePos;
      for (final tee in nextHole.tees) {
        if (tee.markerPoint != null) {
          nextTeePos = tee.markerPoint;
          break;
        }
      }

      // If no explicit tee marker is set, fallback to first polygon of type TEE
      if (nextTeePos == null) {
        for (final poly in nextHole.polygons) {
          if (poly.type == GolfPolygonType.tee && poly.coordinates.isNotEmpty) {
            nextTeePos = poly.coordinates.first;
            break;
          }
        }
      }

      if (nextTeePos != null) {
        final double distToNextTee = DistanceEngine.distanceBetweenLatLngMeters(
          playerPos,
          nextTeePos,
        );

        if (distToNextTee <= nextTeeRadiusMeters) {
          _consecutiveTeeEntries++;
          if (_consecutiveTeeEntries >= debounceRequired) {
            reset();
            return nextHole.holeNumber;
          }
        } else {
          _consecutiveTeeEntries = 0;
        }
      }
    }

    return null;
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/geo/distance_engine.dart';
import '../../../core/location/location_models.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';
import '../models/golf_map_models.dart';
import '../services/distance_arc_service.dart';
import '../services/hole_geofence_service.dart';
import '../widgets/fmb_distance_dashboard.dart';
import '../widgets/hole_navigation_bar.dart';
import '../widgets/map_controls_overlay.dart';
import '../widgets/target_distance_banner.dart';

/// Main Golf GPS Map Screen (Phase 3 Core)
class GolfMapScreen extends StatefulWidget {
  final CourseBundle bundle;
  final CourseTee? selectedTee;
  final LocationService locationService;
  final int initialHoleNumber;

  const GolfMapScreen({
    super.key,
    required this.bundle,
    this.selectedTee,
    required this.locationService,
    this.initialHoleNumber = 1,
  });

  @override
  State<GolfMapScreen> createState() => _GolfMapScreenState();
}

class _GolfMapScreenState extends State<GolfMapScreen> {
  final MapController _mapController = MapController();
  late HoleGeofenceService _geofenceService;
  StreamSubscription<LocationPoint>? _locationSubscription;

  late HoleData _currentHole;
  LocationPoint? _currentLocation;
  DistanceUnit _distanceUnit = DistanceUnit.yards;

  bool _isSatellite = true;
  bool _areArcsVisible = true;
  bool _isTargetActive = false;
  LatLng? _targetPosition;

  @override
  void initState() {
    super.initState();
    _geofenceService = HoleGeofenceService();

    // Select initial hole
    _currentHole = widget.bundle.holes.firstWhere(
      (h) => h.holeNumber == widget.initialHoleNumber,
      orElse: () => widget.bundle.holes.first,
    );

    _initLocationTracking();

    // After first frame, fit camera to hole
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitHoleBounds();
    });
  }

  void _initLocationTracking() async {
    // Request permission if needed
    final hasPerm = await widget.locationService.hasPermission();
    if (!hasPerm) {
      await widget.locationService.requestPermission();
    }

    // Get current fix
    final initialPos = await widget.locationService.getCurrentLocation();
    if (mounted && initialPos != null) {
      setState(() {
        _currentLocation = initialPos;
      });
    }

    // Start stream
    await widget.locationService.startTracking();
    _locationSubscription = widget.locationService.locationStream.listen(
      (LocationPoint point) {
        if (!mounted) return;
        setState(() {
          _currentLocation = point;
        });

        // Evaluate auto-hole geofence
        _checkGeofence(point);
      },
    );
  }

  void _checkGeofence(LocationPoint point) {
    final nextHoleNumber = _currentHole.holeNumber + 1;
    final nextHole = widget.bundle.holes.cast<HoleData?>().firstWhere(
          (h) => h?.holeNumber == nextHoleNumber,
          orElse: () => null,
        );

    final triggeredHole = _geofenceService.processLocation(
      location: point,
      currentHole: _currentHole,
      nextHole: nextHole,
    );

    if (triggeredHole != null && triggeredHole != _currentHole.holeNumber) {
      _onHoleSelected(triggeredHole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-advanced to Hole $triggeredHole'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onHoleSelected(int holeNumber) {
    final targetHole = widget.bundle.holes.firstWhere(
      (h) => h.holeNumber == holeNumber,
      orElse: () => _currentHole,
    );

    setState(() {
      _currentHole = targetHole;
      _geofenceService.reset();
      _isTargetActive = false;
      _targetPosition = null;
    });

    _fitHoleBounds();
  }

  void _fitHoleBounds() {
    final List<LatLng> points = [];

    // Add Green points
    if (_currentHole.greenCenter != null) points.add(_currentHole.greenCenter!);
    if (_currentHole.greenFront != null) points.add(_currentHole.greenFront!);
    if (_currentHole.greenBack != null) points.add(_currentHole.greenBack!);

    // Add Tee points
    for (final tee in _currentHole.tees) {
      if (tee.markerPoint != null) points.add(tee.markerPoint!);
    }

    // Add polygon points
    for (final poly in _currentHole.polygons) {
      points.addAll(poly.coordinates);
    }

    if (points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 140, // Space for F/M/B dashboard
            bottom: 100, // Space for Hole navigation bar
            left: 30,
            right: 70, // Space for right FABs
          ),
        ),
      );
    } else if (_currentHole.greenCenter != null) {
      _mapController.move(_currentHole.greenCenter!, 17.0);
    }
  }

  void _recenterPlayer() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!.toLatLng(), 17.5);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquiring GPS location...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleTarget() {
    setState(() {
      _isTargetActive = !_isTargetActive;
      if (_isTargetActive) {
        // Place target midpoint between player (or tee) and green center
        final green = _currentHole.greenCenter;
        final start = _currentLocation?.toLatLng() ?? _getFirstTeePosition();
        if (green != null && start != null) {
          _targetPosition = LatLng(
            (start.latitude + green.latitude) / 2.0,
            (start.longitude + green.longitude) / 2.0,
          );
        } else if (green != null) {
          _targetPosition = green;
        }
      } else {
        _targetPosition = null;
      }
    });
  }

  LatLng? _getFirstTeePosition() {
    for (final tee in _currentHole.tees) {
      if (tee.markerPoint != null) return tee.markerPoint;
    }
    return null;
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isTargetActive) {
      setState(() {
        _targetPosition = point;
      });
    }
  }

  FmbDistances _calculateFmbDistances() {
    final player = _currentLocation;
    if (player == null ||
        widget.locationService.currentStatus == GpsSignalStatus.unavailable) {
      return const FmbDistances();
    }

    final pLat = player.latitude;
    final pLng = player.longitude;

    double? frontMeters;
    if (_currentHole.greenFrontLat != null && _currentHole.greenFrontLng != null) {
      frontMeters = DistanceEngine.distanceBetweenMeters(
        pLat,
        pLng,
        _currentHole.greenFrontLat!,
        _currentHole.greenFrontLng!,
      );
    }

    double? centerMeters;
    if (_currentHole.greenCenterLat != null && _currentHole.greenCenterLng != null) {
      centerMeters = DistanceEngine.distanceBetweenMeters(
        pLat,
        pLng,
        _currentHole.greenCenterLat!,
        _currentHole.greenCenterLng!,
      );
    }

    double? backMeters;
    if (_currentHole.greenBackLat != null && _currentHole.greenBackLng != null) {
      backMeters = DistanceEngine.distanceBetweenMeters(
        pLat,
        pLng,
        _currentHole.greenBackLat!,
        _currentHole.greenBackLng!,
      );
    }

    return FmbDistances(
      frontMeters: frontMeters,
      centerMeters: centerMeters,
      backMeters: backMeters,
    );
  }

  TargetLayupPoint? _calculateTargetDistances() {
    if (!_isTargetActive || _targetPosition == null) return null;

    double? distFromPlayer;
    if (_currentLocation != null) {
      distFromPlayer = DistanceEngine.distanceBetweenLatLngMeters(
        _currentLocation!.toLatLng(),
        _targetPosition!,
      );
    }

    double? distToGreen;
    if (_currentHole.greenCenter != null) {
      distToGreen = DistanceEngine.distanceBetweenLatLngMeters(
        _targetPosition!,
        _currentHole.greenCenter!,
      );
    }

    return TargetLayupPoint(
      position: _targetPosition!,
      distanceFromPlayerMeters: distFromPlayer,
      distanceToGreenMeters: distToGreen,
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmb = _calculateFmbDistances();
    final target = _calculateTargetDistances();
    final playerLatLng = _currentLocation?.toLatLng();
    final greenCenter = _currentHole.greenCenter;

    // Generate Distance Arcs if visible and player location is available
    List<DistanceArc> arcs = [];
    if (_areArcsVisible && playerLatLng != null) {
      arcs = DistanceArcService.generateArcs(
        playerPos: playerLatLng,
        targetPos: greenCenter,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // 1. FLUTTER MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: greenCenter ?? const LatLng(39.7903, -74.9723),
              initialZoom: 17.0,
              maxZoom: 20.0,
              minZoom: 12.0,
              onTap: _onMapTap,
            ),
            children: [
              // Tile Layer: Satellite or OSM Fallback
              TileLayer(
                urlTemplate: _isSatellite
                    ? AppConstants.esriSatelliteTileUrl
                    : AppConstants.osmFallbackTileUrl,
                userAgentPackageName: 'com.techgolf.mobile',
                maxNativeZoom: 19,
              ),

              // Vector Golf Polygons Layer
              PolygonLayer(
                polygons: _currentHole.polygons.map((poly) {
                  return Polygon(
                    points: poly.coordinates,
                    color: poly.type.fillColor,
                    borderColor: poly.type.strokeColor,
                    borderStrokeWidth: 1.5,
                  );
                }).toList(),
              ),

              // Distance Arcs (150y, 200y, 250y) Layer
              if (_areArcsVisible && arcs.isNotEmpty) ...[
                PolylineLayer(
                  polylines: arcs.map((arc) {
                    return Polyline(
                      points: arc.points,
                      color: arc.strokeColor,
                      strokeWidth: arc.strokeWidth,
                      pattern: StrokePattern.dashed(segments: const [6, 4]),
                    );
                  }).toList(),
                ),
              ],

              // Target Layup Connecting Polylines
              if (_isTargetActive && _targetPosition != null) ...[
                PolylineLayer(
                  polylines: [
                    // Player to Target
                    if (playerLatLng != null)
                      Polyline(
                        points: [playerLatLng, _targetPosition!],
                        color: AppTheme.goldAccent,
                        strokeWidth: 2.5,
                        pattern: StrokePattern.dashed(segments: const [6, 4]),
                      ),
                    // Target to Green Center
                    if (greenCenter != null)
                      Polyline(
                        points: [_targetPosition!, greenCenter],
                        color: Colors.white70,
                        strokeWidth: 2.0,
                        pattern: StrokePattern.dashed(segments: const [6, 4]),
                      ),
                  ],
                ),
              ],

              // Markers Layer: Player, Pins, Tees, Target, Arc Labels
              MarkerLayer(
                markers: [
                  // Distance Arc Text Labels
                  if (_areArcsVisible)
                    ...arcs.map((arc) {
                      return Marker(
                        point: arc.labelPosition,
                        width: 50,
                        height: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: arc.strokeColor, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              '${arc.distanceYards.round()}y',
                              style: TextStyle(
                                color: arc.strokeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  // Green Center Pin
                  if (greenCenter != null)
                    Marker(
                      point: greenCenter,
                      width: 28,
                      height: 28,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                    ),

                  // Green Front Pin (subtle marker)
                  if (_currentHole.greenFront != null)
                    Marker(
                      point: _currentHole.greenFront!,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            'F',
                            style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  // Green Back Pin (subtle marker)
                  if (_currentHole.greenBack != null)
                    Marker(
                      point: _currentHole.greenBack!,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            'B',
                            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  // Tee Markers
                  ..._currentHole.tees
                      .where((t) => t.markerPoint != null)
                      .map((t) {
                    return Marker(
                      point: t.markerPoint!,
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                      ),
                    );
                  }),

                  // Target / Layup Marker
                  if (_isTargetActive && _targetPosition != null)
                    Marker(
                      point: _targetPosition!,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          // Dragging target marker across screen
                          final camera = _mapController.camera;
                          final localPoint = camera.latLngToScreenPoint(_targetPosition!);
                          final newPoint = math.Point<double>(
                            localPoint.x + details.delta.dx,
                            localPoint.y + details.delta.dy,
                          );
                          final newLatLng = camera.pointToLatLng(newPoint);
                          setState(() {
                            _targetPosition = newLatLng;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.goldAccent, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.gps_fixed,
                              color: AppTheme.goldAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Player GPS Location Marker with accuracy halo
                  if (playerLatLng != null)
                    Marker(
                      point: playerLatLng,
                      width: 32,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. TOP OVERLAYS
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // F/M/B Dashboard
                FmbDistanceDashboard(
                  distances: fmb,
                  unit: _distanceUnit,
                  accuracyStatus: widget.locationService.currentStatus,
                  accuracyMeters: _currentLocation?.accuracy,
                  onToggleUnit: () {
                    setState(() {
                      _distanceUnit = _distanceUnit == DistanceUnit.yards
                          ? DistanceUnit.meters
                          : DistanceUnit.yards;
                    });
                  },
                ),

                // Target Dual Distance Banner (when active)
                if (target != null)
                  TargetDistanceBanner(
                    target: target,
                    unit: _distanceUnit,
                    onClose: () {
                      setState(() {
                        _isTargetActive = false;
                        _targetPosition = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          // 3. RIGHT MAP CONTROLS OVERLAY
          Positioned(
            right: 14,
            bottom: 85,
            child: MapControlsOverlay(
              isTargetActive: _isTargetActive,
              isSatellite: _isSatellite,
              areArcsVisible: _areArcsVisible,
              onToggleTarget: _toggleTarget,
              onRecenterPlayer: _recenterPlayer,
              onFitHole: _fitHoleBounds,
              onToggleMapLayer: () {
                setState(() {
                  _isSatellite = !_isSatellite;
                });
              },
              onToggleArcs: () {
                setState(() {
                  _areArcsVisible = !_areArcsVisible;
                });
              },
            ),
          ),

          // 4. TOP APP BAR BACK BUTTON
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Exit Round',
              ),
            ),
          ),

          // 5. BOTTOM HOLE NAVIGATION BAR
          Align(
            alignment: Alignment.bottomCenter,
            child: HoleNavigationBar(
              currentHole: _currentHole,
              allHoles: widget.bundle.holes,
              onHoleSelected: _onHoleSelected,
            ),
          ),
        ],
      ),
    );
  }
}

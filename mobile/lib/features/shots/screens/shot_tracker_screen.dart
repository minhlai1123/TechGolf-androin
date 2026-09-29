import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/location_models.dart';
import '../../../../core/geo/distance_engine.dart';
import '../../../../core/geo/plays_like_engine.dart';
import '../../../../core/network/api_client.dart';
import '../models/shot_models.dart';
import '../services/offline_shot_storage.dart';

class ShotTrackerScreen extends StatefulWidget {
  final String roundId;
  final String playerId;
  final String holeId;
  final int holeNumber;
  final int par;
  final DistanceUnitType unit;
  final LocationService? locationService;
  final ApiClient? apiClient;
  final List<ClubDistanceModel> initialClubs;

  const ShotTrackerScreen({
    super.key,
    required this.roundId,
    required this.playerId,
    required this.holeId,
    required this.holeNumber,
    required this.par,
    this.unit = DistanceUnitType.yards,
    this.locationService,
    this.apiClient,
    this.initialClubs = const [],
  });

  @override
  State<ShotTrackerScreen> createState() => _ShotTrackerScreenState();
}

class _ShotTrackerScreenState extends State<ShotTrackerScreen> {
  late final LocationService _locationService;
  StreamSubscription<LocationPoint>? _locationSub;

  LocationPoint? _currentLocation;
  LocationAccuracyStatus _accuracyStatus = LocationAccuracyStatus.unavailable;

  ShotLifecycle _lifecycle = ShotLifecycle.ready;
  LocationPoint? _startPoint;
  double? _lastSavedDistance;
  ClubDistanceModel? _selectedClub;
  List<ClubDistanceModel> _clubs = [];
  List<ShotModel> _holeShots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? GeolocatorLocationService();
    _clubs = List.from(widget.initialClubs);
    if (_clubs.isNotEmpty) {
      _selectedClub = _clubs.firstWhere(
        (c) => c.isActive,
        orElse: () => _clubs.first,
      );
    }
    _initLocation();
    _loadHistoricalShots();
  }

  Future<void> _initLocation() async {
    _accuracyStatus = _locationService.currentStatus;
    _currentLocation = await _locationService.getCurrentLocation();
    if (mounted) setState(() {});

    _locationSub = _locationService.locationStream.listen((point) {
      if (mounted) {
        setState(() {
          _currentLocation = point;
          _accuracyStatus = point.accuracyStatus;
        });
      }
    });

    await _locationService.startTracking();
  }

  Future<void> _loadHistoricalShots() async {
    final localShots = await OfflineShotStorage.getShotsForRound(widget.roundId);
    if (mounted) {
      setState(() {
        _holeShots = localShots.where((s) => s.holeId == widget.holeId).toList();
      });
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  /// Dynamic live distance walked from start point to current position
  double get _currentWalkDistance {
    if (_startPoint == null || _currentLocation == null) return 0.0;
    if (widget.unit == DistanceUnitType.yards) {
      return DistanceEngine.distanceBetweenYards(
        _startPoint!.latitude,
        _startPoint!.longitude,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    } else {
      return DistanceEngine.distanceBetweenMeters(
        _startPoint!.latitude,
        _startPoint!.longitude,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    }
  }

  void _onStartShotPressed() {
    if (_currentLocation == null || _accuracyStatus == LocationAccuracyStatus.unavailable) {
      _showWarningDialog(
        title: 'GPS Unavailable',
        message: 'Cannot start shot without valid GPS signal. Please wait for GPS lock.',
      );
      return;
    }

    if (_accuracyStatus == LocationAccuracyStatus.poor) {
      _showAccuracyWarningDialog(onProceed: _doStartShot);
      return;
    }

    _doStartShot();
  }

  void _doStartShot() {
    setState(() {
      _lifecycle = ShotLifecycle.started;
      _startPoint = _currentLocation;
      _lastSavedDistance = null;
    });
  }

  Future<void> _onSaveShotPressed() async {
    if (_currentLocation == null || _startPoint == null) {
      _showWarningDialog(
        title: 'Cannot Save Shot',
        message: 'Current GPS location is unavailable.',
      );
      return;
    }

    if (_selectedClub == null) {
      await _showClubSelectionModal();
      if (_selectedClub == null || !mounted) return;
    }

    // Check GPS accuracy on save
    if (!mounted) return;
    if (_accuracyStatus == LocationAccuracyStatus.poor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: GPS accuracy is degraded (±${_currentLocation!.accuracy.toStringAsFixed(0)}m).'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
    }

    setState(() => _isLoading = true);

    final endLoc = _currentLocation!;
    final double distMeters = DistanceEngine.distanceBetweenMeters(
      _startPoint!.latitude,
      _startPoint!.longitude,
      endLoc.latitude,
      endLoc.longitude,
    );

    final double distInUnit = widget.unit == DistanceUnitType.yards
        ? DistanceEngine.metersToYards(distMeters)
        : distMeters;

    double? elevDelta;
    if (_startPoint!.altitude != null && endLoc.altitude != null) {
      elevDelta = endLoc.altitude! - _startPoint!.altitude!;
    }

    final shotId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final newShot = ShotModel(
      id: shotId,
      roundId: widget.roundId,
      playerId: widget.playerId,
      holeId: widget.holeId,
      clubId: _selectedClub?.id,
      clubName: _selectedClub?.displayName,
      status: ShotLifecycle.saved,
      startLatitude: _startPoint!.latitude,
      startLongitude: _startPoint!.longitude,
      startElevation: _startPoint!.altitude,
      endLatitude: endLoc.latitude,
      endLongitude: endLoc.longitude,
      endElevation: endLoc.altitude,
      elevationDelta: elevDelta,
      distance: double.parse(distInUnit.toStringAsFixed(1)),
      distanceUnit: widget.unit,
      syncStatus: ShotSyncStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save to offline storage immediately
    await OfflineShotStorage.saveShot(newShot);

    // Attempt online sync if ApiClient provided
    if (widget.apiClient != null) {
      try {
        final startRes = await widget.apiClient!.startShot(
          roundId: widget.roundId,
          playerId: widget.playerId,
          holeId: widget.holeId,
          latitude: _startPoint!.latitude,
          longitude: _startPoint!.longitude,
          clubId: _selectedClub?.id,
          elevation: _startPoint!.altitude,
          unit: widget.unit.nameUpper,
        );

        final backendShotId = startRes['id'] as String;

        await widget.apiClient!.saveShot(
          roundId: widget.roundId,
          shotId: backendShotId,
          clubId: _selectedClub!.id,
          latitude: endLoc.latitude,
          longitude: endLoc.longitude,
          elevation: endLoc.altitude,
          unit: widget.unit.nameUpper,
        );

        await OfflineShotStorage.markShotSynced(widget.roundId, shotId);
      } catch (_) {
        // Kept as pending for later background sync
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lifecycle = ShotLifecycle.saved;
        _lastSavedDistance = double.parse(distInUnit.toStringAsFixed(1));
        _holeShots.add(newShot);
      });
    }
  }

  void _onStartNextShotPressed() {
    setState(() {
      _lifecycle = ShotLifecycle.ready;
      _startPoint = null;
    });
  }

  Future<void> _showClubSelectionModal() async {
    final selected = await showModalBottomSheet<ClubDistanceModel>(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Club Used',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              if (_clubs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No clubs available in bag.\nPlease add clubs in Golf Bag.',
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _clubs.length,
                    itemBuilder: (ctx, idx) {
                      final c = _clubs[idx];
                      final isCurrent = _selectedClub?.id == c.id;
                      final double avg = widget.unit == DistanceUnitType.yards
                          ? DistanceEngine.metersToYards(c.averageDistanceMeters)
                          : c.averageDistanceMeters;

                      return ListTile(
                        leading: Icon(Icons.sports_golf, color: isCurrent ? AppTheme.primaryGreen : Colors.white60),
                        title: Text(c.displayName, style: const TextStyle(color: Colors.white)),
                        trailing: Text(
                          c.totalShotsRecorded > 0 ? '${avg.toStringAsFixed(0)} ${widget.unit.label}' : 'No data',
                          style: TextStyle(color: isCurrent ? AppTheme.primaryGreen : Colors.white60),
                        ),
                        selected: isCurrent,
                        onTap: () => Navigator.of(ctx).pop(c),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedClub = selected);
    }
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showAccuracyWarningDialog({required VoidCallback onProceed}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Poor GPS Accuracy', style: TextStyle(color: AppTheme.accentOrange)),
        content: Text(
          'GPS signal accuracy is currently ±${_currentLocation?.accuracy.toStringAsFixed(0)}m. '
          'Starting shot now may reduce distance accuracy. Continue anyway?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
            onPressed: () {
              Navigator.of(ctx).pop();
              onProceed();
            },
            child: const Text('Proceed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String unitLabel = widget.unit.label;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Hole ${widget.holeNumber} Shot Tracker'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildGpsBadge(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current Location & GPS Info Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.darkSurface,
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLocation != null
                          ? '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)} (±${_currentLocation!.accuracy.toStringAsFixed(1)}m)'
                          : 'Locating GPS...',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                  if (_currentLocation?.altitude != null)
                    Text(
                      'Alt: ${_currentLocation!.altitude!.toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 11, color: AppTheme.accentGold),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Lifecycle Status Card
                  _buildStatusCard(unitLabel),
                  const SizedBox(height: 16),

                  // Club Selector
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    tileColor: AppTheme.darkSurface,
                    leading: const Icon(Icons.sports_golf, color: AppTheme.primaryGreen),
                    title: Text(
                      _selectedClub != null ? _selectedClub!.displayName : 'Select Club',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      _selectedClub != null && _selectedClub!.totalShotsRecorded > 0
                          ? 'Average: ${widget.unit == DistanceUnitType.yards ? DistanceEngine.metersToYards(_selectedClub!.averageDistanceMeters).toStringAsFixed(0) : _selectedClub!.averageDistanceMeters.toStringAsFixed(0)} $unitLabel'
                          : 'No shot history',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    onTap: _showClubSelectionModal,
                  ),
                  const SizedBox(height: 24),

                  // Big Action Button
                  _buildActionButton(),
                  const SizedBox(height: 24),

                  // Recorded Hole Shots History
                  if (_holeShots.isNotEmpty) ...[
                    const Text(
                      'SHOTS THIS HOLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._holeShots.map((s) => _buildShotHistoryCard(s, unitLabel)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsBadge() {
    Color color;
    String label;
    switch (_accuracyStatus) {
      case LocationAccuracyStatus.good:
        color = AppTheme.primaryGreen;
        label = 'GPS Good';
        break;
      case LocationAccuracyStatus.poor:
        color = AppTheme.accentOrange;
        label = 'GPS Poor';
        break;
      case LocationAccuracyStatus.unavailable:
        color = AppTheme.primaryRed;
        label = 'No GPS';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String unitLabel) {
    if (_lifecycle == ShotLifecycle.started) {
      final double walked = _currentWalkDistance;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('SHOT IN PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                ),
                const Spacer(),
                const Text('Walk to your ball', style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${walked.toStringAsFixed(0)} $unitLabel',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text('Distance walked from tee/shot start', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      );
    }

    if (_lifecycle == ShotLifecycle.saved && _lastSavedDistance != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('SHOT RECORDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ),
                const Spacer(),
                Text(_selectedClub?.displayName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_lastSavedDistance!.toStringAsFixed(1)} $unitLabel',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 4),
            const Text('Saved to your club history & bag statistics', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_golf, size: 40, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          const Text(
            'Ready to Hit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap START SHOT at your ball location before swinging. Walk to your ball and tap SAVE SHOT.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_lifecycle == ShotLifecycle.started) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOrange,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 24, color: Colors.white),
        label: const Text(
          'SAVE SHOT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: _onSaveShotPressed,
      );
    }

    if (_lifecycle == ShotLifecycle.saved) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.add, size: 24, color: Colors.white),
        label: const Text(
          'START NEXT SHOT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: _onStartNextShotPressed,
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
      label: const Text(
        'START SHOT',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      onPressed: _onStartShotPressed,
    );
  }

  Widget _buildShotHistoryCard(ShotModel shot, String unitLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.golf_course, color: AppTheme.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shot.clubName ?? 'Club',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${shot.createdAt.hour.toString().padLeft(2, '0')}:${shot.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(
            shot.distance != null ? '${shot.distance!.toStringAsFixed(0)} $unitLabel' : '---',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/health_models.dart';
import '../services/health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  final IHealthService healthService;
  final String? activeRoundId;
  final String? courseName;

  const HealthDashboardScreen({
    super.key,
    required this.healthService,
    this.activeRoundId,
    this.courseName,
  });

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  bool _isLoading = true;
  bool _isPlatformAvailable = false;
  HealthPermissionStatus _permissionStatus = HealthPermissionStatus.unavailable;
  HealthWorkoutSession? _activeWorkout;
  GolfHealthMetrics? _metrics;
  StreamSubscription<HealthWorkoutSession?>? _workoutSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initHealthState();
    _workoutSub = widget.healthService.workoutStream.listen((session) {
      if (mounted) {
        setState(() {
          _activeWorkout = session;
          _updateTicker();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _workoutSub?.cancel();
    super.dispose();
  }

  void _updateTicker() {
    _ticker?.cancel();
    if (_activeWorkout != null && _activeWorkout!.state == HealthWorkoutState.inProgress) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _activeWorkout != null) {
          setState(() {
            _elapsed = DateTime.now().difference(_activeWorkout!.startTime);
          });
        }
      });
      _elapsed = DateTime.now().difference(_activeWorkout!.startTime);
    } else {
      _elapsed = Duration.zero;
    }
  }

  Future<void> _initHealthState() async {
    setState(() {
      _isLoading = true;
    });

    final available = await widget.healthService.isPlatformAvailable();
    final permission = await widget.healthService.checkPermissions();
    final currentWorkout = widget.healthService.activeWorkout;

    GolfHealthMetrics? metrics;
    if (widget.activeRoundId != null) {
      final startTime = currentWorkout?.startTime ?? DateTime.now().subtract(const Duration(hours: 1));
      metrics = await widget.healthService.getRoundHealthMetrics(
        roundId: widget.activeRoundId!,
        startTime: startTime,
      );
    }

    if (mounted) {
      setState(() {
        _isPlatformAvailable = available;
        _permissionStatus = permission;
        _activeWorkout = currentWorkout;
        _metrics = metrics;
        _isLoading = false;
      });
      _updateTicker();
    }
  }

  Future<void> _requestPermissions() async {
    final status = await widget.healthService.requestPermissions();
    if (mounted) {
      setState(() {
        _permissionStatus = status;
      });
      if (status.isGranted) {
        _initHealthState();
      }
    }
  }

  Future<void> _startWorkout() async {
    final roundId = widget.activeRoundId ?? 'round-manual';
    final course = widget.courseName ?? 'Golf Course';
    final session = await widget.healthService.startGolfWorkout(
      roundId: roundId,
      courseName: course,
    );
    if (mounted) {
      setState(() {
        _activeWorkout = session;
      });
      _updateTicker();
    }
  }

  Future<void> _endWorkout() async {
    if (_activeWorkout == null) return;
    final finished = await widget.healthService.endGolfWorkout(roundId: _activeWorkout!.roundId);
    if (mounted) {
      setState(() {
        _activeWorkout = null;
        _metrics = GolfHealthMetrics(
          roundId: finished.roundId,
          steps: finished.totalSteps,
          walkingDistanceMeters: finished.walkingDistanceMeters,
          calories: finished.caloriesBurned,
          workoutDuration: finished.duration,
          platformSource: finished.source,
        );
      });
      _updateTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('HEALTH INTEGRATION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Health Data',
            onPressed: _initHealthState,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _initHealthState,
              color: AppTheme.primaryGreen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPlatformCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutCard(),
                  const SizedBox(height: 16),
                  _buildMetricsSection(),
                  const SizedBox(height: 16),
                  _buildPrivacyNoticeCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPlatformCard() {
    final platform = widget.healthService.platformType;
    final isGranted = _permissionStatus.isGranted;

    Color statusColor;
    switch (_permissionStatus) {
      case HealthPermissionStatus.granted:
        statusColor = AppTheme.primaryGreen;
        break;
      case HealthPermissionStatus.denied:
      case HealthPermissionStatus.revoked:
        statusColor = AppTheme.primaryRed;
        break;
      case HealthPermissionStatus.restricted:
        statusColor = AppTheme.accentOrange;
        break;
      case HealthPermissionStatus.unavailable:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: AppTheme.primaryRed, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    platform.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  _permissionStatus.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isPlatformAvailable
                ? (isGranted
                    ? 'Connected and synchronized with device health engine.'
                    : 'Health permissions required to read golf steps, calories, and distance.')
                : 'Health platform is not supported or not enabled on this device.',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          if (!isGranted && _isPlatformAvailable) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.lock_open, size: 16, color: Colors.black),
              label: const Text(
                'Request Health Permissions',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutCard() {
    final active = _activeWorkout;
    final inProgress = active != null && active.state == HealthWorkoutState.inProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inProgress ? AppTheme.primaryGreen : Colors.white12,
          width: inProgress ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sports_golf, color: AppTheme.primaryGreen, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Golf Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inProgress
                      ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inProgress ? 'ACTIVE' : 'IDLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: inProgress ? AppTheme.primaryGreen : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (inProgress) ...[
            Text(
              'Course: ${active.courseName}',
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Elapsed: ${_formatDuration(_elapsed)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _endWorkout,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('End Golf Workout', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Track your steps, walking distance, and calories burned automatically during your round.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow, color: AppTheme.primaryGreen),
                label: const Text(
                  'Start Golf Workout',
                  style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final m = _metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HEALTH METRICS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'STEPS',
                value: m?.formattedSteps ?? '---',
                subtitle: m?.steps == null ? 'Steps unavailable' : 'Total steps',
                icon: Icons.directions_walk,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'DISTANCE',
                value: m?.formattedDistanceKm ?? '---',
                subtitle: m?.walkingDistanceMeters == null ? 'Distance unavailable' : 'Walking distance',
                icon: Icons.straighten,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'CALORIES',
                value: m?.formattedCalories ?? '---',
                subtitle: m?.calories == null ? 'Calories unavailable' : 'Active energy',
                icon: Icons.local_fire_department,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'WORKOUT',
                value: m?.formattedDuration ?? '---',
                subtitle: 'Session duration',
                icon: Icons.timer_outlined,
                color: Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: Colors.white60),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Privacy & Device Source: Health metrics are fetched directly from your device\'s Health platform (HealthKit / Health Connect). TechGolf never invents or fakes steps, distance, or calories. All health information remains on your device and is never sent to external servers.',
              style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

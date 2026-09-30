import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';

abstract class IHealthService {
  HealthPlatformType get platformType;
  Future<bool> isPlatformAvailable();
  Future<HealthPermissionStatus> checkPermissions();
  Future<HealthPermissionStatus> requestPermissions();
  Future<HealthWorkoutSession> startGolfWorkout({
    required String roundId,
    required String courseName,
  });
  Future<HealthWorkoutSession> endGolfWorkout({
    required String roundId,
  });
  Future<GolfHealthMetrics> getRoundHealthMetrics({
    required String roundId,
    required DateTime startTime,
    DateTime? endTime,
  });
  HealthWorkoutSession? get activeWorkout;
  Stream<HealthWorkoutSession?> get workoutStream;
  void dispose();
}

class HealthService implements IHealthService {
  static const String _prefActiveWorkoutKey = 'techgolf_active_golf_workout';
  final MethodChannel _channel;
  final SharedPreferences? prefs;
  final HealthPlatformType? overridePlatformType;

  final StreamController<HealthWorkoutSession?> _workoutController =
      StreamController<HealthWorkoutSession?>.broadcast();

  HealthWorkoutSession? _activeWorkout;

  HealthService({
    MethodChannel? channel,
    this.prefs,
    this.overridePlatformType,
  })  : _channel = channel ?? const MethodChannel('techgolf/health') {
    _restoreActiveWorkout();
  }

  void _restoreActiveWorkout() {
    if (prefs != null) {
      final raw = prefs!.getString(_prefActiveWorkoutKey);
      if (raw != null) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          _activeWorkout = HealthWorkoutSession.fromJson(json);
        } catch (_) {}
      }
    }
  }

  @override
  HealthPlatformType get platformType {
    final overrideType = overridePlatformType;
    if (overrideType != null) return overrideType;
    if (kIsWeb) return HealthPlatformType.none;
    try {
      if (Platform.isIOS) return HealthPlatformType.appleHealth;
      if (Platform.isAndroid) return HealthPlatformType.healthConnect;
    } catch (_) {}
    return HealthPlatformType.none;
  }

  @override
  HealthWorkoutSession? get activeWorkout => _activeWorkout;

  @override
  Stream<HealthWorkoutSession?> get workoutStream => _workoutController.stream;

  @override
  Future<bool> isPlatformAvailable() async {
    if (platformType == HealthPlatformType.none) return false;
    try {
      final bool? available = await _channel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<HealthPermissionStatus> checkPermissions() async {
    if (platformType == HealthPlatformType.none) {
      return HealthPermissionStatus.unavailable;
    }
    try {
      final String? status = await _channel.invokeMethod<String>('checkPermissions');
      return _parsePermissionStatus(status);
    } catch (_) {
      return HealthPermissionStatus.unavailable;
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    if (platformType == HealthPlatformType.none) {
      return HealthPermissionStatus.unavailable;
    }
    try {
      final String? status = await _channel.invokeMethod<String>('requestPermissions');
      return _parsePermissionStatus(status);
    } catch (_) {
      return HealthPermissionStatus.denied;
    }
  }

  HealthPermissionStatus _parsePermissionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'granted':
        return HealthPermissionStatus.granted;
      case 'denied':
        return HealthPermissionStatus.denied;
      case 'restricted':
        return HealthPermissionStatus.restricted;
      case 'revoked':
        return HealthPermissionStatus.revoked;
      case 'unavailable':
      default:
        return HealthPermissionStatus.unavailable;
    }
  }

  @override
  Future<HealthWorkoutSession> startGolfWorkout({
    required String roundId,
    required String courseName,
  }) async {
    // Prevent duplicate active workouts for the same round
    if (_activeWorkout != null &&
        _activeWorkout!.roundId == roundId &&
        _activeWorkout!.state == HealthWorkoutState.inProgress) {
      return _activeWorkout!;
    }

    final startTime = DateTime.now();
    final sourceName = platformType.displayName;

    try {
      // Notify native platform to begin golf workout tracking
      await _channel.invokeMethod('startWorkout', {
        'roundId': roundId,
        'courseName': courseName,
        'startTime': startTime.toIso8601String(),
        'activityType': 'Golf',
      });

      final session = HealthWorkoutSession(
        id: 'workout-$roundId-${startTime.millisecondsSinceEpoch}',
        roundId: roundId,
        courseName: courseName,
        startTime: startTime,
        state: HealthWorkoutState.inProgress,
        source: sourceName,
      );

      _activeWorkout = session;
      _saveActiveWorkout(session);
      _workoutController.add(session);
      return session;
    } catch (e) {
      // In case of native error or permissions missing, track locally without crashing
      final fallbackSession = HealthWorkoutSession(
        id: 'workout-$roundId-${startTime.millisecondsSinceEpoch}',
        roundId: roundId,
        courseName: courseName,
        startTime: startTime,
        state: HealthWorkoutState.inProgress,
        source: '$sourceName (Local Timer)',
        errorMessage: 'Native workout session start error. Tracking local duration.',
      );

      _activeWorkout = fallbackSession;
      _saveActiveWorkout(fallbackSession);
      _workoutController.add(fallbackSession);
      return fallbackSession;
    }
  }

  @override
  Future<HealthWorkoutSession> endGolfWorkout({
    required String roundId,
  }) async {
    final endTime = DateTime.now();
    final active = _activeWorkout;
    final startTime = active?.startTime ?? endTime;
    final durationSecs = endTime.difference(startTime).inSeconds;

    int? totalSteps;
    double? walkingDistanceMeters;
    double? caloriesBurned;
    String? errorMsg;

    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('endWorkout', {
        'roundId': roundId,
        'endTime': endTime.toIso8601String(),
      });

      if (res != null) {
        totalSteps = res['steps'] as int?;
        walkingDistanceMeters = (res['distanceMeters'] as num?)?.toDouble();
        caloriesBurned = (res['calories'] as num?)?.toDouble();
      }
    } catch (e) {
      errorMsg = 'Could not fetch final workout summary from platform: $e';
    }

    final finishedSession = HealthWorkoutSession(
      id: active?.id ?? 'workout-$roundId-${endTime.millisecondsSinceEpoch}',
      roundId: roundId,
      courseName: active?.courseName ?? 'Golf Round',
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSecs,
      totalSteps: totalSteps,
      walkingDistanceMeters: walkingDistanceMeters,
      caloriesBurned: caloriesBurned,
      state: HealthWorkoutState.completed,
      source: active?.source ?? platformType.displayName,
      errorMessage: errorMsg,
    );

    _activeWorkout = null;
    _clearActiveWorkout();
    _workoutController.add(null);

    return finishedSession;
  }

  @override
  Future<GolfHealthMetrics> getRoundHealthMetrics({
    required String roundId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final targetEnd = endTime ?? DateTime.now();
    final duration = targetEnd.difference(startTime);

    if (platformType == HealthPlatformType.none) {
      return GolfHealthMetrics.empty(roundId: roundId, workoutDuration: duration);
    }

    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getMetrics', {
        'startTime': startTime.toIso8601String(),
        'endTime': targetEnd.toIso8601String(),
      });

      if (res == null) {
        return GolfHealthMetrics(
          roundId: roundId,
          workoutDuration: duration,
          platformSource: platformType.displayName,
          limitationNote: 'No health metrics returned by platform for the round timeframe.',
        );
      }

      final steps = res['steps'] as int?;
      final distance = (res['distanceMeters'] as num?)?.toDouble();
      final calories = (res['calories'] as num?)?.toDouble();
      final note = res['limitationNote'] as String?;

      return GolfHealthMetrics(
        roundId: roundId,
        steps: steps,
        walkingDistanceMeters: distance,
        calories: calories,
        workoutDuration: duration,
        platformSource: platformType.displayName,
        limitationNote: note ?? (steps == null ? 'Steps are aggregated from device sensor.' : null),
      );
    } catch (_) {
      return GolfHealthMetrics(
        roundId: roundId,
        workoutDuration: duration,
        platformSource: platformType.displayName,
        limitationNote: 'Health platform unavailable or access was revoked.',
      );
    }
  }

  void _saveActiveWorkout(HealthWorkoutSession session) {
    if (prefs != null) {
      prefs!.setString(_prefActiveWorkoutKey, jsonEncode(session.toJson()));
    }
  }

  void _clearActiveWorkout() {
    if (prefs != null) {
      prefs!.remove(_prefActiveWorkoutKey);
    }
  }

  @override
  void dispose() {
    _workoutController.close();
  }
}

enum HealthPlatformType {
  appleHealth,
  healthConnect,
  none,
}

extension HealthPlatformTypeExtension on HealthPlatformType {
  String get displayName {
    switch (this) {
      case HealthPlatformType.appleHealth:
        return 'Apple Health (HealthKit)';
      case HealthPlatformType.healthConnect:
        return 'Health Connect (Android)';
      case HealthPlatformType.none:
        return 'Not Supported';
    }
  }
}

enum HealthPermissionStatus {
  granted,
  denied,
  restricted,
  unavailable,
  revoked,
}

extension HealthPermissionStatusExtension on HealthPermissionStatus {
  String get displayName {
    switch (this) {
      case HealthPermissionStatus.granted:
        return 'Granted';
      case HealthPermissionStatus.denied:
        return 'Denied';
      case HealthPermissionStatus.restricted:
        return 'Restricted';
      case HealthPermissionStatus.unavailable:
        return 'Unavailable';
      case HealthPermissionStatus.revoked:
        return 'Revoked';
    }
  }

  bool get isGranted => this == HealthPermissionStatus.granted;
}

enum HealthWorkoutState {
  notStarted,
  inProgress,
  completed,
  failed,
}

class HealthWorkoutSession {
  final String id;
  final String roundId;
  final String courseName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final int? totalSteps;
  final double? walkingDistanceMeters;
  final double? caloriesBurned;
  final HealthWorkoutState state;
  final String source;
  final String? errorMessage;

  const HealthWorkoutSession({
    required this.id,
    required this.roundId,
    required this.courseName,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.totalSteps,
    this.walkingDistanceMeters,
    this.caloriesBurned,
    this.state = HealthWorkoutState.notStarted,
    required this.source,
    this.errorMessage,
  });

  Duration? get duration {
    if (durationSeconds != null) {
      return Duration(seconds: durationSeconds!);
    }
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  HealthWorkoutSession copyWith({
    String? id,
    String? roundId,
    String? courseName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? totalSteps,
    double? walkingDistanceMeters,
    double? caloriesBurned,
    HealthWorkoutState? state,
    String? source,
    String? errorMessage,
  }) {
    return HealthWorkoutSession(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      courseName: courseName ?? this.courseName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalSteps: totalSteps ?? this.totalSteps,
      walkingDistanceMeters: walkingDistanceMeters ?? this.walkingDistanceMeters,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      state: state ?? this.state,
      source: source ?? this.source,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundId': roundId,
      'courseName': courseName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalSteps': totalSteps,
      'walkingDistanceMeters': walkingDistanceMeters,
      'caloriesBurned': caloriesBurned,
      'state': state.name,
      'source': source,
      'errorMessage': errorMessage,
    };
  }

  factory HealthWorkoutSession.fromJson(Map<String, dynamic> json) {
    return HealthWorkoutSession(
      id: json['id'] as String? ?? '',
      roundId: json['roundId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      durationSeconds: json['durationSeconds'] as int?,
      totalSteps: json['totalSteps'] as int?,
      walkingDistanceMeters: (json['walkingDistanceMeters'] as num?)?.toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble(),
      state: HealthWorkoutState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => HealthWorkoutState.notStarted,
      ),
      source: json['source'] as String? ?? 'Device Health',
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class GolfHealthMetrics {
  final String roundId;
  final int? steps;
  final double? walkingDistanceMeters;
  final double? calories;
  final Duration? workoutDuration;
  final String platformSource;
  final String? limitationNote;

  const GolfHealthMetrics({
    required this.roundId,
    this.steps,
    this.walkingDistanceMeters,
    this.calories,
    this.workoutDuration,
    required this.platformSource,
    this.limitationNote,
  });

  bool get hasAnyMetric =>
      steps != null || walkingDistanceMeters != null || calories != null || workoutDuration != null;

  String get formattedSteps {
    if (steps == null) return '---';
    return '$steps';
  }

  String get formattedDistanceKm {
    if (walkingDistanceMeters == null) return '---';
    final km = walkingDistanceMeters! / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  String get formattedCalories {
    if (calories == null) return '---';
    return '${calories!.round()} kcal';
  }

  String get formattedDuration {
    if (workoutDuration == null) return '---';
    final hours = workoutDuration!.inHours;
    final minutes = workoutDuration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory GolfHealthMetrics.empty({
    required String roundId,
    Duration? workoutDuration,
    String source = 'Unavailable',
  }) {
    return GolfHealthMetrics(
      roundId: roundId,
      workoutDuration: workoutDuration,
      platformSource: source,
      limitationNote: 'Health platform unavailable or permissions not granted.',
    );
  }
}

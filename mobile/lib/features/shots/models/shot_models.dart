import '../../../core/geo/plays_like_engine.dart';

enum ShotLifecycle {
  ready,
  started,
  saved,
}

enum ShotSyncStatus {
  pending,
  synced,
  failed,
}

class ClubDistanceModel {
  final String id;
  final String clubType;
  final String? customName;
  final double averageDistanceMeters;
  final double averageDistanceYards;
  final int totalShotsRecorded;
  final bool isActive;

  const ClubDistanceModel({
    required this.id,
    required this.clubType,
    this.customName,
    required this.averageDistanceMeters,
    required this.averageDistanceYards,
    required this.totalShotsRecorded,
    this.isActive = true,
  });

  String get displayName {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!.trim();
    }
    return clubType.replaceAll('_', ' ');
  }

  factory ClubDistanceModel.fromJson(Map<String, dynamic> json) {
    return ClubDistanceModel(
      id: json['id'] as String,
      clubType: (json['clubType'] ?? json['club_type'] ?? 'UNKNOWN') as String,
      customName: (json['customName'] ?? json['custom_name']) as String?,
      averageDistanceMeters: (json['averageDistanceMeters'] ?? json['average_distance_meters'] ?? 0.0).toDouble(),
      averageDistanceYards: (json['averageDistanceYards'] ?? json['average_distance_yards'] ?? 0.0).toDouble(),
      totalShotsRecorded: (json['totalShotsRecorded'] ?? json['total_shots_recorded'] ?? 0) as int,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubType': clubType,
      'customName': customName,
      'averageDistanceMeters': averageDistanceMeters,
      'averageDistanceYards': averageDistanceYards,
      'totalShotsRecorded': totalShotsRecorded,
      'isActive': isActive,
    };
  }
}

class ShotModel {
  final String id;
  final String roundId;
  final String playerId;
  final String? userId;
  final String holeId;
  final String? clubId;
  final String? clubName;
  final ShotLifecycle status;
  final double startLatitude;
  final double startLongitude;
  final double? startElevation;
  final double? endLatitude;
  final double? endLongitude;
  final double? endElevation;
  final double? elevationDelta;
  final double? distance;
  final DistanceUnitType distanceUnit;
  final ShotSyncStatus syncStatus;
  final DateTime createdAt;

  const ShotModel({
    required this.id,
    required this.roundId,
    required this.playerId,
    this.userId,
    required this.holeId,
    this.clubId,
    this.clubName,
    required this.status,
    required this.startLatitude,
    required this.startLongitude,
    this.startElevation,
    this.endLatitude,
    this.endLongitude,
    this.endElevation,
    this.elevationDelta,
    this.distance,
    this.distanceUnit = DistanceUnitType.yards,
    this.syncStatus = ShotSyncStatus.synced,
    required this.createdAt,
  });

  ShotModel copyWith({
    String? id,
    String? roundId,
    String? playerId,
    String? userId,
    String? holeId,
    String? clubId,
    String? clubName,
    ShotLifecycle? status,
    double? startLatitude,
    double? startLongitude,
    double? startElevation,
    double? endLatitude,
    double? endLongitude,
    double? endElevation,
    double? elevationDelta,
    double? distance,
    DistanceUnitType? distanceUnit,
    ShotSyncStatus? syncStatus,
    DateTime? createdAt,
  }) {
    return ShotModel(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      playerId: playerId ?? this.playerId,
      userId: userId ?? this.userId,
      holeId: holeId ?? this.holeId,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      status: status ?? this.status,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      startElevation: startElevation ?? this.startElevation,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      endElevation: endElevation ?? this.endElevation,
      elevationDelta: elevationDelta ?? this.elevationDelta,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ShotModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'STARTED').toUpperCase();
    final ShotLifecycle status;
    if (statusStr == 'SAVED') {
      status = ShotLifecycle.saved;
    } else if (statusStr == 'READY') {
      status = ShotLifecycle.ready;
    } else {
      status = ShotLifecycle.started;
    }

    final syncStr = (json['syncStatus'] as String? ?? 'synced').toLowerCase();
    final ShotSyncStatus syncStatus;
    if (syncStr == 'pending') {
      syncStatus = ShotSyncStatus.pending;
    } else if (syncStr == 'failed') {
      syncStatus = ShotSyncStatus.failed;
    } else {
      syncStatus = ShotSyncStatus.synced;
    }

    return ShotModel(
      id: json['id'] as String,
      roundId: (json['roundId'] ?? json['round_id']) as String,
      playerId: (json['playerId'] ?? json['player_id']) as String,
      userId: (json['userId'] ?? json['user_id']) as String?,
      holeId: (json['holeId'] ?? json['hole_id']) as String,
      clubId: (json['clubId'] ?? json['club_id']) as String?,
      clubName: json['club'] != null
          ? (json['club']['custom_name'] ?? json['club']['customName'] ?? json['club']['club_type'])
          : json['clubName'] as String?,
      status: status,
      startLatitude: ((json['startLatitude'] ?? json['start_latitude']) as num).toDouble(),
      startLongitude: ((json['startLongitude'] ?? json['start_longitude']) as num).toDouble(),
      startElevation: ((json['startElevation'] ?? json['start_elevation']) as num?)?.toDouble(),
      endLatitude: ((json['endLatitude'] ?? json['end_latitude']) as num?)?.toDouble(),
      endLongitude: ((json['endLongitude'] ?? json['end_longitude']) as num?)?.toDouble(),
      endElevation: ((json['endElevation'] ?? json['end_elevation']) as num?)?.toDouble(),
      elevationDelta: ((json['elevationDelta'] ?? json['elevation_delta']) as num?)?.toDouble(),
      distance: ((json['distance']) as num?)?.toDouble(),
      distanceUnit: DistanceUnitTypeExtension.fromString(
        (json['distanceUnit'] ?? json['distance_unit']) as String?,
      ),
      syncStatus: syncStatus,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundId': roundId,
      'playerId': playerId,
      'userId': userId,
      'holeId': holeId,
      'clubId': clubId,
      'clubName': clubName,
      'status': status.name.toUpperCase(),
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'startElevation': startElevation,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'endElevation': endElevation,
      'elevationDelta': elevationDelta,
      'distance': distance,
      'distanceUnit': distanceUnit.nameUpper,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

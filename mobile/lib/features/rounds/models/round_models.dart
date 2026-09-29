import '../../game_modes/game_mode_engine.dart';

enum RoundStatus {
  notStarted,
  inProgress,
  completed,
  cancelled,
}

extension RoundStatusExtension on RoundStatus {
  String get value {
    switch (this) {
      case RoundStatus.notStarted:
        return 'NOT_STARTED';
      case RoundStatus.inProgress:
        return 'IN_PROGRESS';
      case RoundStatus.completed:
        return 'COMPLETED';
      case RoundStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static RoundStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'IN_PROGRESS':
        return RoundStatus.inProgress;
      case 'COMPLETED':
        return RoundStatus.completed;
      case 'CANCELLED':
        return RoundStatus.cancelled;
      default:
        return RoundStatus.notStarted;
    }
  }
}

class RoundPlayerModel {
  final String id;
  final String roundId;
  final String? userId;
  final String playerName;
  final int playerOrder;
  final String? teamId;

  const RoundPlayerModel({
    required this.id,
    required this.roundId,
    this.userId,
    required this.playerName,
    required this.playerOrder,
    this.teamId,
  });

  factory RoundPlayerModel.fromJson(Map<String, dynamic> json) {
    return RoundPlayerModel(
      id: json['id'] as String,
      roundId: json['roundId'] as String? ?? '',
      userId: json['userId'] as String?,
      playerName: json['playerName'] as String,
      playerOrder: json['playerOrder'] as int,
      teamId: json['teamId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'userId': userId,
        'playerName': playerName,
        'playerOrder': playerOrder,
        'teamId': teamId,
      };
}

class RoundScoreModel {
  final String id;
  final String roundId;
  final String playerId;
  final String holeId;
  int grossScore;
  int putts;
  int penalties;
  FairwayHit? fairwayHit;
  bool? gir;

  RoundScoreModel({
    required this.id,
    required this.roundId,
    required this.playerId,
    required this.holeId,
    required this.grossScore,
    this.putts = 0,
    this.penalties = 0,
    this.fairwayHit,
    this.gir,
  });

  factory RoundScoreModel.fromJson(Map<String, dynamic> json) {
    return RoundScoreModel(
      id: json['id'] as String,
      roundId: json['roundId'] as String? ?? '',
      playerId: json['playerId'] as String,
      holeId: json['holeId'] as String,
      grossScore: json['grossScore'] as int,
      putts: json['putts'] as int? ?? 0,
      penalties: json['penalties'] as int? ?? 0,
      fairwayHit: FairwayHitExtension.fromString(json['fairwayHit'] as String?),
      gir: json['gir'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'playerId': playerId,
        'holeId': holeId,
        'grossScore': grossScore,
        'putts': putts,
        'penalties': penalties,
        'fairwayHit': fairwayHit?.value,
        'gir': gir,
      };
}

class PlayerScorecardTotal {
  final String playerId;
  final String playerName;
  final int playerOrder;
  final String? teamId;
  final int grossScore;
  final int putts;
  final int penalties;
  final int firCount;
  final int firPossible;
  final int girCount;
  final int girPossible;
  final int holesCompleted;

  const PlayerScorecardTotal({
    required this.playerId,
    required this.playerName,
    required this.playerOrder,
    this.teamId,
    required this.grossScore,
    required this.putts,
    required this.penalties,
    required this.firCount,
    required this.firPossible,
    required this.girCount,
    required this.girPossible,
    required this.holesCompleted,
  });

  factory PlayerScorecardTotal.fromJson(Map<String, dynamic> json) {
    return PlayerScorecardTotal(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      playerOrder: json['playerOrder'] as int,
      teamId: json['teamId'] as String?,
      grossScore: json['grossScore'] as int? ?? 0,
      putts: json['putts'] as int? ?? 0,
      penalties: json['penalties'] as int? ?? 0,
      firCount: json['firCount'] as int? ?? 0,
      firPossible: json['firPossible'] as int? ?? 0,
      girCount: json['girCount'] as int? ?? 0,
      girPossible: json['girPossible'] as int? ?? 0,
      holesCompleted: json['holesCompleted'] as int? ?? 0,
    );
  }
}

class ScorecardHoleInfo {
  final String id;
  final int holeNumber;
  final int par;
  final int? handicapIndex;

  const ScorecardHoleInfo({
    required this.id,
    required this.holeNumber,
    required this.par,
    this.handicapIndex,
  });

  factory ScorecardHoleInfo.fromJson(Map<String, dynamic> json) {
    return ScorecardHoleInfo(
      id: json['id'] as String,
      holeNumber: json['holeNumber'] as int,
      par: json['par'] as int,
      handicapIndex: json['handicapIndex'] as int?,
    );
  }
}

class ScorecardMatrix {
  final String roundId;
  final GameMode gameMode;
  final RoundStatus status;
  final int currentHole;
  final List<ScorecardHoleInfo> holes;
  final List<RoundPlayerModel> players;
  final List<RoundScoreModel> scores;
  final List<PlayerScorecardTotal> totals;

  const ScorecardMatrix({
    required this.roundId,
    required this.gameMode,
    required this.status,
    required this.currentHole,
    required this.holes,
    required this.players,
    required this.scores,
    required this.totals,
  });

  factory ScorecardMatrix.fromJson(Map<String, dynamic> json) {
    final roundData = json['round'] as Map<String, dynamic>? ?? {};
    final holesList = (json['holes'] as List? ?? [])
        .map((h) => ScorecardHoleInfo.fromJson(h as Map<String, dynamic>))
        .toList();
    final playersList = (json['players'] as List? ?? [])
        .map((p) => RoundPlayerModel.fromJson(p as Map<String, dynamic>))
        .toList();
    final scoresList = (json['scores'] as List? ?? [])
        .map((s) => RoundScoreModel.fromJson(s as Map<String, dynamic>))
        .toList();
    final totalsList = (json['totals'] as List? ?? [])
        .map((t) => PlayerScorecardTotal.fromJson(t as Map<String, dynamic>))
        .toList();

    return ScorecardMatrix(
      roundId: roundData['id'] as String? ?? '',
      gameMode: GameModeExtension.fromString(roundData['gameMode'] as String? ?? 'STROKE_PLAY'),
      status: RoundStatusExtension.fromString(roundData['status'] as String? ?? 'NOT_STARTED'),
      currentHole: roundData['currentHole'] as int? ?? 1,
      holes: holesList,
      players: playersList,
      scores: scoresList,
      totals: totalsList,
    );
  }
}

class RoundModel {
  final String id;
  final String courseId;
  final GameMode gameMode;
  RoundStatus status;
  int currentHole;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<RoundPlayerModel> players;

  RoundModel({
    required this.id,
    required this.courseId,
    required this.gameMode,
    required this.status,
    required this.currentHole,
    this.startedAt,
    this.finishedAt,
    this.players = const [],
  });

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    final playersList = (json['players'] as List? ?? [])
        .map((p) => RoundPlayerModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return RoundModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      gameMode: GameModeExtension.fromString(json['gameMode'] as String),
      status: RoundStatusExtension.fromString(json['status'] as String),
      currentHole: json['currentHole'] as int? ?? 1,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'] as String) : null,
      players: playersList,
    );
  }
}

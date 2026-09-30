import '../../rounds/models/round_models.dart';
import '../../game_modes/game_mode_engine.dart';

enum LivePlayConnectionStatus {
  connected,
  connecting,
  reconnecting,
  disconnected,
  error,
}

class LivePlayHole {
  final String id;
  final int holeNumber;
  final int par;
  final int? handicapIndex;

  const LivePlayHole({
    required this.id,
    required this.holeNumber,
    required this.par,
    this.handicapIndex,
  });

  factory LivePlayHole.fromJson(Map<String, dynamic> json) {
    return LivePlayHole(
      id: json['id'] as String? ?? '',
      holeNumber: json['holeNumber'] as int? ?? 1,
      par: json['par'] as int? ?? 4,
      handicapIndex: json['handicapIndex'] as int?,
    );
  }
}

class LivePlayScore {
  final String id;
  final String playerId;
  final String holeId;
  final int grossScore;
  final int putts;
  final int penalties;
  final String? fairwayHit;
  final bool? gir;

  const LivePlayScore({
    required this.id,
    required this.playerId,
    required this.holeId,
    required this.grossScore,
    this.putts = 0,
    this.penalties = 0,
    this.fairwayHit,
    this.gir,
  });

  factory LivePlayScore.fromJson(Map<String, dynamic> json) {
    return LivePlayScore(
      id: json['id'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      holeId: json['holeId'] as String? ?? '',
      grossScore: json['grossScore'] as int? ?? 0,
      putts: json['putts'] as int? ?? 0,
      penalties: json['penalties'] as int? ?? 0,
      fairwayHit: json['fairwayHit'] as String?,
      gir: json['gir'] as bool?,
    );
  }
}

class LivePlayPlayerSummary {
  final String playerId;
  final String? userId;
  final String playerName;
  final int playerOrder;
  final String? teamId;
  final int grossScore;
  final int toPar;
  final String thru;
  final int holesCompleted;
  final int totalPutts;
  final int totalPenalties;

  const LivePlayPlayerSummary({
    required this.playerId,
    this.userId,
    required this.playerName,
    required this.playerOrder,
    this.teamId,
    required this.grossScore,
    required this.toPar,
    required this.thru,
    required this.holesCompleted,
    this.totalPutts = 0,
    this.totalPenalties = 0,
  });

  factory LivePlayPlayerSummary.fromJson(Map<String, dynamic> json) {
    return LivePlayPlayerSummary(
      playerId: json['playerId'] as String? ?? '',
      userId: json['userId'] as String?,
      playerName: json['playerName'] as String? ?? 'Player',
      playerOrder: json['playerOrder'] as int? ?? 1,
      teamId: json['teamId'] as String?,
      grossScore: json['grossScore'] as int? ?? 0,
      toPar: json['toPar'] as int? ?? 0,
      thru: json['thru'] as String? ?? '-',
      holesCompleted: json['holesCompleted'] as int? ?? 0,
      totalPutts: json['totalPutts'] as int? ?? 0,
      totalPenalties: json['totalPenalties'] as int? ?? 0,
    );
  }

  String get formattedToPar {
    if (holesCompleted == 0) return 'E';
    if (toPar == 0) return 'E';
    if (toPar > 0) return '+$toPar';
    return '$toPar';
  }
}

class LivePlayStateModel {
  final String roundId;
  final String courseName;
  final GameMode gameMode;
  final String roundStatus;
  final int currentHole;
  final List<RoundPlayerModel> players;
  final List<LivePlayHole> holes;
  final List<LivePlayScore> scores;
  final List<LivePlayPlayerSummary> playerSummaries;
  final Map<String, dynamic> leaderboard;

  const LivePlayStateModel({
    required this.roundId,
    required this.courseName,
    required this.gameMode,
    required this.roundStatus,
    required this.currentHole,
    required this.players,
    required this.holes,
    required this.scores,
    required this.playerSummaries,
    required this.leaderboard,
  });

  factory LivePlayStateModel.fromJson(Map<String, dynamic> json) {
    final roundJson = json['round'] as Map<String, dynamic>? ?? {};
    final courseJson = json['course'] as Map<String, dynamic>? ?? {};

    final playersList = (json['players'] as List<dynamic>? ?? [])
        .map((p) => RoundPlayerModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final holesList = (json['holes'] as List<dynamic>? ?? [])
        .map((h) => LivePlayHole.fromJson(h as Map<String, dynamic>))
        .toList();

    final scoresList = (json['scores'] as List<dynamic>? ?? [])
        .map((s) => LivePlayScore.fromJson(s as Map<String, dynamic>))
        .toList();

    final summariesList = (json['playerSummaries'] as List<dynamic>? ?? [])
        .map((ps) => LivePlayPlayerSummary.fromJson(ps as Map<String, dynamic>))
        .toList();

    final rawGameMode = roundJson['gameMode'] as String? ?? 'STROKE_PLAY';
    final gameMode = GameModeExtension.fromString(rawGameMode);

    return LivePlayStateModel(
      roundId: roundJson['id'] as String? ?? json['roundId'] as String? ?? '',
      courseName: courseJson['name'] as String? ?? 'Golf Course',
      gameMode: gameMode,
      roundStatus: roundJson['status'] as String? ?? 'IN_PROGRESS',
      currentHole: json['currentHole'] as int? ?? roundJson['currentHole'] as int? ?? 1,
      players: playersList,
      holes: holesList,
      scores: scoresList,
      playerSummaries: summariesList,
      leaderboard: json['leaderboard'] as Map<String, dynamic>? ?? {},
    );
  }
}

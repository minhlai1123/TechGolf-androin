class HandicapCurrentModel {
  final String userId;
  final double handicapIndex;
  final bool isEstablished;
  final int roundsCount;
  final DateTime? lastCalculatedAt;
  final String status;
  final String message;

  const HandicapCurrentModel({
    required this.userId,
    required this.handicapIndex,
    required this.isEstablished,
    required this.roundsCount,
    this.lastCalculatedAt,
    required this.status,
    required this.message,
  });

  factory HandicapCurrentModel.fromJson(Map<String, dynamic> json) {
    return HandicapCurrentModel(
      userId: json['userId'] as String? ?? '',
      handicapIndex: (json['handicapIndex'] as num?)?.toDouble() ?? 54.0,
      isEstablished: json['isEstablished'] as bool? ?? false,
      roundsCount: json['roundsCount'] as int? ?? 0,
      lastCalculatedAt: json['lastCalculatedAt'] != null
          ? DateTime.tryParse(json['lastCalculatedAt'].toString())
          : null,
      status: json['status'] as String? ?? 'INSUFFICIENT_ROUNDS',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'handicapIndex': handicapIndex,
        'isEstablished': isEstablished,
        'roundsCount': roundsCount,
        'lastCalculatedAt': lastCalculatedAt?.toIso8601String(),
        'status': status,
        'message': message,
      };
}

class HandicapHistoryModel {
  final String id;
  final double? previousHandicapIndex;
  final double resultingHandicapIndex;
  final int? differentialsUsedCount;
  final int? roundsCount;
  final String? status;
  final DateTime calculatedAt;

  const HandicapHistoryModel({
    required this.id,
    this.previousHandicapIndex,
    required this.resultingHandicapIndex,
    this.differentialsUsedCount,
    this.roundsCount,
    this.status,
    required this.calculatedAt,
  });

  factory HandicapHistoryModel.fromJson(Map<String, dynamic> json) {
    return HandicapHistoryModel(
      id: json['id'] as String? ?? '',
      previousHandicapIndex: (json['previous_handicap_index'] as num?)?.toDouble(),
      resultingHandicapIndex: (json['resulting_handicap_index'] as num?)?.toDouble() ?? 54.0,
      differentialsUsedCount: json['differentials_used_count'] as int?,
      roundsCount: json['rounds_count'] as int?,
      status: json['status'] as String?,
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'].toString())
          : DateTime.now(),
    );
  }
}

class ScoreDifferentialModel {
  final String id;
  final String roundId;
  final String courseName;
  final String? teeName;
  final int grossScore;
  final int adjustedGrossScore;
  final double courseRating;
  final int slopeRating;
  final double pccAdjustment;
  final double scoreDifferential;
  final DateTime playedAt;

  const ScoreDifferentialModel({
    required this.id,
    required this.roundId,
    required this.courseName,
    this.teeName,
    required this.grossScore,
    required this.adjustedGrossScore,
    required this.courseRating,
    required this.slopeRating,
    required this.pccAdjustment,
    required this.scoreDifferential,
    required this.playedAt,
  });

  factory ScoreDifferentialModel.fromJson(Map<String, dynamic> json) {
    return ScoreDifferentialModel(
      id: json['id'] as String? ?? '',
      roundId: json['round_id'] as String? ?? '',
      courseName: json['course'] != null && json['course']['name'] != null
          ? json['course']['name'].toString()
          : 'Golf Course',
      teeName: json['courseTee'] != null && json['courseTee']['tee_name'] != null
          ? json['courseTee']['tee_name'].toString()
          : null,
      grossScore: json['gross_score'] as int? ?? 0,
      adjustedGrossScore: json['adjusted_gross_score'] as int? ?? 0,
      courseRating: (json['course_rating'] as num?)?.toDouble() ?? 72.0,
      slopeRating: json['slope_rating'] as int? ?? 113,
      pccAdjustment: (json['pcc_adjustment'] as num?)?.toDouble() ?? 0.0,
      scoreDifferential: (json['score_differential'] as num?)?.toDouble() ?? 0.0,
      playedAt: json['played_at'] != null
          ? DateTime.parse(json['played_at'].toString())
          : DateTime.now(),
    );
  }
}

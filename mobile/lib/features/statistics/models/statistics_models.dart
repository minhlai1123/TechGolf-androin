class FirModel {
  final int hitCount;
  final int missLeftCount;
  final int missRightCount;
  final int totalOpportunities;
  final double? percentage;

  const FirModel({
    required this.hitCount,
    required this.missLeftCount,
    required this.missRightCount,
    required this.totalOpportunities,
    this.percentage,
  });

  factory FirModel.fromJson(Map<String, dynamic> json) {
    return FirModel(
      hitCount: json['hitCount'] as int? ?? 0,
      missLeftCount: json['missLeftCount'] as int? ?? 0,
      missRightCount: json['missRightCount'] as int? ?? 0,
      totalOpportunities: json['totalOpportunities'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }
}

class GirModel {
  final int hitCount;
  final int missCount;
  final int totalOpportunities;
  final double? percentage;

  const GirModel({
    required this.hitCount,
    required this.missCount,
    required this.totalOpportunities,
    this.percentage,
  });

  factory GirModel.fromJson(Map<String, dynamic> json) {
    return GirModel(
      hitCount: json['hitCount'] as int? ?? 0,
      missCount: json['missCount'] as int? ?? 0,
      totalOpportunities: json['totalOpportunities'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }
}

class PuttsModel {
  final int totalPutts;
  final double? puttsPerHole;
  final double? puttsPerGir;
  final int onePuttsCount;
  final int twoPuttsCount;
  final int threeOrMorePuttsCount;
  final int totalHolesWithPutts;

  const PuttsModel({
    required this.totalPutts,
    this.puttsPerHole,
    this.puttsPerGir,
    required this.onePuttsCount,
    required this.twoPuttsCount,
    required this.threeOrMorePuttsCount,
    required this.totalHolesWithPutts,
  });

  factory PuttsModel.fromJson(Map<String, dynamic> json) {
    return PuttsModel(
      totalPutts: json['totalPutts'] as int? ?? 0,
      puttsPerHole: (json['puttsPerHole'] as num?)?.toDouble(),
      puttsPerGir: (json['puttsPerGir'] as num?)?.toDouble(),
      onePuttsCount: json['onePuttsCount'] as int? ?? 0,
      twoPuttsCount: json['twoPuttsCount'] as int? ?? 0,
      threeOrMorePuttsCount: json['threeOrMorePuttsCount'] as int? ?? 0,
      totalHolesWithPutts: json['totalHolesWithPutts'] as int? ?? 0,
    );
  }
}

class ScramblingModel {
  final int successCount;
  final int opportunitiesCount;
  final double? percentage;
  final String status; // 'AVAILABLE' | 'NO_OPPORTUNITIES'
  final String? message;

  const ScramblingModel({
    required this.successCount,
    required this.opportunitiesCount,
    this.percentage,
    required this.status,
    this.message,
  });

  factory ScramblingModel.fromJson(Map<String, dynamic> json) {
    return ScramblingModel(
      successCount: json['successCount'] as int? ?? 0,
      opportunitiesCount: json['opportunitiesCount'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'NO_OPPORTUNITIES',
      message: json['message'] as String?,
    );
  }

  bool get hasOpportunities => opportunitiesCount > 0 && status == 'AVAILABLE';
}

class ParBreakdownModel {
  final double? par3Average;
  final double? par4Average;
  final double? par5Average;

  const ParBreakdownModel({
    this.par3Average,
    this.par4Average,
    this.par5Average,
  });

  factory ParBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ParBreakdownModel(
      par3Average: (json['par3Average'] as num?)?.toDouble(),
      par4Average: (json['par4Average'] as num?)?.toDouble(),
      par5Average: (json['par5Average'] as num?)?.toDouble(),
    );
  }
}

class ScoreDistributionModel {
  final int eaglesOrBetter;
  final int birdies;
  final int pars;
  final int bogeys;
  final int doubleBogeys;
  final int tripleOrWorse;

  const ScoreDistributionModel({
    required this.eaglesOrBetter,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.doubleBogeys,
    required this.tripleOrWorse,
  });

  factory ScoreDistributionModel.fromJson(Map<String, dynamic> json) {
    return ScoreDistributionModel(
      eaglesOrBetter: json['eaglesOrBetter'] as int? ?? 0,
      birdies: json['birdies'] as int? ?? 0,
      pars: json['pars'] as int? ?? 0,
      bogeys: json['bogeys'] as int? ?? 0,
      doubleBogeys: json['doubleBogeys'] as int? ?? 0,
      tripleOrWorse: json['tripleOrWorse'] as int? ?? 0,
    );
  }
}

class StatsOverviewModel {
  final int roundsPlayed;
  final int totalHolesPlayed;
  final double? scoringAverage;
  final int? bestScore;
  final FirModel fir;
  final GirModel gir;
  final PuttsModel putts;
  final ScramblingModel scrambling;
  final ParBreakdownModel parBreakdown;
  final ScoreDistributionModel scoreDistribution;

  const StatsOverviewModel({
    required this.roundsPlayed,
    required this.totalHolesPlayed,
    this.scoringAverage,
    this.bestScore,
    required this.fir,
    required this.gir,
    required this.putts,
    required this.scrambling,
    required this.parBreakdown,
    required this.scoreDistribution,
  });

  factory StatsOverviewModel.fromJson(Map<String, dynamic> json) {
    return StatsOverviewModel(
      roundsPlayed: json['roundsPlayed'] as int? ?? 0,
      totalHolesPlayed: json['totalHolesPlayed'] as int? ?? 0,
      scoringAverage: (json['scoringAverage'] as num?)?.toDouble(),
      bestScore: json['bestScore'] as int?,
      fir: json['fir'] != null
          ? FirModel.fromJson(json['fir'] as Map<String, dynamic>)
          : const FirModel(hitCount: 0, missLeftCount: 0, missRightCount: 0, totalOpportunities: 0),
      gir: json['gir'] != null
          ? GirModel.fromJson(json['gir'] as Map<String, dynamic>)
          : const GirModel(hitCount: 0, missCount: 0, totalOpportunities: 0),
      putts: json['putts'] != null
          ? PuttsModel.fromJson(json['putts'] as Map<String, dynamic>)
          : const PuttsModel(
              totalPutts: 0,
              onePuttsCount: 0,
              twoPuttsCount: 0,
              threeOrMorePuttsCount: 0,
              totalHolesWithPutts: 0,
            ),
      scrambling: json['scrambling'] != null
          ? ScramblingModel.fromJson(json['scrambling'] as Map<String, dynamic>)
          : const ScramblingModel(
              successCount: 0,
              opportunitiesCount: 0,
              status: 'NO_OPPORTUNITIES',
            ),
      parBreakdown: json['parBreakdown'] != null
          ? ParBreakdownModel.fromJson(json['parBreakdown'] as Map<String, dynamic>)
          : const ParBreakdownModel(),
      scoreDistribution: json['scoreDistribution'] != null
          ? ScoreDistributionModel.fromJson(json['scoreDistribution'] as Map<String, dynamic>)
          : const ScoreDistributionModel(
              eaglesOrBetter: 0,
              birdies: 0,
              pars: 0,
              bogeys: 0,
              doubleBogeys: 0,
              tripleOrWorse: 0,
            ),
    );
  }
}

class TrendPointModel {
  final String roundId;
  final DateTime roundDate;
  final String courseName;
  final int grossScore;
  final double? scoreDifferential;
  final double? firPercentage;
  final double? girPercentage;
  final int? totalPutts;

  const TrendPointModel({
    required this.roundId,
    required this.roundDate,
    required this.courseName,
    required this.grossScore,
    this.scoreDifferential,
    this.firPercentage,
    this.girPercentage,
    this.totalPutts,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      roundId: json['roundId'] as String? ?? '',
      roundDate: json['roundDate'] != null
          ? DateTime.parse(json['roundDate'].toString())
          : DateTime.now(),
      courseName: json['courseName'] as String? ?? 'Golf Course',
      grossScore: json['grossScore'] as int? ?? 0,
      scoreDifferential: (json['scoreDifferential'] as num?)?.toDouble(),
      firPercentage: (json['firPercentage'] as num?)?.toDouble(),
      girPercentage: (json['girPercentage'] as num?)?.toDouble(),
      totalPutts: json['totalPutts'] as int?,
    );
  }
}

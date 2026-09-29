import '../../core/geo/distance_engine.dart';
import '../../core/geo/plays_like_engine.dart';
import '../shots/models/shot_models.dart';

class ClubCandidate {
  final String clubId;
  final String clubName;
  final String clubType;
  final double averageDistance;
  final double difference; // expected - remaining

  const ClubCandidate({
    required this.clubId,
    required this.clubName,
    required this.clubType,
    required this.averageDistance,
    required this.difference,
  });
}

class ClubRecommendation {
  final bool hasRecommendation;
  final ClubCandidate? recommendedClub;
  final double? expectedDistance;
  final double? difference;
  final DistanceUnitType unit;
  final double remainingDistance;
  final List<ClubCandidate> candidates;
  final String message;

  const ClubRecommendation({
    required this.hasRecommendation,
    this.recommendedClub,
    this.expectedDistance,
    this.difference,
    required this.unit,
    required this.remainingDistance,
    required this.candidates,
    required this.message,
  });
}

class MobileClubRecommendationEngine {
  /// Recommends the optimal club based on remaining target distance and player's recorded club averages.
  static ClubRecommendation recommend({
    required double remainingDistance,
    required DistanceUnitType unit,
    required List<ClubDistanceModel> clubs,
  }) {
    final double validRemaining = remainingDistance < 0 ? 0.0 : remainingDistance;

    // Filter active clubs with valid shot history (>0 shots and average >0 meters)
    final validClubs = clubs.where((c) =>
      c.isActive &&
      c.averageDistanceMeters > 0 &&
      c.totalShotsRecorded > 0
    ).toList();

    if (validClubs.isEmpty) {
      return ClubRecommendation(
        hasRecommendation: false,
        recommendedClub: null,
        expectedDistance: null,
        difference: null,
        unit: unit,
        remainingDistance: double.parse(validRemaining.toStringAsFixed(1)),
        candidates: const [],
        message: 'Not enough shot data. Save shots to build club averages.',
      );
    }

    final List<ClubCandidate> candidates = validClubs.map((c) {
      final double avgInUnit = unit == DistanceUnitType.yards
          ? DistanceEngine.metersToYards(c.averageDistanceMeters)
          : c.averageDistanceMeters;

      final double diff = avgInUnit - validRemaining;

      return ClubCandidate(
        clubId: c.id,
        clubName: c.displayName,
        clubType: c.clubType,
        averageDistance: double.parse(avgInUnit.toStringAsFixed(1)),
        difference: double.parse(diff.toStringAsFixed(1)),
      );
    }).toList();

    // Sort candidates by lowest absolute difference to remaining distance
    candidates.sort((a, b) =>
      (a.averageDistance - validRemaining).abs().compareTo(
        (b.averageDistance - validRemaining).abs(),
      ),
    );

    final best = candidates.first;
    final diffSign = best.difference >= 0 ? '+' : '';

    return ClubRecommendation(
      hasRecommendation: true,
      recommendedClub: best,
      expectedDistance: best.averageDistance,
      difference: best.difference,
      unit: unit,
      remainingDistance: double.parse(validRemaining.toStringAsFixed(1)),
      candidates: candidates,
      message: 'Recommended: ${best.clubName} (Avg: ${best.averageDistance} ${unit.label}, diff: $diffSign${best.difference} ${unit.label})',
    );
  }
}

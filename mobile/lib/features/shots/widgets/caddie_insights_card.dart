import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/geo/plays_like_engine.dart';
import '../../clubs/club_recommendation_engine.dart';
import '../models/shot_models.dart';

class CaddieInsightsCard extends StatelessWidget {
  final double remainingDistance;
  final DistanceUnitType unit;
  final double? startElevation;
  final double? targetElevation;
  final List<ClubDistanceModel> clubs;

  const CaddieInsightsCard({
    super.key,
    required this.remainingDistance,
    this.unit = DistanceUnitType.yards,
    this.startElevation,
    this.targetElevation,
    required this.clubs,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Plays Like
    final playsLike = PlaysLikeDistanceEngine.calculate(
      actualDistance: remainingDistance,
      startElevationMeters: startElevation,
      targetElevationMeters: targetElevation,
      unit: unit,
    );

    // 2. Compute Club Recommendation using Plays Like distance
    final recommendation = MobileClubRecommendationEngine.recommend(
      remainingDistance: playsLike.playsLikeDistance,
      unit: unit,
      clubs: clubs,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CADDIE INSIGHTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.accentGold,
                ),
              ),
              const Spacer(),
              if (playsLike.hasElevation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: playsLike.adjustment >= 0
                        ? AppTheme.primaryRed.withValues(alpha: 0.2)
                        : AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    playsLike.adjustment >= 0
                        ? '+${playsLike.adjustment.toStringAsFixed(0)} ${unit.label} Uphill'
                        : '${playsLike.adjustment.toStringAsFixed(0)} ${unit.label} Downhill',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: playsLike.adjustment >= 0 ? AppTheme.primaryRed : AppTheme.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTUAL', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    const SizedBox(height: 2),
                    Text(
                      '${playsLike.actualDistance.toStringAsFixed(0)} ${unit.label}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PLAYS LIKE', style: TextStyle(fontSize: 11, color: AppTheme.accentGold)),
                    const SizedBox(height: 2),
                    Text(
                      '${playsLike.playsLikeDistance.toStringAsFixed(0)} ${unit.label}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          if (recommendation.hasRecommendation && recommendation.recommendedClub != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_golf, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.recommendedClub!.clubName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your average: ${recommendation.recommendedClub!.averageDistance.toStringAsFixed(0)} ${unit.label}',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white38, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.message,
                    style: const TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

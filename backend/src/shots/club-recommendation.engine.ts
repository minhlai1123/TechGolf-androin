import { DistanceUnit } from './entities/shot.entity';
import { PlaysLikeEngine } from './plays-like.engine';

export interface ClubInfo {
  id: string;
  clubType: string;
  customName?: string | null;
  averageDistanceMeters: number;
  totalShotsRecorded: number;
  isActive?: boolean;
}

export interface ClubRecommendationCandidate {
  clubId: string;
  clubName: string;
  clubType: string;
  averageDistance: number; // in requested unit
  difference: number; // expected - remaining
}

export interface ClubRecommendationResult {
  hasRecommendation: boolean;
  recommendedClub: ClubRecommendationCandidate | null;
  expectedDistance: number | null;
  difference: number | null;
  unit: DistanceUnit;
  remainingDistance: number;
  candidates: ClubRecommendationCandidate[];
  message: string;
}

export class ClubRecommendationEngine {
  /**
   * Recommends the optimal club based on remaining target distance and user's club shot history.
   *
   * @param remainingDistance Distance to green/pin/target in [unit]
   * @param unit Target distance unit (YARDS or METERS)
   * @param clubs Available clubs from user's golf bag
   */
  public static recommend(
    remainingDistance: number,
    unit: DistanceUnit,
    clubs: ClubInfo[],
  ): ClubRecommendationResult {
    const validRemaining = Math.max(0, remainingDistance);

    // Filter active clubs with valid shot history (>0 shots and average >0 meters)
    const validClubs = (clubs || []).filter(
      (c) =>
        (c.isActive === undefined || c.isActive === true) &&
        Number(c.averageDistanceMeters) > 0 &&
        Number(c.totalShotsRecorded) > 0,
    );

    if (validClubs.length === 0) {
      return {
        hasRecommendation: false,
        recommendedClub: null,
        expectedDistance: null,
        difference: null,
        unit,
        remainingDistance: Number(validRemaining.toFixed(1)),
        candidates: [],
        message: 'Not enough shot data. Save shots to build club averages.',
      };
    }

    // Convert each club's average distance to the requested unit
    const candidates: ClubRecommendationCandidate[] = validClubs.map((club) => {
      const avgInUnit =
        unit === DistanceUnit.YARDS
          ? Number(club.averageDistanceMeters) * PlaysLikeEngine.METERS_TO_YARDS
          : Number(club.averageDistanceMeters);

      const displayName =
        club.customName && club.customName.trim().length > 0
          ? club.customName.trim()
          : club.clubType.replace(/_/g, ' ');

      return {
        clubId: club.id,
        clubName: displayName,
        clubType: club.clubType,
        averageDistance: Number(avgInUnit.toFixed(1)),
        difference: Number((avgInUnit - validRemaining).toFixed(1)),
      };
    });

    // Sort by absolute distance difference from remainingDistance
    candidates.sort(
      (a, b) =>
        Math.abs(a.averageDistance - validRemaining) -
        Math.abs(b.averageDistance - validRemaining),
    );

    const best = candidates[0];

    return {
      hasRecommendation: true,
      recommendedClub: best,
      expectedDistance: best.averageDistance,
      difference: best.difference,
      unit,
      remainingDistance: Number(validRemaining.toFixed(1)),
      candidates,
      message: `Recommended: ${best.clubName} (Avg: ${best.averageDistance} ${unit.toLowerCase()}, diff: ${best.difference >= 0 ? '+' : ''}${best.difference} ${unit.toLowerCase()})`,
    };
  }
}

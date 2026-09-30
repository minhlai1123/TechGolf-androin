import { ClubType } from '../golf-bag/entities/golf-bag-club.entity';
import { ShotCategory } from './strokes-gained.types';

export interface ShotClassificationInput {
  holePar: number;
  shotIndexOnHole: number; // 1-based (1 = tee shot)
  clubType?: ClubType | string | null;
  startDistanceToGreenMeters?: number | null;
  isOnGreen?: boolean | null;
}

export class StrokesGainedClassifier {
  /**
   * Distance threshold between Short Game and Approach (100 yards = 91.44 meters).
   */
  public static readonly SHORT_GAME_MAX_METERS = 91.44;

  /**
   * Classify a golf shot into Mark Broadie's standard Strokes Gained categories:
   * 1. DRIVING: Off-the-tee on Par 4 and Par 5 holes.
   * 2. APPROACH: Tee shots on Par 3 holes, and subsequent shots starting >100 yards from the green.
   * 3. SHORT_GAME: Shots starting within 100 yards (91.44m) of the green, but not on the putting surface.
   * 4. PUTTING: Any shot taken on the putting green or with a putter.
   * 5. UNKNOWN: If information is ambiguous or missing.
   */
  public static classifyShot(input: ShotClassificationInput): ShotCategory {
    const { holePar, shotIndexOnHole, clubType, startDistanceToGreenMeters, isOnGreen } = input;

    // 1. Putting surface check
    if (isOnGreen === true || clubType === ClubType.PUTTER) {
      return ShotCategory.PUTTING;
    }

    // 2. Off-The-Tee (Driving) check
    if (shotIndexOnHole === 1 && holePar >= 4) {
      return ShotCategory.DRIVING;
    }

    // 3. Par 3 Tee shot is considered Approach by Strokes Gained convention
    if (shotIndexOnHole === 1 && holePar === 3) {
      return ShotCategory.APPROACH;
    }

    // 4. Distance-based classification
    if (startDistanceToGreenMeters !== null && startDistanceToGreenMeters !== undefined && startDistanceToGreenMeters >= 0) {
      if (startDistanceToGreenMeters <= this.SHORT_GAME_MAX_METERS) {
        return ShotCategory.SHORT_GAME;
      }
      return ShotCategory.APPROACH;
    }

    // 5. Club-based fallback heuristic when GPS distance to green is missing
    if (clubType) {
      const wedgeTypes = [
        ClubType.PITCHING_WEDGE,
        ClubType.GAP_WEDGE,
        ClubType.SAND_WEDGE,
        ClubType.LOB_WEDGE,
      ];
      if (wedgeTypes.includes(clubType as ClubType)) {
        return ShotCategory.SHORT_GAME;
      }

      const longClubs = [
        ClubType.DRIVER,
        ClubType.WOOD_3,
        ClubType.WOOD_5,
        ClubType.HYBRID_3,
        ClubType.HYBRID_4,
        ClubType.IRON_3,
        ClubType.IRON_4,
        ClubType.IRON_5,
        ClubType.IRON_6,
        ClubType.IRON_7,
        ClubType.IRON_8,
        ClubType.IRON_9,
      ];
      if (longClubs.includes(clubType as ClubType)) {
        return ShotCategory.APPROACH;
      }
    }

    return ShotCategory.UNKNOWN;
  }
}

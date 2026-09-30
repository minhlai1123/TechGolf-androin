import { BadRequestException } from '@nestjs/common';

export interface HoleScoreInput {
  holeNumber: number;
  par: number;
  handicapIndex?: number;
  grossScore: number;
}

export interface HandicapCalculationResult {
  isEstablished: boolean;
  handicapIndex: number | null;
  differentialsUsed: number[];
  roundsCount: number;
  message: string;
}

export class WhsEngine {
  /**
   * Official USGA / R&A baseline slope rating constant.
   */
  public static readonly STANDARD_SLOPE_RATING = 113.0;

  /**
   * Maximum Handicap Index allowed by World Handicap System.
   */
  public static readonly MAX_HANDICAP_INDEX = 54.0;

  /**
   * Calculates WHS Score Differential:
   * Score Differential = (113 / Slope Rating) * (Adjusted Gross Score - Course Rating - PCC)
   *
   * @param adjustedGrossScore Total adjusted gross score for 18 holes
   * @param courseRating Course rating from CourseTee (e.g. 72.4)
   * @param slopeRating Slope rating from CourseTee (55 to 155, e.g. 130)
   * @param pcc Playing Conditions Calculation adjustment (-1.0 to +3.0, default 0.0)
   */
  public static calculateScoreDifferential(
    adjustedGrossScore: number,
    courseRating: number,
    slopeRating: number,
    pcc: number = 0.0,
  ): number {
    if (!slopeRating || slopeRating < 55 || slopeRating > 155) {
      throw new BadRequestException(
        `Invalid Slope Rating: ${slopeRating}. WHS standard slope rating must be between 55 and 155.`,
      );
    }

    if (!courseRating || courseRating <= 0) {
      throw new BadRequestException(`Invalid Course Rating: ${courseRating}. Course Rating must be positive.`);
    }

    if (!adjustedGrossScore || adjustedGrossScore <= 0) {
      throw new BadRequestException(`Invalid Adjusted Gross Score: ${adjustedGrossScore}. Must be greater than 0.`);
    }

    // Formula: 113 / Slope * (AGS - CR - PCC)
    const rawDiff = (this.STANDARD_SLOPE_RATING / slopeRating) * (adjustedGrossScore - courseRating - pcc);

    return Number(rawDiff.toFixed(1));
  }

  /**
   * Computes Adjusted Gross Score (AGS) using WHS Net Double Bogey rule:
   * Maximum score per hole for handicap purposes = Par + 2 + Handicap Strokes Received.
   * If golfer has no handicap, hole score is capped at Par + 5.
   */
  public static calculateAdjustedGrossScore(
    holeScores: HoleScoreInput[],
    playingHandicap: number = 0,
  ): number {
    if (!holeScores || holeScores.length === 0) {
      throw new BadRequestException('Hole scores are required to compute Adjusted Gross Score');
    }

    let totalAdjusted = 0;
    const roundedHcp = Math.max(0, Math.round(playingHandicap));

    for (const h of holeScores) {
      let maxScore: number;

      if (roundedHcp > 0 && h.handicapIndex !== undefined && h.handicapIndex !== null) {
        const baseStrokes = Math.floor(roundedHcp / 18);
        const remainder = roundedHcp % 18;
        const extraStroke = h.handicapIndex <= remainder ? 1 : 0;
        const strokesOnHole = baseStrokes + extraStroke;
        maxScore = h.par + 2 + strokesOnHole; // Net Double Bogey
      } else {
        // Unestablished handicap: Par + 5
        maxScore = h.par + 5;
      }

      const adjustedHole = Math.min(h.grossScore, maxScore);
      totalAdjusted += adjustedHole;
    }

    return totalAdjusted;
  }

  /**
   * Computes WHS Handicap Index based on recent Score Differentials.
   * Implements the official USGA / R&A World Handicap System sliding scale
   * for 3 to 20+ eligible rounds.
   *
   * @param differentials List of valid Score Differentials, ordered from most recent to oldest
   */
  public static calculateHandicapIndex(differentials: number[]): HandicapCalculationResult {
    if (!differentials || differentials.length < 3) {
      return {
        isEstablished: false,
        handicapIndex: null,
        differentialsUsed: [],
        roundsCount: differentials ? differentials.length : 0,
        message: 'Minimum 3 completed 18-hole rounds required to establish an official WHS Handicap Index.',
      };
    }

    // WHS takes the most recent 20 rounds
    const recentDifferentials = differentials.slice(0, 20);
    const count = recentDifferentials.length;

    // Sort ascending to easily pick the lowest (best) differentials
    const sorted = [...recentDifferentials].sort((a, b) => a - b);

    let numToUse: number;
    let adjustment: number;

    if (count === 3) {
      numToUse = 1;
      adjustment = -2.0; // Lowest 1 minus 2.0
    } else if (count === 4) {
      numToUse = 1;
      adjustment = -1.0; // Lowest 1 minus 1.0
    } else if (count === 5) {
      numToUse = 1;
      adjustment = 0.0; // Lowest 1
    } else if (count === 6) {
      numToUse = 2;
      adjustment = -1.0; // Lowest 2 average minus 1.0
    } else if (count === 7 || count === 8) {
      numToUse = 2;
      adjustment = 0.0; // Lowest 2 average
    } else if (count >= 9 && count <= 11) {
      numToUse = 3;
      adjustment = 0.0; // Lowest 3 average
    } else if (count >= 12 && count <= 14) {
      numToUse = 4;
      adjustment = 0.0; // Lowest 4 average
    } else if (count === 15 || count === 16) {
      numToUse = 5;
      adjustment = 0.0; // Lowest 5 average
    } else if (count === 17 || count === 18) {
      numToUse = 6;
      adjustment = 0.0; // Lowest 6 average
    } else if (count === 19) {
      numToUse = 7;
      adjustment = 0.0; // Lowest 7 average
    } else {
      // 20 or more rounds: lowest 8 differentials
      numToUse = 8;
      adjustment = 0.0;
    }

    const used = sorted.slice(0, numToUse);
    const sum = used.reduce((acc, val) => acc + val, 0);
    const average = sum / numToUse;
    const rawIndex = average + adjustment;

    // Handicap Index cannot be negative for standard index display (scratch = 0.0)
    // and cannot exceed WHS maximum limit of 54.0
    const clampedIndex = Math.min(this.MAX_HANDICAP_INDEX, Math.max(0.0, rawIndex));
    const finalIndex = Number(clampedIndex.toFixed(1));

    return {
      isEstablished: true,
      handicapIndex: finalIndex,
      differentialsUsed: used,
      roundsCount: count,
      message: `Calculated using lowest ${numToUse} of ${count} recent rounds${adjustment !== 0 ? ` (with ${adjustment > 0 ? '+' : ''}${adjustment.toFixed(1)} WHS scale adjustment)` : ''}.`,
    };
  }
}

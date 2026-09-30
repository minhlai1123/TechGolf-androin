export interface ScoreItem {
  holeNumber: number;
  par: number;
  grossScore: number;
  putts?: number | null;
  penalties?: number | null;
  fairwayHit?: string | null; // 'LEFT' | 'STRAIGHT' | 'RIGHT' | null
  gir?: boolean | null;
}

export interface FirResult {
  hitCount: number;
  missLeftCount: number;
  missRightCount: number;
  totalOpportunities: number;
  percentage: number | null;
}

export interface GirResult {
  hitCount: number;
  missCount: number;
  totalOpportunities: number;
  percentage: number | null;
}

export interface PuttsResult {
  totalPutts: number;
  puttsPerHole: number | null;
  puttsPerGir: number | null;
  onePuttsCount: number;
  twoPuttsCount: number;
  threeOrMorePuttsCount: number;
  totalHolesWithPutts: number;
}

export interface ScramblingResult {
  successCount: number;
  opportunitiesCount: number;
  percentage: number | null;
  status: 'AVAILABLE' | 'NO_OPPORTUNITIES';
  message: string | null;
}

export interface ScoreDistribution {
  eaglesOrBetter: number;
  birdies: number;
  pars: number;
  bogeys: number;
  doubleBogeys: number;
  tripleOrWorse: number;
}

export interface ParBreakdown {
  par3Average: number | null;
  par3HolesCount: number;
  par4Average: number | null;
  par4HolesCount: number;
  par5Average: number | null;
  par5HolesCount: number;
}

export class StatisticsEngine {
  /**
   * Fairways in Regulation (FIR) calculation.
   * Standard Golf Rule: Only holes with Par >= 4 qualify. Par 3 holes are strictly excluded.
   * Holes where fairway hit tracking was not recorded (fairwayHit is null) are excluded from denominator.
   */
  public static calculateFIR(scores: ScoreItem[]): FirResult {
    const validHoles = scores.filter(
      (s) => s.par >= 4 && s.fairwayHit !== null && s.fairwayHit !== undefined && s.fairwayHit !== '',
    );

    const hitCount = validHoles.filter((s) => s.fairwayHit?.toUpperCase() === 'STRAIGHT').length;
    const missLeftCount = validHoles.filter((s) => s.fairwayHit?.toUpperCase() === 'LEFT').length;
    const missRightCount = validHoles.filter((s) => s.fairwayHit?.toUpperCase() === 'RIGHT').length;
    const totalOpportunities = validHoles.length;

    const percentage =
      totalOpportunities > 0
        ? Number(((hitCount / totalOpportunities) * 100).toFixed(1))
        : null;

    return {
      hitCount,
      missLeftCount,
      missRightCount,
      totalOpportunities,
      percentage,
    };
  }

  /**
   * Greens in Regulation (GIR) calculation.
   * A hole qualifies if gir tracking was explicitly set to true or false.
   * Holes with null GIR are excluded from denominator.
   */
  public static calculateGIR(scores: ScoreItem[]): GirResult {
    const validHoles = scores.filter(
      (s) => s.gir !== null && s.gir !== undefined,
    );

    const hitCount = validHoles.filter((s) => s.gir === true).length;
    const missCount = validHoles.filter((s) => s.gir === false).length;
    const totalOpportunities = validHoles.length;

    const percentage =
      totalOpportunities > 0
        ? Number(((hitCount / totalOpportunities) * 100).toFixed(1))
        : null;

    return {
      hitCount,
      missCount,
      totalOpportunities,
      percentage,
    };
  }

  /**
   * Putting Statistics calculation.
   */
  public static calculatePutts(scores: ScoreItem[]): PuttsResult {
    const holesWithPutts = scores.filter(
      (s) => s.putts !== null && s.putts !== undefined && s.putts >= 0,
    );

    const totalPutts = holesWithPutts.reduce((acc, s) => acc + (s.putts || 0), 0);
    const totalHolesWithPutts = holesWithPutts.length;

    const puttsPerHole =
      totalHolesWithPutts > 0
        ? Number((totalPutts / totalHolesWithPutts).toFixed(2))
        : null;

    const girHolesWithPutts = holesWithPutts.filter((s) => s.gir === true);
    const girPuttsTotal = girHolesWithPutts.reduce((acc, s) => acc + (s.putts || 0), 0);
    const puttsPerGir =
      girHolesWithPutts.length > 0
        ? Number((girPuttsTotal / girHolesWithPutts.length).toFixed(2))
        : null;

    const onePuttsCount = holesWithPutts.filter((s) => s.putts === 1).length;
    const twoPuttsCount = holesWithPutts.filter((s) => s.putts === 2).length;
    const threeOrMorePuttsCount = holesWithPutts.filter((s) => (s.putts || 0) >= 3).length;

    return {
      totalPutts,
      puttsPerHole,
      puttsPerGir,
      onePuttsCount,
      twoPuttsCount,
      threeOrMorePuttsCount,
      totalHolesWithPutts,
    };
  }

  /**
   * Scrambling calculation:
   * Opportunity: Golfer misses green in regulation (gir === false).
   * Success: Score on that hole is Par or better (grossScore <= par).
   * If there are 0 missed greens (or no GIR data), scrambling rate is NOT 0.0%,
   * but explicitly NO_OPPORTUNITIES with percentage = null.
   */
  public static calculateScrambling(scores: ScoreItem[]): ScramblingResult {
    const missedGirHoles = scores.filter((s) => s.gir === false);
    const opportunitiesCount = missedGirHoles.length;

    if (opportunitiesCount === 0) {
      return {
        successCount: 0,
        opportunitiesCount: 0,
        percentage: null,
        status: 'NO_OPPORTUNITIES',
        message: 'No missed greens or not enough GIR data to calculate scrambling.',
      };
    }

    const successCount = missedGirHoles.filter((s) => s.grossScore <= s.par).length;
    const percentage = Number(((successCount / opportunitiesCount) * 100).toFixed(1));

    return {
      successCount,
      opportunitiesCount,
      percentage,
      status: 'AVAILABLE',
      message: null,
    };
  }

  /**
   * Score distribution breakdown (Eagles, Birdies, Pars, Bogeys, etc.)
   */
  public static calculateScoreDistribution(scores: ScoreItem[]): ScoreDistribution {
    const dist: ScoreDistribution = {
      eaglesOrBetter: 0,
      birdies: 0,
      pars: 0,
      bogeys: 0,
      doubleBogeys: 0,
      tripleOrWorse: 0,
    };

    for (const s of scores) {
      const diff = s.grossScore - s.par;
      if (diff <= -2) {
        dist.eaglesOrBetter++;
      } else if (diff === -1) {
        dist.birdies++;
      } else if (diff === 0) {
        dist.pars++;
      } else if (diff === 1) {
        dist.bogeys++;
      } else if (diff === 2) {
        dist.doubleBogeys++;
      } else {
        dist.tripleOrWorse++;
      }
    }

    return dist;
  }

  /**
   * Scoring averages grouped by Par (Par 3, Par 4, Par 5)
   */
  public static calculateParBreakdown(scores: ScoreItem[]): ParBreakdown {
    const par3Holes = scores.filter((s) => s.par === 3);
    const par4Holes = scores.filter((s) => s.par === 4);
    const par5Holes = scores.filter((s) => s.par >= 5);

    const par3Average =
      par3Holes.length > 0
        ? Number(
            (par3Holes.reduce((acc, s) => acc + s.grossScore, 0) / par3Holes.length).toFixed(2),
          )
        : null;

    const par4Average =
      par4Holes.length > 0
        ? Number(
            (par4Holes.reduce((acc, s) => acc + s.grossScore, 0) / par4Holes.length).toFixed(2),
          )
        : null;

    const par5Average =
      par5Holes.length > 0
        ? Number(
            (par5Holes.reduce((acc, s) => acc + s.grossScore, 0) / par5Holes.length).toFixed(2),
          )
        : null;

    return {
      par3Average,
      par3HolesCount: par3Holes.length,
      par4Average,
      par4HolesCount: par4Holes.length,
      par5Average,
      par5HolesCount: par5Holes.length,
    };
  }
}

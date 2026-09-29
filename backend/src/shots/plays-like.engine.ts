import { DistanceUnit } from './entities/shot.entity';

export interface PlaysLikeResult {
  actualDistance: number;
  startElevation: number | null; // meters
  targetElevation: number | null; // meters
  elevationDeltaMeters: number | null; // meters (target - start)
  elevationDeltaUnit: number | null; // converted to requested distance unit
  adjustment: number; // added to actual distance in requested unit
  playsLikeDistance: number; // final plays like distance in requested unit
  unit: DistanceUnit;
  hasElevation: boolean;
  explanation: string;
}

export class PlaysLikeEngine {
  /**
   * Earth conversion constants:
   * 1 meter = 1.0936132983 yards
   * 1 yard = 0.9144 meters
   */
  public static readonly METERS_TO_YARDS = 1.0936132983;
  public static readonly YARDS_TO_METERS = 0.9144;

  /**
   * Standard Golf Slope Empirical Adjustment Factor:
   * 1 unit of elevation difference translates to approximately 1.0 unit of distance adjustment
   * for standard approach trajectories (35°–45° descent angle).
   */
  public static readonly DEFAULT_SLOPE_FACTOR = 1.0;

  /**
   * Calculates Plays Like Distance given horizontal geodesic distance and elevation points.
   *
   * @param actualDistance Horizontal distance in specified [unit]
   * @param startElevationMeters Elevation at ball/start position (in meters above sea level)
   * @param targetElevationMeters Elevation at target/flag position (in meters above sea level)
   * @param unit Distance unit: DistanceUnit.YARDS | DistanceUnit.METERS (default YARDS)
   * @param slopeFactor Empirical adjustment factor (default 1.0)
   */
  public static calculate(
    actualDistance: number,
    startElevationMeters: number | null | undefined,
    targetElevationMeters: number | null | undefined,
    unit: DistanceUnit = DistanceUnit.YARDS,
    slopeFactor: number = PlaysLikeEngine.DEFAULT_SLOPE_FACTOR,
  ): PlaysLikeResult {
    const validActual = Math.max(0, actualDistance);

    // If either start or target elevation is missing, elevation cannot be determined
    if (
      startElevationMeters === null ||
      startElevationMeters === undefined ||
      targetElevationMeters === null ||
      targetElevationMeters === undefined
    ) {
      return {
        actualDistance: Number(validActual.toFixed(1)),
        startElevation: null,
        targetElevation: null,
        elevationDeltaMeters: null,
        elevationDeltaUnit: null,
        adjustment: 0,
        playsLikeDistance: Number(validActual.toFixed(1)),
        unit,
        hasElevation: false,
        explanation: 'Elevation data unavailable. Plays Like equals actual distance.',
      };
    }

    // Delta = target - start (positive = uphill, negative = downhill)
    const deltaMeters = targetElevationMeters - startElevationMeters;

    // Convert elevation delta to target distance unit
    const deltaInUnit =
      unit === DistanceUnit.YARDS
        ? deltaMeters * PlaysLikeEngine.METERS_TO_YARDS
        : deltaMeters;

    // Adjustment: uphill adds distance, downhill subtracts distance
    const adjustment = deltaInUnit * slopeFactor;
    const playsLike = Math.max(0, validActual + adjustment);

    let slopeType = 'Flat';
    if (deltaMeters > 0.5) slopeType = 'Uphill';
    else if (deltaMeters < -0.5) slopeType = 'Downhill';

    return {
      actualDistance: Number(validActual.toFixed(1)),
      startElevation: Number(startElevationMeters.toFixed(1)),
      targetElevation: Number(targetElevationMeters.toFixed(1)),
      elevationDeltaMeters: Number(deltaMeters.toFixed(1)),
      elevationDeltaUnit: Number(deltaInUnit.toFixed(1)),
      adjustment: Number(adjustment.toFixed(1)),
      playsLikeDistance: Number(playsLike.toFixed(1)),
      unit,
      hasElevation: true,
      explanation: `${slopeType}: ${deltaMeters >= 0 ? '+' : ''}${deltaMeters.toFixed(1)}m (${deltaInUnit >= 0 ? '+' : ''}${deltaInUnit.toFixed(1)} ${unit.toLowerCase()}), adjustment: ${adjustment >= 0 ? '+' : ''}${adjustment.toFixed(1)} ${unit.toLowerCase()}`,
    };
  }

  /**
   * Geodesic Haversine distance calculation between two points in meters
   */
  public static distanceBetweenMeters(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
  ): number {
    const R = 6371000.0; // Earth mean radius in meters
    const toRad = (deg: number) => (deg * Math.PI) / 180.0;

    const phi1 = toRad(lat1);
    const phi2 = toRad(lat2);
    const deltaPhi = toRad(lat2 - lat1);
    const deltaLambda = toRad(lng2 - lng1);

    const a =
      Math.sin(deltaPhi / 2.0) * Math.sin(deltaPhi / 2.0) +
      Math.cos(phi1) *
        Math.cos(phi2) *
        Math.sin(deltaLambda / 2.0) *
        Math.sin(deltaLambda / 2.0);

    const c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));
    return R * c;
  }

  /**
   * Geodesic Haversine distance in yards
   */
  public static distanceBetweenYards(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
  ): number {
    return this.distanceBetweenMeters(lat1, lng1, lat2, lng2) * this.METERS_TO_YARDS;
  }
}

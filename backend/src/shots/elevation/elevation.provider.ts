export interface ElevationProvider {
  getElevation(latitude: number, longitude: number): Promise<number | null>;
}

/**
 * Default provider when no third-party DEM service (e.g. USGS, Open-Elevation, Mapbox Terrain)
 * is configured. Explicitly returns null rather than generating fake elevation.
 */
export class NullElevationProvider implements ElevationProvider {
  async getElevation(_latitude: number, _longitude: number): Promise<number | null> {
    return null;
  }
}

/**
 * Controllable elevation provider for testing and deterministic simulations.
 */
export class MockElevationProvider implements ElevationProvider {
  private readonly elevationMap = new Map<string, number>();
  private defaultElevation: number | null = null;

  constructor(defaultElevation: number | null = null) {
    this.defaultElevation = defaultElevation;
  }

  setElevation(latitude: number, longitude: number, elevationMeters: number): void {
    const key = `${latitude.toFixed(6)},${longitude.toFixed(6)}`;
    this.elevationMap.set(key, elevationMeters);
  }

  async getElevation(latitude: number, longitude: number): Promise<number | null> {
    const key = `${latitude.toFixed(6)},${longitude.toFixed(6)}`;
    if (this.elevationMap.has(key)) {
      return this.elevationMap.get(key)!;
    }
    return this.defaultElevation;
  }
}

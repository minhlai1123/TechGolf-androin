import {
  ShotCategory,
  BenchmarkStatus,
  StrokesGainedBenchmarkResult,
} from '../strokes-gained.types';

export interface IStrokesGainedBenchmarkProvider {
  getExpectedStrokes(
    category: ShotCategory,
    distanceMeters: number,
    lie?: string,
  ): Promise<StrokesGainedBenchmarkResult>;
}

/**
 * Default Production Benchmark Provider.
 * As per specification, because the reference PDF does not provide Mark Broadie / PGA Tour
 * baseline benchmark tables, this provider returns status 'UNAVAILABLE'.
 * The UI and API must explicitly report Strokes Gained data unavailable, NEVER faking 0.00.
 */
export class NullStrokesGainedBenchmarkProvider implements IStrokesGainedBenchmarkProvider {
  async getExpectedStrokes(
    _category: ShotCategory,
    _distanceMeters: number,
    _lie?: string,
  ): Promise<StrokesGainedBenchmarkResult> {
    return {
      status: 'UNAVAILABLE',
      expectedStrokes: null,
      reason: 'Strokes Gained benchmark reference tables (Mark Broadie / PGA Tour) are unavailable in project specifications.',
    };
  }
}

/**
 * Mock Strokes Gained Benchmark Provider for testing and deterministic validation.
 */
export class MockStrokesGainedBenchmarkProvider implements IStrokesGainedBenchmarkProvider {
  private status: BenchmarkStatus = 'AVAILABLE';
  private table: Map<string, number> = new Map();

  constructor(status: BenchmarkStatus = 'AVAILABLE') {
    this.status = status;
  }

  setStatus(status: BenchmarkStatus): void {
    this.status = status;
  }

  setBenchmark(key: string, expectedStrokes: number): void {
    this.table.set(key, expectedStrokes);
  }

  async getExpectedStrokes(
    category: ShotCategory,
    distanceMeters: number,
    _lie?: string,
  ): Promise<StrokesGainedBenchmarkResult> {
    if (this.status === 'UNAVAILABLE') {
      return {
        status: 'UNAVAILABLE',
        expectedStrokes: null,
        reason: 'Mock provider set to UNAVAILABLE',
      };
    }

    const key = `${category}_${Math.round(distanceMeters)}`;
    if (this.table.has(key)) {
      return {
        status: 'AVAILABLE',
        expectedStrokes: this.table.get(key)!,
      };
    }

    // Default mock heuristic formula when exact key is not set
    let expected = 2.0;
    if (category === ShotCategory.PUTTING) {
      expected = 1.0 + Math.min(1.5, distanceMeters / 10.0);
    } else if (category === ShotCategory.SHORT_GAME) {
      expected = 2.2 + distanceMeters / 100.0;
    } else if (category === ShotCategory.APPROACH) {
      expected = 2.8 + distanceMeters / 150.0;
    } else if (category === ShotCategory.DRIVING) {
      expected = 3.8 + distanceMeters / 250.0;
    }

    return {
      status: 'AVAILABLE',
      expectedStrokes: Number(expected.toFixed(2)),
    };
  }
}

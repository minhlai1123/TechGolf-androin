export interface PccResult {
  value: number; // In WHS, PCC is an integer from -1.0 to +3.0
  isAvailable: boolean; // false when no production weather / field score calculation data is available
  status: 'AVAILABLE' | 'UNAVAILABLE';
  reason?: string;
}

export interface PccProvider {
  getPcc(roundDate: Date, courseId: string): Promise<PccResult>;
}

/**
 * Production Default PCC Provider.
 * As per project requirements, since the PDF does not supply daily field score datasets
 * or external weather-adjusted scoring records for automatic PCC derivation,
 * this provider explicitly reports UNAVAILABLE and applies 0.0 adjustment without faking data.
 */
export class NullPccProvider implements PccProvider {
  async getPcc(_roundDate: Date, _courseId: string): Promise<PccResult> {
    return {
      value: 0.0,
      isAvailable: false,
      status: 'UNAVAILABLE',
      reason: 'Playing Conditions Calculation (PCC) requires statistical field scoring data across 8+ daily rounds, which is not currently available for this course date.',
    };
  }
}

/**
 * Mock PCC Provider for deterministic automated testing.
 */
export class MockPccProvider implements PccProvider {
  private pccValue: number = 0.0;
  private available: boolean = true;

  constructor(pccValue: number = 0.0, available: boolean = true) {
    this.pccValue = pccValue;
    this.available = available;
  }

  setPcc(value: number, available: boolean = true): void {
    this.pccValue = value;
    this.available = available;
  }

  async getPcc(_roundDate: Date, _courseId: string): Promise<PccResult> {
    return {
      value: this.pccValue,
      isAvailable: this.available,
      status: this.available ? 'AVAILABLE' : 'UNAVAILABLE',
      reason: this.available ? 'Mock PCC configured' : 'Mock PCC unavailable',
    };
  }
}

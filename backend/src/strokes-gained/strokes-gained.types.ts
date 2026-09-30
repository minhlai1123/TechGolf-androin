export enum ShotCategory {
  DRIVING = 'DRIVING',
  APPROACH = 'APPROACH',
  SHORT_GAME = 'SHORT_GAME',
  PUTTING = 'PUTTING',
  UNKNOWN = 'UNKNOWN',
}

export type BenchmarkStatus = 'AVAILABLE' | 'UNAVAILABLE';

export interface StrokesGainedBenchmarkResult {
  status: BenchmarkStatus;
  expectedStrokes: number | null;
  reason?: string;
}

export interface StrokesGainedCategorySummary {
  category: ShotCategory;
  shotsCount: number;
  strokesGained: number | null;
  status: BenchmarkStatus;
}

export interface StrokesGainedRoundSummary {
  status: BenchmarkStatus;
  totalStrokesGained: number | null;
  categories: Record<ShotCategory, StrokesGainedCategorySummary>;
  message: string;
}

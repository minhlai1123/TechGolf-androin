import { StatisticsEngine, ScoreItem } from '../src/statistics/statistics.engine';

describe('StatisticsEngine', () => {
  describe('calculateFIR (Fairways in Regulation)', () => {
    it('strictly excludes Par 3 holes and holes without fairway hit data', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, fairwayHit: 'STRAIGHT' }, // Hit
        { holeNumber: 2, par: 3, grossScore: 3, fairwayHit: 'STRAIGHT' }, // Par 3: EXCLUDED
        { holeNumber: 3, par: 4, grossScore: 5, fairwayHit: 'LEFT' }, // Miss Left
        { holeNumber: 4, par: 5, grossScore: 5, fairwayHit: 'RIGHT' }, // Miss Right
        { holeNumber: 5, par: 4, grossScore: 4, fairwayHit: null }, // Null: EXCLUDED
        { holeNumber: 6, par: 5, grossScore: 5, fairwayHit: 'STRAIGHT' }, // Hit
      ];

      // Total valid opportunities: 4 (holes 1, 3, 4, 6)
      // Hits: 2 (holes 1, 6) -> 2/4 = 50.0%
      const fir = StatisticsEngine.calculateFIR(scores);
      expect(fir.totalOpportunities).toBe(4);
      expect(fir.hitCount).toBe(2);
      expect(fir.missLeftCount).toBe(1);
      expect(fir.missRightCount).toBe(1);
      expect(fir.percentage).toBe(50.0);
    });

    it('returns null percentage when no qualifying holes exist', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 3, grossScore: 3, fairwayHit: 'STRAIGHT' },
      ];
      const fir = StatisticsEngine.calculateFIR(scores);
      expect(fir.totalOpportunities).toBe(0);
      expect(fir.percentage).toBeNull();
    });
  });

  describe('calculateGIR (Greens in Regulation)', () => {
    it('calculates GIR percentage correctly excluding null entries', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, gir: true },
        { holeNumber: 2, par: 3, grossScore: 3, gir: true },
        { holeNumber: 3, par: 4, grossScore: 5, gir: false },
        { holeNumber: 4, par: 5, grossScore: 5, gir: false },
        { holeNumber: 5, par: 4, grossScore: 4, gir: null }, // Excluded
      ];

      // 4 valid opportunities, 2 hits -> 50.0%
      const gir = StatisticsEngine.calculateGIR(scores);
      expect(gir.totalOpportunities).toBe(4);
      expect(gir.hitCount).toBe(2);
      expect(gir.missCount).toBe(2);
      expect(gir.percentage).toBe(50.0);
    });

    it('returns null percentage when 0 holes have GIR tracked', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, gir: null },
      ];
      const gir = StatisticsEngine.calculateGIR(scores);
      expect(gir.totalOpportunities).toBe(0);
      expect(gir.percentage).toBeNull();
    });
  });

  describe('calculatePutts', () => {
    it('calculates total, per hole, per GIR, and distribution accurately', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, putts: 1, gir: true },
        { holeNumber: 2, par: 3, grossScore: 3, putts: 2, gir: true },
        { holeNumber: 3, par: 4, grossScore: 5, putts: 3, gir: false },
        { holeNumber: 4, par: 5, grossScore: 6, putts: 2, gir: false },
      ];

      const putts = StatisticsEngine.calculatePutts(scores);
      expect(putts.totalPutts).toBe(8);
      expect(putts.totalHolesWithPutts).toBe(4);
      expect(putts.puttsPerHole).toBe(2.0);
      expect(putts.puttsPerGir).toBe(1.5); // Holes 1 & 2: (1 + 2) / 2 = 1.5
      expect(putts.onePuttsCount).toBe(1);
      expect(putts.twoPuttsCount).toBe(2);
      expect(putts.threeOrMorePuttsCount).toBe(1);
    });
  });

  describe('calculateScrambling (Up and Down)', () => {
    it('calculates scrambling percentage when GIR is missed and score is <= Par', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, gir: false }, // Scrambled (Par)
        { holeNumber: 2, par: 3, grossScore: 2, gir: false }, // Scrambled (Birdie)
        { holeNumber: 3, par: 4, grossScore: 5, gir: false }, // Missed (Bogey)
        { holeNumber: 4, par: 5, grossScore: 6, gir: false }, // Missed (Bogey)
        { holeNumber: 5, par: 4, grossScore: 4, gir: true }, // GIR HIT: NOT a scrambling opportunity
      ];

      // Missed greens: 4. Successes: 2 (holes 1, 2) -> 50.0%
      const scram = StatisticsEngine.calculateScrambling(scores);
      expect(scram.status).toBe('AVAILABLE');
      expect(scram.opportunitiesCount).toBe(4);
      expect(scram.successCount).toBe(2);
      expect(scram.percentage).toBe(50.0);
      expect(scram.message).toBeNull();
    });

    it('returns status NO_OPPORTUNITIES and null percentage when 0 greens missed (NEVER fake 0.0%)', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 4, grossScore: 4, gir: true },
        { holeNumber: 2, par: 3, grossScore: 3, gir: true },
      ];

      const scram = StatisticsEngine.calculateScrambling(scores);
      expect(scram.status).toBe('NO_OPPORTUNITIES');
      expect(scram.opportunitiesCount).toBe(0);
      expect(scram.percentage).toBeNull();
      expect(scram.message).toContain('No missed greens');
    });
  });

  describe('calculateParBreakdown & calculateScoreDistribution', () => {
    it('aggregates par breakdowns and score distributions correctly', () => {
      const scores: ScoreItem[] = [
        { holeNumber: 1, par: 3, grossScore: 2 }, // Birdie (-1)
        { holeNumber: 2, par: 4, grossScore: 4 }, // Par (0)
        { holeNumber: 3, par: 4, grossScore: 5 }, // Bogey (+1)
        { holeNumber: 4, par: 5, grossScore: 7 }, // Double Bogey (+2)
        { holeNumber: 5, par: 5, grossScore: 9 }, // Triple+ (+4)
      ];

      const dist = StatisticsEngine.calculateScoreDistribution(scores);
      expect(dist.birdies).toBe(1);
      expect(dist.pars).toBe(1);
      expect(dist.bogeys).toBe(1);
      expect(dist.doubleBogeys).toBe(1);
      expect(dist.tripleOrWorse).toBe(1);

      const pb = StatisticsEngine.calculateParBreakdown(scores);
      expect(pb.par3Average).toBe(2.0);
      expect(pb.par4Average).toBe(4.5); // (4+5)/2 = 4.5
      expect(pb.par5Average).toBe(8.0); // (7+9)/2 = 8.0
    });
  });
});

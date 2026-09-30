import { BadRequestException } from '@nestjs/common';
import { WhsEngine } from '../src/handicap/whs/whs.engine';
import { NullPccProvider, MockPccProvider } from '../src/handicap/pcc/pcc.provider';

describe('WhsEngine (WHS Handicap Rules)', () => {
  describe('calculateScoreDifferential', () => {
    it('calculates score differential with standard formula (113 / Slope) * (AGS - CR - PCC)', () => {
      // AGS: 85, CR: 72.0, Slope: 125, PCC: 0
      // 113 / 125 * (85 - 72.0) = 0.904 * 13 = 11.752 -> 11.8
      const diff = WhsEngine.calculateScoreDifferential(85, 72.0, 125, 0.0);
      expect(diff).toBe(11.8);
    });

    it('applies PCC condition adjustment properly when provided', () => {
      // AGS: 85, CR: 72.0, Slope: 125, PCC: 1.0
      // 113 / 125 * (85 - 72.0 - 1.0) = 0.904 * 12.0 = 10.848 -> 10.8
      const diffWithPcc = WhsEngine.calculateScoreDifferential(85, 72.0, 125, 1.0);
      expect(diffWithPcc).toBe(10.8);
    });

    it('throws BadRequestException on invalid slope rating (< 55 or > 155)', () => {
      expect(() => WhsEngine.calculateScoreDifferential(80, 70.0, 50)).toThrow(
        BadRequestException,
      );
      expect(() => WhsEngine.calculateScoreDifferential(80, 70.0, 160)).toThrow(
        BadRequestException,
      );
    });

    it('throws BadRequestException on non-positive course rating or AGS', () => {
      expect(() => WhsEngine.calculateScoreDifferential(80, 0, 113)).toThrow(
        BadRequestException,
      );
      expect(() => WhsEngine.calculateScoreDifferential(0, 72.0, 113)).toThrow(
        BadRequestException,
      );
    });
  });

  describe('calculateAdjustedGrossScore (Net Double Bogey)', () => {
    it('caps hole score at Par + 2 + strokes received for established player', () => {
      const holeScores = [
        { holeNumber: 1, par: 4, handicapIndex: 5, grossScore: 8 }, // 1 stroke received (HCP 18) -> max 4+2+1 = 7. Gross 8 -> 7
        { holeNumber: 2, par: 3, handicapIndex: 12, grossScore: 3 }, // gross 3 -> 3
        { holeNumber: 3, par: 5, handicapIndex: 1, grossScore: 7 }, // 1 stroke received -> max 5+2+1 = 8. Gross 7 -> 7
      ];

      const ags = WhsEngine.calculateAdjustedGrossScore(holeScores, 18);
      // hole 1: 7, hole 2: 3, hole 3: 7 -> total 17
      expect(ags).toBe(17);
    });

    it('caps hole score at Par + 5 when player has no established handicap', () => {
      const holeScores = [
        { holeNumber: 1, par: 4, grossScore: 12 }, // max 4+5 = 9. Gross 12 -> 9
        { holeNumber: 2, par: 3, grossScore: 5 }, // max 3+5 = 8. Gross 5 -> 5
      ];

      const ags = WhsEngine.calculateAdjustedGrossScore(holeScores, 0);
      expect(ags).toBe(14);
    });
  });

  describe('calculateHandicapIndex (Official WHS Sliding Scale)', () => {
    it('returns isEstablished: false when fewer than 3 rounds are available', () => {
      const res0 = WhsEngine.calculateHandicapIndex([]);
      expect(res0.isEstablished).toBe(false);
      expect(res0.handicapIndex).toBeNull();

      const res2 = WhsEngine.calculateHandicapIndex([15.2, 18.0]);
      expect(res2.isEstablished).toBe(false);
      expect(res2.handicapIndex).toBeNull();
    });

    it('3 rounds: uses lowest 1 minus 2.0 adjustment', () => {
      const diffs = [18.0, 14.0, 20.0]; // lowest is 14.0 -> 14.0 - 2.0 = 12.0
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(12.0);
      expect(res.differentialsUsed).toEqual([14.0]);
    });

    it('4 rounds: uses lowest 1 minus 1.0 adjustment', () => {
      const diffs = [18.0, 14.0, 20.0, 16.0]; // lowest is 14.0 -> 14.0 - 1.0 = 13.0
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(13.0);
      expect(res.differentialsUsed).toEqual([14.0]);
    });

    it('5 rounds: uses lowest 1 with no adjustment', () => {
      const diffs = [18.0, 14.0, 20.0, 16.0, 13.5]; // lowest is 13.5
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(13.5);
      expect(res.differentialsUsed).toEqual([13.5]);
    });

    it('6 rounds: uses average of lowest 2 minus 1.0 adjustment', () => {
      const diffs = [18.0, 14.0, 20.0, 16.0, 12.0, 15.0]; // lowest 2 are 12.0, 14.0 -> avg 13.0 - 1.0 = 12.0
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(12.0);
      expect(res.differentialsUsed).toEqual([12.0, 14.0]);
    });

    it('7-8 rounds: uses average of lowest 2 with no adjustment', () => {
      const diffs = [18.0, 14.0, 20.0, 16.0, 12.0, 15.0, 17.0]; // lowest 2: 12.0, 14.0 -> avg 13.0
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(13.0);
      expect(res.differentialsUsed).toEqual([12.0, 14.0]);
    });

    it('20 rounds: uses average of lowest 8 differentials', () => {
      const diffs = [
        10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, // lowest 8: sum = 108, avg = 13.5
        18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0,
      ];
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.isEstablished).toBe(true);
      expect(res.handicapIndex).toBe(13.5);
      expect(res.differentialsUsed.length).toBe(8);
    });

    it('caps handicap index at maximum WHS limit of 54.0', () => {
      const diffs = [60.0, 62.0, 65.0]; // lowest 1 is 60.0 - 2.0 = 58.0 -> capped to 54.0
      const res = WhsEngine.calculateHandicapIndex(diffs);
      expect(res.handicapIndex).toBe(54.0);
    });
  });

  describe('PCC Providers', () => {
    it('NullPccProvider returns UNAVAILABLE status and 0.0 adjustment without faking data', async () => {
      const provider = new NullPccProvider();
      const result = await provider.getPcc(new Date(), 'course-uuid');
      expect(result.status).toBe('UNAVAILABLE');
      expect(result.isAvailable).toBe(false);
      expect(result.value).toBe(0.0);
    });

    it('MockPccProvider returns configured PCC value for deterministic tests', async () => {
      const mock = new MockPccProvider(2.0, true);
      const res = await mock.getPcc(new Date(), 'course-uuid');
      expect(res.status).toBe('AVAILABLE');
      expect(res.value).toBe(2.0);
    });
  });
});

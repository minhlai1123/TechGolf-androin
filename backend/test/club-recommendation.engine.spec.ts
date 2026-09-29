import { ClubRecommendationEngine, ClubInfo } from '../src/shots/club-recommendation.engine';
import { DistanceUnit } from '../src/shots/entities/shot.entity';

describe('ClubRecommendationEngine Tests', () => {
  const sampleClubs: ClubInfo[] = [
    {
      id: 'driver-id',
      clubType: 'DRIVER',
      customName: 'Stealth Driver',
      averageDistanceMeters: 220, // ~240 yards
      totalShotsRecorded: 15,
      isActive: true,
    },
    {
      id: '5iron-id',
      clubType: 'IRON_5',
      customName: '5 Iron',
      averageDistanceMeters: 165, // ~180.4 yards
      totalShotsRecorded: 12,
      isActive: true,
    },
    {
      id: '7iron-id',
      clubType: 'IRON_7',
      customName: '7 Iron',
      averageDistanceMeters: 137.16, // exactly 150 yards
      totalShotsRecorded: 20,
      isActive: true,
    },
    {
      id: '9iron-id',
      clubType: 'IRON_9',
      customName: '9 Iron',
      averageDistanceMeters: 110, // ~120.3 yards
      totalShotsRecorded: 18,
      isActive: true,
    },
    {
      id: 'pw-id',
      clubType: 'PITCHING_WEDGE',
      customName: 'PW',
      averageDistanceMeters: 95, // ~103.9 yards
      totalShotsRecorded: 25,
      isActive: true,
    },
    {
      id: 'inactive-id',
      clubType: 'IRON_6',
      customName: '6 Iron (Old)',
      averageDistanceMeters: 150,
      totalShotsRecorded: 10,
      isActive: false, // inactive!
    },
  ];

  it('returns "Not enough shot data" when no clubs have recorded shots', () => {
    const emptyBag: ClubInfo[] = [
      {
        id: 'c1',
        clubType: 'IRON_7',
        averageDistanceMeters: 0,
        totalShotsRecorded: 0,
        isActive: true,
      },
    ];

    const result = ClubRecommendationEngine.recommend(150, DistanceUnit.YARDS, emptyBag);
    expect(result.hasRecommendation).toBe(false);
    expect(result.recommendedClub).toBeNull();
    expect(result.message).toContain('Not enough shot data');
  });

  it('returns closest club to remaining target distance in yards', () => {
    // 150 yards remaining: 7 Iron is exactly 150 yards
    const result = ClubRecommendationEngine.recommend(150, DistanceUnit.YARDS, sampleClubs);
    expect(result.hasRecommendation).toBe(true);
    expect(result.recommendedClub).not.toBeNull();
    expect(result.recommendedClub?.clubName).toBe('7 Iron');
    expect(result.recommendedClub?.averageDistance).toBeCloseTo(150.0, 1);
    expect(result.difference).toBeCloseTo(0.0, 1);
  });

  it('selects 5 Iron for 180 yards approach', () => {
    const result = ClubRecommendationEngine.recommend(180, DistanceUnit.YARDS, sampleClubs);
    expect(result.hasRecommendation).toBe(true);
    expect(result.recommendedClub?.clubName).toBe('5 Iron');
    expect(result.recommendedClub?.averageDistance).toBeCloseTo(180.4, 1);
  });

  it('filters out inactive clubs even if their distance is closest', () => {
    // 6 Iron has 150m average (~164 yards), but isActive is false
    const result = ClubRecommendationEngine.recommend(164, DistanceUnit.YARDS, sampleClubs);
    // Should NOT recommend 6 Iron (Old)
    expect(result.recommendedClub?.clubName).not.toBe('6 Iron (Old)');
  });

  it('handles metric meters unit recommendation accurately', () => {
    // 110 meters target -> 9 Iron (110m average)
    const result = ClubRecommendationEngine.recommend(110, DistanceUnit.METERS, sampleClubs);
    expect(result.hasRecommendation).toBe(true);
    expect(result.recommendedClub?.clubName).toBe('9 Iron');
    expect(result.recommendedClub?.averageDistance).toBe(110.0);
    expect(result.difference).toBe(0.0);
  });

  it('provides candidates sorted by distance difference', () => {
    const result = ClubRecommendationEngine.recommend(140, DistanceUnit.YARDS, sampleClubs);
    expect(result.candidates.length).toBeGreaterThan(1);
    // Best candidate is first in array
    expect(result.candidates[0].clubId).toBe(result.recommendedClub?.clubId);
  });
});

import { PlaysLikeEngine } from '../src/shots/plays-like.engine';
import { DistanceUnit } from '../src/shots/entities/shot.entity';

describe('PlaysLikeEngine Tests', () => {
  it('returns actual distance when elevation is flat (delta = 0)', () => {
    const result = PlaysLikeEngine.calculate(150, 10.0, 10.0, DistanceUnit.YARDS);
    expect(result.actualDistance).toBe(150);
    expect(result.playsLikeDistance).toBe(150);
    expect(result.adjustment).toBe(0);
    expect(result.elevationDeltaMeters).toBe(0);
    expect(result.hasElevation).toBe(true);
  });

  it('adjusts plays-like distance for uphill shots (plays longer)', () => {
    // Start elevation 10m, target 20m -> delta +10m
    // 10m * 1.0936132983 ~ 10.9 yards
    const result = PlaysLikeEngine.calculate(150, 10.0, 20.0, DistanceUnit.YARDS);
    expect(result.actualDistance).toBe(150);
    expect(result.elevationDeltaMeters).toBe(10.0);
    expect(result.elevationDeltaUnit).toBeCloseTo(10.9, 1);
    expect(result.adjustment).toBeGreaterThan(10.0);
    expect(result.playsLikeDistance).toBeGreaterThan(150);
    expect(result.playsLikeDistance).toBeCloseTo(160.9, 1);
    expect(result.explanation).toContain('Uphill');
  });

  it('adjusts plays-like distance for downhill shots (plays shorter)', () => {
    // Start elevation 30m, target 15m -> delta -15m
    const result = PlaysLikeEngine.calculate(150, 30.0, 15.0, DistanceUnit.YARDS);
    expect(result.actualDistance).toBe(150);
    expect(result.elevationDeltaMeters).toBe(-15.0);
    expect(result.adjustment).toBeLessThan(0);
    expect(result.playsLikeDistance).toBeLessThan(150);
    expect(result.explanation).toContain('Downhill');
  });

  it('handles METERS unit calculation accurately', () => {
    // 140 meters actual, start 5m, target 15m -> delta +10m -> plays like 150m
    const result = PlaysLikeEngine.calculate(140, 5.0, 15.0, DistanceUnit.METERS);
    expect(result.actualDistance).toBe(140);
    expect(result.elevationDeltaMeters).toBe(10.0);
    expect(result.elevationDeltaUnit).toBe(10.0);
    expect(result.adjustment).toBe(10.0);
    expect(result.playsLikeDistance).toBe(150.0);
    expect(result.unit).toBe(DistanceUnit.METERS);
  });

  it('returns actual distance with hasElevation=false when elevation data is missing', () => {
    const res1 = PlaysLikeEngine.calculate(165, null, 25.0, DistanceUnit.YARDS);
    expect(res1.hasElevation).toBe(false);
    expect(res1.playsLikeDistance).toBe(165);
    expect(res1.elevationDeltaMeters).toBeNull();
    expect(res1.adjustment).toBe(0);

    const res2 = PlaysLikeEngine.calculate(165, 12.0, null, DistanceUnit.YARDS);
    expect(res2.hasElevation).toBe(false);
    expect(res2.playsLikeDistance).toBe(165);
  });

  it('calculates geodesic Haversine distance between known coordinates accurately', () => {
    // Known points roughly 100-200 meters apart
    const lat1 = 21.028511;
    const lng1 = 105.854444;
    const lat2 = 21.029800;
    const lng2 = 105.855200;

    const meters = PlaysLikeEngine.distanceBetweenMeters(lat1, lng1, lat2, lng2);
    expect(meters).toBeGreaterThan(100);
    expect(meters).toBeLessThan(250);

    const yards = PlaysLikeEngine.distanceBetweenYards(lat1, lng1, lat2, lng2);
    expect(yards).toBeCloseTo(meters * PlaysLikeEngine.METERS_TO_YARDS, 1);
  });
});

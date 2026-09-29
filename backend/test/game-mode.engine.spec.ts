import { GameModeEngine } from '../src/rounds/game-mode.engine';
import { GameMode } from '../src/rounds/entities/round.entity';
import { RoundPlayer } from '../src/rounds/entities/round-player.entity';
import { RoundScore } from '../src/rounds/entities/round-score.entity';
import { Hole } from '../src/courses/entities/hole.entity';

describe('GameModeEngine Unit Tests', () => {
  describe('Stableford points calculation', () => {
    const par4 = 4;

    test('Double Eagle / Albatross (3 under par) yields 5 points', () => {
      expect(GameModeEngine.calculateStablefordPoints(1, par4)).toBe(5);
    });

    test('Eagle (2 under par) yields 4 points', () => {
      expect(GameModeEngine.calculateStablefordPoints(2, par4)).toBe(4);
    });

    test('Birdie (1 under par) yields 3 points', () => {
      expect(GameModeEngine.calculateStablefordPoints(3, par4)).toBe(3);
    });

    test('Par (level par) yields 2 points', () => {
      expect(GameModeEngine.calculateStablefordPoints(4, par4)).toBe(2);
    });

    test('Bogey (1 over par) yields 1 point', () => {
      expect(GameModeEngine.calculateStablefordPoints(5, par4)).toBe(1);
    });

    test('Double Bogey or worse (>= 2 over par) yields 0 points', () => {
      expect(GameModeEngine.calculateStablefordPoints(6, par4)).toBe(0);
      expect(GameModeEngine.calculateStablefordPoints(7, par4)).toBe(0);
      expect(GameModeEngine.calculateStablefordPoints(10, par4)).toBe(0);
    });
  });

  describe('Full round game mode calculations', () => {
    const hole1: Partial<Hole> = { id: 'h1', hole_number: 1, par: 4, course_id: 'c1' };
    const hole2: Partial<Hole> = { id: 'h2', hole_number: 2, par: 3, course_id: 'c1' };
    const hole3: Partial<Hole> = { id: 'h3', hole_number: 3, par: 5, course_id: 'c1' };
    const holes = [hole1, hole2, hole3] as Hole[];

    const player1: Partial<RoundPlayer> = { id: 'p1', playerName: 'Player 1', playerOrder: 1, teamId: 'Team A' };
    const player2: Partial<RoundPlayer> = { id: 'p2', playerName: 'Player 2', playerOrder: 2, teamId: 'Team B' };
    const players = [player1, player2] as RoundPlayer[];

    const scores: Partial<RoundScore>[] = [
      // Player 1: H1 par (4), H2 birdie (2), H3 bogey (6) -> Gross 12
      { id: 's1', playerId: 'p1', holeId: 'h1', grossScore: 4, putts: 2, penalties: 0, fairwayHit: 'STRAIGHT' as any, gir: true },
      { id: 's2', playerId: 'p1', holeId: 'h2', grossScore: 2, putts: 1, penalties: 0, fairwayHit: null, gir: true },
      { id: 's3', playerId: 'p1', holeId: 'h3', grossScore: 6, putts: 2, penalties: 0, fairwayHit: 'LEFT' as any, gir: false },

      // Player 2: H1 bogey (5), H2 par (3), H3 eagle (3) -> Gross 11
      { id: 's4', playerId: 'p2', holeId: 'h1', grossScore: 5, putts: 2, penalties: 0, fairwayHit: 'STRAIGHT' as any, gir: false },
      { id: 's5', playerId: 'p2', holeId: 'h2', grossScore: 3, putts: 2, penalties: 0, fairwayHit: null, gir: true },
      { id: 's6', playerId: 'p2', holeId: 'h3', grossScore: 3, putts: 1, penalties: 0, fairwayHit: 'STRAIGHT' as any, gir: true },
    ];

    test('Stroke Play ranks players by lowest total gross', () => {
      const result = GameModeEngine.calculateResult(
        GameMode.STROKE_PLAY,
        players,
        holes,
        scores as RoundScore[],
        true,
      );

      expect(result.strokePlay).toBeDefined();
      expect(result.strokePlay?.length).toBe(2);

      // Player 2 has 11 gross, Player 1 has 12 gross -> Player 2 is rank 1
      expect(result.strokePlay?.[0].playerId).toBe('p2');
      expect(result.strokePlay?.[0].totalGross).toBe(11);
      expect(result.strokePlay?.[0].rank).toBe(1);

      expect(result.strokePlay?.[1].playerId).toBe('p1');
      expect(result.strokePlay?.[1].totalGross).toBe(12);
      expect(result.strokePlay?.[1].rank).toBe(2);
    });

    test('Stableford ranks players by highest total points', () => {
      // Points:
      // Player 1: H1(par 4 -> 4 = 2), H2(par 3 -> 2 = 3), H3(par 5 -> 6 = 1) -> Total 6 pts
      // Player 2: H1(par 4 -> 5 = 1), H2(par 3 -> 3 = 2), H3(par 5 -> 3 = 4) -> Total 7 pts
      const result = GameModeEngine.calculateResult(
        GameMode.STABLEFORD,
        players,
        holes,
        scores as RoundScore[],
        true,
      );

      expect(result.stableford).toBeDefined();
      expect(result.stableford?.[0].playerId).toBe('p2');
      expect(result.stableford?.[0].totalPoints).toBe(7);
      expect(result.stableford?.[0].rank).toBe(1);

      expect(result.stableford?.[1].playerId).toBe('p1');
      expect(result.stableford?.[1].totalPoints).toBe(6);
      expect(result.stableford?.[1].rank).toBe(2);
    });

    test('Match Play determines hole-by-hole winner and match status', () => {
      // H1: P1(4) vs P2(5) -> P1 wins (+1 lead)
      // H2: P1(2) vs P2(3) -> P1 wins (+2 lead)
      // H3: P1(6) vs P2(3) -> P2 wins (+1 lead for P1)
      const result = GameModeEngine.calculateResult(
        GameMode.MATCH_PLAY,
        players,
        holes,
        scores as RoundScore[],
        true,
      );

      expect(result.matchPlay).toBeDefined();
      expect(result.matchPlay?.holesCompleted).toBe(3);
      expect(result.matchPlay?.holesRemaining).toBe(0);
      expect(result.matchPlay?.winnerId).toBe('p1');
      expect(result.matchPlay?.matchStatus).toBe('Player 1 wins 1 UP');
    });

    test('Scramble computes minimum team score per hole', () => {
      // Put both players in the same team
      const teamPlayers = [
        { ...player1, teamId: 'Scramble Team' },
        { ...player2, teamId: 'Scramble Team' },
      ] as RoundPlayer[];

      // Team scores:
      // H1: min(4, 5) = 4
      // H2: min(2, 3) = 2
      // H3: min(6, 3) = 3
      // Team Total Gross = 9
      const result = GameModeEngine.calculateResult(
        GameMode.SCRAMBLE,
        teamPlayers,
        holes,
        scores as RoundScore[],
        true,
      );

      expect(result.scramble).toBeDefined();
      expect(result.scramble?.length).toBe(1);
      expect(result.scramble?.[0].totalGross).toBe(9);
      expect(result.scramble?.[0].scoresByHole['h1']).toBe(4);
      expect(result.scramble?.[0].scoresByHole['h2']).toBe(2);
      expect(result.scramble?.[0].scoresByHole['h3']).toBe(3);
    });

    test('Four-Ball computes individual summaries and best-ball team score', () => {
      const result = GameModeEngine.calculateResult(
        GameMode.FOUR_BALL,
        players,
        holes,
        scores as RoundScore[],
        true,
      );

      expect(result.fourBall).toBeDefined();
      expect(result.fourBall?.individualSummaries.length).toBe(2);
      expect(result.fourBall?.teams.length).toBe(2);
    });
  });
});

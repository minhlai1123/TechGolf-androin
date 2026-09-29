import { GameMode } from './entities/round.entity';
import { RoundPlayer } from './entities/round-player.entity';
import { RoundScore } from './entities/round-score.entity';
import { Hole } from '../courses/entities/hole.entity';

export interface PlayerScoreSummary {
  playerId: string;
  playerName: string;
  playerOrder: number;
  teamId?: string | null;
  totalGross: number;
  totalPutts: number;
  totalPenalties: number;
  holesPlayed: number;
  firCount: number;
  firPossible: number;
  girCount: number;
  girPossible: number;
  rank?: number;
}

export interface StablefordPlayerResult extends PlayerScoreSummary {
  totalPoints: number;
  pointsByHole: { [holeId: string]: number };
}

export interface MatchPlayResult {
  player1: { id: string; name: string };
  player2: { id: string; name: string };
  holesCompleted: number;
  holesRemaining: number;
  matchStatus: string; // e.g. "ALL SQUARE", "Player 1 2 UP", "Player 1 wins 3 & 2"
  winnerId: string | null;
  holeOutcomes: {
    [holeId: string]: {
      holeNumber: number;
      player1Gross: number;
      player2Gross: number;
      winnerId: string | null; // null if halved
    };
  };
}

export interface TeamScoreSummary {
  teamId: string;
  playerNames: string[];
  totalGross: number;
  holesPlayed: number;
  scoresByHole: { [holeId: string]: number };
  rank?: number;
}

export interface GameModeResult {
  gameMode: GameMode;
  isCompleted: boolean;
  strokePlay?: PlayerScoreSummary[];
  stableford?: StablefordPlayerResult[];
  matchPlay?: MatchPlayResult;
  scramble?: TeamScoreSummary[];
  fourBall?: {
    teams: TeamScoreSummary[];
    individualSummaries: PlayerScoreSummary[];
  };
}

export class GameModeEngine {
  /**
   * Calculates points for a single hole under standard Stableford rules based on Gross Score and Hole Par.
   *
   * Assumptions / Standard Rules:
   * - Albatross (3 under par or better): 5 points
   * - Eagle (2 under par): 4 points
   * - Birdie (1 under par): 3 points
   * - Par (Level par): 2 points
   * - Bogey (1 over par): 1 point
   * - Double Bogey or worse (>= 2 over par): 0 points
   */
  static calculateStablefordPoints(grossScore: number, par: number): number {
    const scoreDiff = grossScore - par;
    if (scoreDiff <= -3) return 5;
    if (scoreDiff === -2) return 4;
    if (scoreDiff === -1) return 3;
    if (scoreDiff === 0) return 2;
    if (scoreDiff === 1) return 1;
    return 0;
  }

  /**
   * Calculates game mode results given players, holes, and scores.
   */
  static calculateResult(
    gameMode: GameMode,
    players: RoundPlayer[],
    holes: Hole[],
    scores: RoundScore[],
    isCompleted: boolean,
  ): GameModeResult {
    const holeMap = new Map<string, Hole>();
    for (const h of holes) {
      holeMap.set(h.id, h);
    }

    switch (gameMode) {
      case GameMode.STROKE_PLAY:
        return {
          gameMode,
          isCompleted,
          strokePlay: this._calculateStrokePlay(players, holeMap, scores),
        };

      case GameMode.STABLEFORD:
        return {
          gameMode,
          isCompleted,
          stableford: this._calculateStableford(players, holeMap, scores),
        };

      case GameMode.MATCH_PLAY:
        return {
          gameMode,
          isCompleted,
          matchPlay: this._calculateMatchPlay(players, holes, scores),
        };

      case GameMode.SCRAMBLE:
        return {
          gameMode,
          isCompleted,
          scramble: this._calculateScramble(players, holes, scores),
        };

      case GameMode.FOUR_BALL:
        return {
          gameMode,
          isCompleted,
          fourBall: this._calculateFourBall(players, holes, scores, holeMap),
        };

      default:
        return {
          gameMode,
          isCompleted,
          strokePlay: this._calculateStrokePlay(players, holeMap, scores),
        };
    }
  }

  private static _calculateStrokePlay(
    players: RoundPlayer[],
    holeMap: Map<string, Hole>,
    scores: RoundScore[],
  ): PlayerScoreSummary[] {
    const summaries: PlayerScoreSummary[] = players.map((p) => {
      const pScores = scores.filter((s) => s.playerId === p.id);
      let totalGross = 0;
      let totalPutts = 0;
      let totalPenalties = 0;
      let firCount = 0;
      let firPossible = 0;
      let girCount = 0;
      let girPossible = 0;

      for (const s of pScores) {
        totalGross += s.grossScore;
        totalPutts += s.putts;
        totalPenalties += s.penalties;

        const hole = holeMap.get(s.holeId);
        if (hole && hole.par > 3) {
          firPossible++;
          if (s.fairwayHit === 'STRAIGHT') {
            firCount++;
          }
        }

        if (s.gir !== null && s.gir !== undefined) {
          girPossible++;
          if (s.gir) {
            girCount++;
          }
        }
      }

      return {
        playerId: p.id,
        playerName: p.playerName,
        playerOrder: p.playerOrder,
        teamId: p.teamId,
        totalGross,
        totalPutts,
        totalPenalties,
        holesPlayed: pScores.length,
        firCount,
        firPossible,
        girCount,
        girPossible,
      };
    });

    // Rank ascending by total gross
    summaries.sort((a, b) => a.totalGross - b.totalGross);
    summaries.forEach((s, idx) => {
      s.rank = idx + 1;
    });

    return summaries;
  }

  private static _calculateStableford(
    players: RoundPlayer[],
    holeMap: Map<string, Hole>,
    scores: RoundScore[],
  ): StablefordPlayerResult[] {
    const strokeSummaries = this._calculateStrokePlay(players, holeMap, scores);

    const results: StablefordPlayerResult[] = strokeSummaries.map((summary) => {
      const pScores = scores.filter((s) => s.playerId === summary.playerId);
      let totalPoints = 0;
      const pointsByHole: { [holeId: string]: number } = {};

      for (const s of pScores) {
        const hole = holeMap.get(s.holeId);
        const par = hole?.par ?? 4;
        const pts = this.calculateStablefordPoints(s.grossScore, par);
        totalPoints += pts;
        pointsByHole[s.holeId] = pts;
      }

      return {
        ...summary,
        totalPoints,
        pointsByHole,
      };
    });

    // Rank descending by Stableford points
    results.sort((a, b) => b.totalPoints - a.totalPoints);
    results.forEach((r, idx) => {
      r.rank = idx + 1;
    });

    return results;
  }

  private static _calculateMatchPlay(
    players: RoundPlayer[],
    holes: Hole[],
    scores: RoundScore[],
  ): MatchPlayResult {
    const p1 = players[0] ?? { id: 'p1', playerName: 'Player 1' };
    const p2 = players[1] ?? { id: 'p2', playerName: 'Player 2' };

    const sortedHoles = [...holes].sort((a, b) => a.hole_number - b.hole_number);
    let netLead = 0; // Positive = p1 lead, Negative = p2 lead
    let holesCompleted = 0;
    const holeOutcomes: MatchPlayResult['holeOutcomes'] = {};

    for (const h of sortedHoles) {
      const s1 = scores.find((s) => s.playerId === p1.id && s.holeId === h.id);
      const s2 = scores.find((s) => s.playerId === p2.id && s.holeId === h.id);

      if (s1 && s2) {
        holesCompleted++;
        let winnerId: string | null = null;
        if (s1.grossScore < s2.grossScore) {
          winnerId = p1.id;
          netLead += 1;
        } else if (s2.grossScore < s1.grossScore) {
          winnerId = p2.id;
          netLead -= 1;
        }

        holeOutcomes[h.id] = {
          holeNumber: h.hole_number,
          player1Gross: s1.grossScore,
          player2Gross: s2.grossScore,
          winnerId,
        };
      }
    }

    const holesRemaining = Math.max(0, holes.length - holesCompleted);
    let matchStatus: string;
    let winnerId: string | null = null;

    const absLead = Math.abs(netLead);
    const leadingPlayer = netLead > 0 ? p1 : p2;

    if (absLead > 0) {
      if (holesRemaining === 0) {
        matchStatus = `${leadingPlayer.playerName} wins ${absLead} UP`;
        winnerId = leadingPlayer.id;
      } else if (absLead > holesRemaining) {
        matchStatus = `${leadingPlayer.playerName} wins ${absLead} & ${holesRemaining}`;
        winnerId = leadingPlayer.id;
      } else if (absLead === holesRemaining) {
        matchStatus = `${leadingPlayer.playerName} ${absLead} UP (DORMIE)`;
      } else {
        matchStatus = `${leadingPlayer.playerName} ${absLead} UP`;
      }
    } else {
      if (holesRemaining === 0 && holesCompleted > 0) {
        matchStatus = 'MATCH HALVED';
      } else {
        matchStatus = 'ALL SQUARE';
      }
    }

    return {
      player1: { id: p1.id, name: p1.playerName },
      player2: { id: p2.id, name: p2.playerName },
      holesCompleted,
      holesRemaining,
      matchStatus,
      winnerId,
      holeOutcomes,
    };
  }

  private static _calculateScramble(
    players: RoundPlayer[],
    holes: Hole[],
    scores: RoundScore[],
  ): TeamScoreSummary[] {
    // Group players by teamId (default to player.id if no team assigned)
    const teamsMap = new Map<string, RoundPlayer[]>();
    for (const p of players) {
      const tId = p.teamId || `Team ${p.playerOrder}`;
      if (!teamsMap.has(tId)) {
        teamsMap.set(tId, []);
      }
      teamsMap.get(tId)!.push(p);
    }

    const teamSummaries: TeamScoreSummary[] = [];

    teamsMap.forEach((teamPlayers, teamId) => {
      const playerIds = new Set(teamPlayers.map((tp) => tp.id));
      const teamScores = scores.filter((s) => playerIds.has(s.playerId));

      let totalGross = 0;
      let holesPlayed = 0;
      const scoresByHole: { [holeId: string]: number } = {};

      for (const h of holes) {
        const holeScores = teamScores.filter((s) => s.holeId === h.id);
        if (holeScores.length > 0) {
          // In scramble, the hole score for the team is the best score recorded by the team
          const minScore = Math.min(...holeScores.map((s) => s.grossScore));
          scoresByHole[h.id] = minScore;
          totalGross += minScore;
          holesPlayed++;
        }
      }

      teamSummaries.push({
        teamId,
        playerNames: teamPlayers.map((tp) => tp.playerName),
        totalGross,
        holesPlayed,
        scoresByHole,
      });
    });

    teamSummaries.sort((a, b) => a.totalGross - b.totalGross);
    teamSummaries.forEach((t, idx) => {
      t.rank = idx + 1;
    });

    return teamSummaries;
  }

  private static _calculateFourBall(
    players: RoundPlayer[],
    holes: Hole[],
    scores: RoundScore[],
    holeMap: Map<string, Hole>,
  ): GameModeResult['fourBall'] {
    const individualSummaries = this._calculateStrokePlay(players, holeMap, scores);
    const teams = this._calculateScramble(players, holes, scores);

    return {
      teams,
      individualSummaries,
    };
  }
}

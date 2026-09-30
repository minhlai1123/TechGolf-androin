export enum LivePlayEvent {
  JOIN = 'liveplay:join',
  JOINED = 'liveplay:joined',
  LEAVE = 'liveplay:leave',
  LEFT = 'liveplay:left',
  SCORE_UPDATE = 'score:update',
  SCORE_UPDATED = 'score:updated',
  LEADERBOARD_UPDATED = 'leaderboard:updated',
  ROUND_UPDATED = 'round:updated',
  PLAYER_JOINED = 'player:joined',
  PLAYER_LEFT = 'player:left',
  ERROR = 'liveplay:error',
}

export interface LivePlaySocketUser {
  userId: string;
  email: string;
  fullName?: string;
}

export interface LivePlayJoinPayload {
  roundId: string;
}

export interface LivePlayLeavePayload {
  roundId: string;
}

export interface LivePlayScoreUpdatePayload {
  roundId: string;
  holeId: string;
  playerId?: string;
  grossScore: number;
  putts?: number;
  penalties?: number;
  fairwayHit?: string | null;
  gir?: boolean | null;
}

export interface LivePlayLeaderboardEntry {
  playerId: string;
  playerName: string;
  playerOrder: number;
  rank?: number;
  grossScore: number;
  toPar: number;
  holesCompleted: number;
  thru: string; // e.g. "9", "18", "F"
  putts: number;
  penalties: number;
  points?: number; // For Stableford
  matchStatus?: string; // For Match Play
}

/// Supported Game Modes in TechGolf (Phase 4 per PDF)
enum GameMode {
  strokePlay,
  stableford,
  matchPlay,
  scramble,
  fourBall,
}

extension GameModeExtension on GameMode {
  String get value {
    switch (this) {
      case GameMode.strokePlay:
        return 'STROKE_PLAY';
      case GameMode.stableford:
        return 'STABLEFORD';
      case GameMode.matchPlay:
        return 'MATCH_PLAY';
      case GameMode.scramble:
        return 'SCRAMBLE';
      case GameMode.fourBall:
        return 'FOUR_BALL';
    }
  }

  String get displayName {
    switch (this) {
      case GameMode.strokePlay:
        return 'Stroke Play';
      case GameMode.stableford:
        return 'Stableford';
      case GameMode.matchPlay:
        return 'Match Play';
      case GameMode.scramble:
        return 'Scramble';
      case GameMode.fourBall:
        return 'Four-Ball';
    }
  }

  String get description {
    switch (this) {
      case GameMode.strokePlay:
        return 'Count every stroke. Player with lowest total gross score wins.';
      case GameMode.stableford:
        return 'Points based on score relative to par. Most points wins.';
      case GameMode.matchPlay:
        return 'Hole-by-hole competition between 2 players or sides.';
      case GameMode.scramble:
        return 'Team selects best shot each time and plays from that spot.';
      case GameMode.fourBall:
        return 'Two-player teams. Best individual ball counts as team score.';
    }
  }

  static GameMode fromString(String val) {
    switch (val.toUpperCase()) {
      case 'STROKE_PLAY':
        return GameMode.strokePlay;
      case 'STABLEFORD':
        return GameMode.stableford;
      case 'MATCH_PLAY':
        return GameMode.matchPlay;
      case 'SCRAMBLE':
        return GameMode.scramble;
      case 'FOUR_BALL':
        return GameMode.fourBall;
      default:
        return GameMode.strokePlay;
    }
  }
}

/// Fairway Hit direction
enum FairwayHit {
  left,
  straight,
  right,
}

extension FairwayHitExtension on FairwayHit {
  String get value {
    switch (this) {
      case FairwayHit.left:
        return 'LEFT';
      case FairwayHit.straight:
        return 'STRAIGHT';
      case FairwayHit.right:
        return 'RIGHT';
    }
  }

  static FairwayHit? fromString(String? val) {
    if (val == null) return null;
    switch (val.toUpperCase()) {
      case 'LEFT':
        return FairwayHit.left;
      case 'STRAIGHT':
        return FairwayHit.straight;
      case 'RIGHT':
        return FairwayHit.right;
      default:
        return null;
    }
  }
}

/// Domain engine for calculating game mode scores on Mobile
class MobileGameModeEngine {
  /// Stableford points per hole:
  /// - Albatross (<= par - 3): 5 pts
  /// - Eagle (par - 2): 4 pts
  /// - Birdie (par - 1): 3 pts
  /// - Par (par): 2 pts
  /// - Bogey (par + 1): 1 pt
  /// - Double Bogey or worse (>= par + 2): 0 pts
  static int calculateStablefordPoints(int grossScore, int par) {
    final diff = grossScore - par;
    if (diff <= -3) return 5;
    if (diff == -2) return 4;
    if (diff == -1) return 3;
    if (diff == 0) return 2;
    if (diff == 1) return 1;
    return 0;
  }

  /// Calculates FIR status: Par 3 holes are N/A; Par 4 & 5 have FIR.
  static bool isFirApplicable(int par) => par > 3;

  /// Default GIR heuristic: (gross - putts) <= (par - 2)
  static bool calculateDefaultGir({required int grossScore, required int putts, required int par}) {
    final strokesToGreen = grossScore - putts;
    return strokesToGreen <= (par - 2);
  }
}

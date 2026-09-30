import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/liveplay/models/liveplay_models.dart';

void main() {
  group('LivePlay Models Tests', () {
    test('LivePlayHole parses JSON with valid and default fields', () {
      final json = {
        'id': 'hole-1',
        'holeNumber': 1,
        'par': 4,
        'handicapIndex': 7,
      };

      final hole = LivePlayHole.fromJson(json);
      expect(hole.id, 'hole-1');
      expect(hole.holeNumber, 1);
      expect(hole.par, 4);
      expect(hole.handicapIndex, 7);

      // Default fallback
      final emptyHole = LivePlayHole.fromJson({});
      expect(emptyHole.id, '');
      expect(emptyHole.holeNumber, 1);
      expect(emptyHole.par, 4);
      expect(emptyHole.handicapIndex, isNull);
    });

    test('LivePlayScore parses JSON correctly with full statistics', () {
      final json = {
        'id': 'score-101',
        'playerId': 'player-1',
        'holeId': 'hole-1',
        'grossScore': 4,
        'putts': 2,
        'penalties': 0,
        'fairwayHit': 'LEFT',
        'gir': true,
      };

      final score = LivePlayScore.fromJson(json);
      expect(score.id, 'score-101');
      expect(score.playerId, 'player-1');
      expect(score.holeId, 'hole-1');
      expect(score.grossScore, 4);
      expect(score.putts, 2);
      expect(score.penalties, 0);
      expect(score.fairwayHit, 'LEFT');
      expect(score.gir, isTrue);
    });

    test('LivePlayPlayerSummary formats toPar accurately', () {
      // 0 holes completed
      final p0 = LivePlayPlayerSummary.fromJson({
        'playerId': 'p1',
        'playerName': 'Tiger Woods',
        'playerOrder': 1,
        'grossScore': 0,
        'toPar': 0,
        'thru': '-',
        'holesCompleted': 0,
      });
      expect(p0.formattedToPar, 'E');

      // Even par after 5 holes
      final pEven = LivePlayPlayerSummary.fromJson({
        'playerId': 'p1',
        'playerName': 'Tiger Woods',
        'playerOrder': 1,
        'grossScore': 20,
        'toPar': 0,
        'thru': '5',
        'holesCompleted': 5,
      });
      expect(pEven.formattedToPar, 'E');

      // Over par (+3)
      final pOver = LivePlayPlayerSummary.fromJson({
        'playerId': 'p2',
        'playerName': 'Rory McIlroy',
        'playerOrder': 2,
        'grossScore': 23,
        'toPar': 3,
        'thru': '5',
        'holesCompleted': 5,
      });
      expect(pOver.formattedToPar, '+3');

      // Under par (-2)
      final pUnder = LivePlayPlayerSummary.fromJson({
        'playerId': 'p3',
        'playerName': 'Scottie Scheffler',
        'playerOrder': 3,
        'grossScore': 18,
        'toPar': -2,
        'thru': '5',
        'holesCompleted': 5,
      });
      expect(pUnder.formattedToPar, '-2');
    });

    test('LivePlayStateModel parses full round payload', () {
      final json = {
        'round': {
          'id': 'round-xyz',
          'gameMode': 'STROKE_PLAY',
          'status': 'IN_PROGRESS',
          'currentHole': 6,
        },
        'course': {
          'name': 'Pebble Beach Golf Links',
        },
        'players': [
          {
            'id': 'rp-1',
            'userId': 'u-1',
            'roundId': 'round-xyz',
            'playerName': 'Tiger Woods',
            'playerOrder': 1,
            'handicap': 0.0,
            'playingHandicap': 0,
          },
        ],
        'holes': [
          {'id': 'h-1', 'holeNumber': 1, 'par': 4, 'handicapIndex': 7},
          {'id': 'h-2', 'holeNumber': 2, 'par': 5, 'handicapIndex': 1},
        ],
        'scores': [
          {
            'id': 's-1',
            'playerId': 'rp-1',
            'holeId': 'h-1',
            'grossScore': 4,
            'putts': 2,
            'penalties': 0,
            'gir': true,
          }
        ],
        'playerSummaries': [
          {
            'playerId': 'rp-1',
            'playerName': 'Tiger Woods',
            'playerOrder': 1,
            'grossScore': 4,
            'toPar': 0,
            'thru': '1',
            'holesCompleted': 1,
          }
        ],
        'leaderboard': {
          'standings': [
            {'playerId': 'rp-1', 'rank': 1, 'toPar': 0, 'grossScore': 4}
          ]
        }
      };

      final state = LivePlayStateModel.fromJson(json);
      expect(state.roundId, 'round-xyz');
      expect(state.courseName, 'Pebble Beach Golf Links');
      expect(state.gameMode, GameMode.strokePlay);
      expect(state.roundStatus, 'IN_PROGRESS');
      expect(state.currentHole, 6);
      expect(state.players.length, 1);
      expect(state.players.first.playerName, 'Tiger Woods');
      expect(state.holes.length, 2);
      expect(state.scores.length, 1);
      expect(state.playerSummaries.length, 1);
      expect(state.leaderboard['standings'], isNotEmpty);
    });
  });
}

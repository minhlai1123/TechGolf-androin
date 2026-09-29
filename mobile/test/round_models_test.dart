import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/rounds/models/round_models.dart';

void main() {
  group('Round & Score Models Tests', () {
    test('GameMode enums map correctly to string and display names', () {
      expect(GameMode.strokePlay.value, equals('STROKE_PLAY'));
      expect(GameMode.stableford.value, equals('STABLEFORD'));
      expect(GameMode.matchPlay.value, equals('MATCH_PLAY'));
      expect(GameMode.scramble.value, equals('SCRAMBLE'));
      expect(GameMode.fourBall.value, equals('FOUR_BALL'));

      expect(GameModeExtension.fromString('STROKE_PLAY'), equals(GameMode.strokePlay));
      expect(GameModeExtension.fromString('STABLEFORD'), equals(GameMode.stableford));
      expect(GameModeExtension.fromString('MATCH_PLAY'), equals(GameMode.matchPlay));
      expect(GameModeExtension.fromString('SCRAMBLE'), equals(GameMode.scramble));
      expect(GameModeExtension.fromString('FOUR_BALL'), equals(GameMode.fourBall));
    });

    test('FairwayHit enums map correctly', () {
      expect(FairwayHit.left.value, equals('LEFT'));
      expect(FairwayHit.straight.value, equals('STRAIGHT'));
      expect(FairwayHit.right.value, equals('RIGHT'));

      expect(FairwayHitExtension.fromString('LEFT'), equals(FairwayHit.left));
      expect(FairwayHitExtension.fromString('STRAIGHT'), equals(FairwayHit.straight));
      expect(FairwayHitExtension.fromString('RIGHT'), equals(FairwayHit.right));
      expect(FairwayHitExtension.fromString(null), isNull);
    });

    test('RoundPlayerModel parses and serializes correctly', () {
      final json = {
        'id': 'player-1',
        'roundId': 'round-1',
        'userId': 'user-1',
        'playerName': 'Minh Lai',
        'playerOrder': 1,
        'teamId': 'Team A',
      };

      final player = RoundPlayerModel.fromJson(json);
      expect(player.id, equals('player-1'));
      expect(player.playerName, equals('Minh Lai'));
      expect(player.playerOrder, equals(1));
      expect(player.teamId, equals('Team A'));

      final outJson = player.toJson();
      expect(outJson['playerName'], equals('Minh Lai'));
      expect(outJson['playerOrder'], equals(1));
    });

    test('RoundScoreModel parses and validates score parameters', () {
      final json = {
        'id': 'score-1',
        'roundId': 'round-1',
        'playerId': 'player-1',
        'holeId': 'hole-1',
        'grossScore': 4,
        'putts': 2,
        'penalties': 0,
        'fairwayHit': 'STRAIGHT',
        'gir': true,
      };

      final score = RoundScoreModel.fromJson(json);
      expect(score.grossScore, equals(4));
      expect(score.putts, equals(2));
      expect(score.penalties, equals(0));
      expect(score.fairwayHit, equals(FairwayHit.straight));
      expect(score.gir, isTrue);

      final outJson = score.toJson();
      expect(outJson['grossScore'], equals(4));
      expect(outJson['fairwayHit'], equals('STRAIGHT'));
      expect(outJson['gir'], isTrue);
    });

    test('ScorecardMatrix deserializes from API payload with totals', () {
      final matrixJson = {
        'round': {
          'id': 'round-1',
          'courseId': 'course-1',
          'gameMode': 'STROKE_PLAY',
          'status': 'IN_PROGRESS',
          'currentHole': 2,
        },
        'holes': [
          {'id': 'h1', 'holeNumber': 1, 'par': 4, 'handicapIndex': 7},
          {'id': 'h2', 'holeNumber': 2, 'par': 3, 'handicapIndex': 15},
        ],
        'players': [
          {'id': 'p1', 'playerName': 'Golfer 1', 'playerOrder': 1},
          {'id': 'p2', 'playerName': 'Golfer 2', 'playerOrder': 2},
        ],
        'scores': [
          {
            'id': 's1',
            'playerId': 'p1',
            'holeId': 'h1',
            'grossScore': 4,
            'putts': 2,
            'penalties': 0,
            'fairwayHit': 'STRAIGHT',
            'gir': true,
          },
        ],
        'totals': [
          {
            'playerId': 'p1',
            'playerName': 'Golfer 1',
            'playerOrder': 1,
            'grossScore': 4,
            'putts': 2,
            'penalties': 0,
            'firCount': 1,
            'firPossible': 1,
            'girCount': 1,
            'girPossible': 1,
            'holesCompleted': 1,
          },
        ],
      };

      final matrix = ScorecardMatrix.fromJson(matrixJson);
      expect(matrix.roundId, equals('round-1'));
      expect(matrix.gameMode, equals(GameMode.strokePlay));
      expect(matrix.status, equals(RoundStatus.inProgress));
      expect(matrix.holes.length, equals(2));
      expect(matrix.players.length, equals(2));
      expect(matrix.scores.length, equals(1));
      expect(matrix.totals.length, equals(1));
      expect(matrix.totals.first.grossScore, equals(4));
    });
  });
}

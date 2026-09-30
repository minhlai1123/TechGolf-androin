import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/handicap/models/handicap_models.dart';

void main() {
  group('WHS Handicap Models', () {
    test('HandicapCurrentModel parses established handicap properly', () {
      final json = {
        'userId': 'user-123',
        'handicapIndex': 14.2,
        'isEstablished': true,
        'roundsCount': 10,
        'lastCalculatedAt': '2026-09-28T10:00:00.000Z',
        'status': 'ESTABLISHED',
        'message': 'Official WHS Handicap Index based on 10 eligible rounds.',
      };

      final model = HandicapCurrentModel.fromJson(json);
      expect(model.userId, 'user-123');
      expect(model.handicapIndex, 14.2);
      expect(model.isEstablished, true);
      expect(model.roundsCount, 10);
      expect(model.status, 'ESTABLISHED');
    });

    test('HandicapCurrentModel parses unestablished handicap (< 3 rounds)', () {
      final json = {
        'userId': 'user-456',
        'handicapIndex': 54.0,
        'isEstablished': false,
        'roundsCount': 2,
        'status': 'INSUFFICIENT_ROUNDS',
        'message': 'Needs at least 3 completed 18-hole rounds to establish',
      };

      final model = HandicapCurrentModel.fromJson(json);
      expect(model.isEstablished, false);
      expect(model.roundsCount, 2);
      expect(model.message, contains('Needs at least 3'));
    });

    test('ScoreDifferentialModel deserializes API differential record', () {
      final json = {
        'id': 'diff-1',
        'round_id': 'round-101',
        'course': {'name': 'Royal Golf Links'},
        'courseTee': {'tee_name': 'Blue Championship'},
        'gross_score': 85,
        'adjusted_gross_score': 84,
        'course_rating': 72.1,
        'slope_rating': 128,
        'pcc_adjustment': 0.0,
        'score_differential': 10.5,
        'played_at': '2026-09-25T08:30:00.000Z',
      };

      final diff = ScoreDifferentialModel.fromJson(json);
      expect(diff.id, 'diff-1');
      expect(diff.courseName, 'Royal Golf Links');
      expect(diff.teeName, 'Blue Championship');
      expect(diff.grossScore, 85);
      expect(diff.adjustedGrossScore, 84);
      expect(diff.courseRating, 72.1);
      expect(diff.slopeRating, 128);
      expect(diff.scoreDifferential, 10.5);
    });

    test('HandicapHistoryModel deserializes audit log entry', () {
      final json = {
        'id': 'hist-1',
        'previous_handicap_index': 15.1,
        'resulting_handicap_index': 14.2,
        'differentials_used_count': 3,
        'rounds_count': 10,
        'status': 'VALID',
        'calculated_at': '2026-09-28T12:00:00.000Z',
      };

      final h = HandicapHistoryModel.fromJson(json);
      expect(h.previousHandicapIndex, 15.1);
      expect(h.resultingHandicapIndex, 14.2);
      expect(h.differentialsUsedCount, 3);
      expect(h.roundsCount, 10);
    });
  });
}

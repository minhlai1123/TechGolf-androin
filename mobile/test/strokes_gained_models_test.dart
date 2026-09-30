import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/strokes_gained/models/strokes_gained_models.dart';

void main() {
  group('Strokes Gained Models Tests', () {
    test('StrokesGainedSummaryModel correctly sets isAvailable to false when UNAVAILABLE', () {
      final json = {
        'status': 'UNAVAILABLE',
        'totalStrokesGained': null,
        'categories': {
          'DRIVING': {
            'category': 'DRIVING',
            'shotsCount': 14,
            'strokesGained': null,
            'status': 'UNAVAILABLE',
          },
          'APPROACH': {
            'category': 'APPROACH',
            'shotsCount': 18,
            'strokesGained': null,
            'status': 'UNAVAILABLE',
          },
          'SHORT_GAME': {
            'category': 'SHORT_GAME',
            'shotsCount': 8,
            'strokesGained': null,
            'status': 'UNAVAILABLE',
          },
          'PUTTING': {
            'category': 'PUTTING',
            'shotsCount': 32,
            'strokesGained': null,
            'status': 'UNAVAILABLE',
          },
        },
        'message': 'Strokes Gained data unavailable: Benchmark table is not supplied.',
      };

      final sg = StrokesGainedSummaryModel.fromJson(json);
      expect(sg.isAvailable, false);
      expect(sg.totalStrokesGained, isNull);
      expect(sg.categories['DRIVING']?.shotsCount, 14);
      expect(sg.categories['DRIVING']?.strokesGained, isNull);
      expect(sg.message, contains('Strokes Gained data unavailable'));
    });

    test('StrokesGainedSummaryModel parses available mock data', () {
      final json = {
        'status': 'AVAILABLE',
        'totalStrokesGained': 2.45,
        'categories': {
          'DRIVING': {
            'category': 'DRIVING',
            'shotsCount': 14,
            'strokesGained': 0.85,
            'status': 'AVAILABLE',
          },
        },
        'message': 'Strokes Gained calculated successfully.',
      };

      final sg = StrokesGainedSummaryModel.fromJson(json);
      expect(sg.isAvailable, true);
      expect(sg.totalStrokesGained, 2.45);
      expect(sg.categories['DRIVING']?.strokesGained, 0.85);
    });
  });
}

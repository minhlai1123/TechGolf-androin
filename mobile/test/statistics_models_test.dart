import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/statistics/models/statistics_models.dart';

void main() {
  group('Statistics Models Tests', () {
    test('FirModel parses and computes percentage correctly', () {
      final json = {
        'hitCount': 8,
        'missLeftCount': 3,
        'missRightCount': 3,
        'totalOpportunities': 14,
        'percentage': 57.1,
      };

      final fir = FirModel.fromJson(json);
      expect(fir.hitCount, 8);
      expect(fir.totalOpportunities, 14);
      expect(fir.percentage, 57.1);
    });

    test('GirModel parses accurately', () {
      final json = {
        'hitCount': 9,
        'missCount': 9,
        'totalOpportunities': 18,
        'percentage': 50.0,
      };

      final gir = GirModel.fromJson(json);
      expect(gir.hitCount, 9);
      expect(gir.missCount, 9);
      expect(gir.totalOpportunities, 18);
      expect(gir.percentage, 50.0);
    });

    test('ScramblingModel flags hasOpportunities as false when 0 opportunities exist (NEVER fake 0.0%)', () {
      final jsonNoOpp = {
        'successCount': 0,
        'opportunitiesCount': 0,
        'percentage': null,
        'status': 'NO_OPPORTUNITIES',
        'message': 'No missed greens to calculate scrambling',
      };

      final scram = ScramblingModel.fromJson(jsonNoOpp);
      expect(scram.hasOpportunities, false);
      expect(scram.percentage, isNull);
      expect(scram.status, 'NO_OPPORTUNITIES');

      final jsonWithOpp = {
        'successCount': 2,
        'opportunitiesCount': 4,
        'percentage': 50.0,
        'status': 'AVAILABLE',
      };
      final scram2 = ScramblingModel.fromJson(jsonWithOpp);
      expect(scram2.hasOpportunities, true);
      expect(scram2.percentage, 50.0);
    });

    test('PuttsModel parses putting metrics', () {
      final json = {
        'totalPutts': 32,
        'puttsPerHole': 1.78,
        'puttsPerGir': 1.67,
        'onePuttsCount': 4,
        'twoPuttsCount': 12,
        'threeOrMorePuttsCount': 2,
        'totalHolesWithPutts': 18,
      };

      final putts = PuttsModel.fromJson(json);
      expect(putts.totalPutts, 32);
      expect(putts.puttsPerHole, 1.78);
      expect(putts.puttsPerGir, 1.67);
      expect(putts.onePuttsCount, 4);
    });

    test('StatsOverviewModel aggregates all sections properly', () {
      final json = {
        'roundsPlayed': 5,
        'totalHolesPlayed': 90,
        'scoringAverage': 82.4,
        'bestScore': 78,
        'fir': {
          'hitCount': 40,
          'missLeftCount': 15,
          'missRightCount': 15,
          'totalOpportunities': 70,
          'percentage': 57.1,
        },
        'gir': {
          'hitCount': 45,
          'missCount': 45,
          'totalOpportunities': 90,
          'percentage': 50.0,
        },
        'putts': {
          'totalPutts': 160,
          'puttsPerHole': 1.78,
          'onePuttsCount': 20,
          'twoPuttsCount': 60,
          'threeOrMorePuttsCount': 10,
          'totalHolesWithPutts': 90,
        },
        'scrambling': {
          'successCount': 18,
          'opportunitiesCount': 45,
          'percentage': 40.0,
          'status': 'AVAILABLE',
        },
        'parBreakdown': {
          'par3Average': 3.25,
          'par4Average': 4.55,
          'par5Average': 5.40,
        },
        'scoreDistribution': {
          'eaglesOrBetter': 0,
          'birdies': 5,
          'pars': 45,
          'bogeys': 30,
          'doubleBogeys': 8,
          'tripleOrWorse': 2,
        },
      };

      final overview = StatsOverviewModel.fromJson(json);
      expect(overview.roundsPlayed, 5);
      expect(overview.scoringAverage, 82.4);
      expect(overview.bestScore, 78);
      expect(overview.fir.percentage, 57.1);
      expect(overview.gir.percentage, 50.0);
      expect(overview.scrambling.percentage, 40.0);
      expect(overview.parBreakdown.par3Average, 3.25);
      expect(overview.scoreDistribution.birdies, 5);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';
import 'package:mobile/features/clubs/club_recommendation_engine.dart';
import 'package:mobile/features/shots/models/shot_models.dart';

void main() {
  group('MobileClubRecommendationEngine Tests', () {
    final List<ClubDistanceModel> sampleClubs = [
      const ClubDistanceModel(
        id: 'c-driver',
        clubType: 'DRIVER',
        customName: 'Stealth Driver',
        averageDistanceMeters: 220.0,
        averageDistanceYards: 240.6,
        totalShotsRecorded: 10,
        isActive: true,
      ),
      const ClubDistanceModel(
        id: 'c-5iron',
        clubType: 'IRON_5',
        customName: '5 Iron',
        averageDistanceMeters: 165.0,
        averageDistanceYards: 180.4,
        totalShotsRecorded: 15,
        isActive: true,
      ),
      const ClubDistanceModel(
        id: 'c-7iron',
        clubType: 'IRON_7',
        customName: '7 Iron',
        averageDistanceMeters: 137.16, // exactly 150 yards
        averageDistanceYards: 150.0,
        totalShotsRecorded: 22,
        isActive: true,
      ),
      const ClubDistanceModel(
        id: 'c-9iron',
        clubType: 'IRON_9',
        customName: '9 Iron',
        averageDistanceMeters: 110.0,
        averageDistanceYards: 120.3,
        totalShotsRecorded: 18,
        isActive: true,
      ),
      const ClubDistanceModel(
        id: 'c-inactive',
        clubType: 'IRON_6',
        customName: '6 Iron',
        averageDistanceMeters: 150.0,
        averageDistanceYards: 164.0,
        totalShotsRecorded: 8,
        isActive: false, // inactive!
      ),
    ];

    test('Returns "Not enough shot data" when no clubs have recorded shots', () {
      const emptyClubs = [
        ClubDistanceModel(
          id: 'c1',
          clubType: 'IRON_7',
          averageDistanceMeters: 0.0,
          averageDistanceYards: 0.0,
          totalShotsRecorded: 0,
          isActive: true,
        ),
      ];

      final result = MobileClubRecommendationEngine.recommend(
        remainingDistance: 150.0,
        unit: DistanceUnitType.yards,
        clubs: emptyClubs,
      );

      expect(result.hasRecommendation, isFalse);
      expect(result.recommendedClub, isNull);
      expect(result.message, contains('Not enough shot data'));
    });

    test('Recommends 7 Iron for 150 yards approach', () {
      final result = MobileClubRecommendationEngine.recommend(
        remainingDistance: 150.0,
        unit: DistanceUnitType.yards,
        clubs: sampleClubs,
      );

      expect(result.hasRecommendation, isTrue);
      expect(result.recommendedClub?.clubName, '7 Iron');
      expect(result.recommendedClub?.averageDistance, closeTo(150.0, 0.5));
      expect(result.difference, closeTo(0.0, 0.5));
    });

    test('Recommends 5 Iron for 180 yards approach', () {
      final result = MobileClubRecommendationEngine.recommend(
        remainingDistance: 180.0,
        unit: DistanceUnitType.yards,
        clubs: sampleClubs,
      );

      expect(result.hasRecommendation, isTrue);
      expect(result.recommendedClub?.clubName, '5 Iron');
    });

    test('Filters out inactive clubs even if closest distance', () {
      // 164 yards is exactly 6 Iron, but 6 Iron is inactive
      final result = MobileClubRecommendationEngine.recommend(
        remainingDistance: 164.0,
        unit: DistanceUnitType.yards,
        clubs: sampleClubs,
      );

      expect(result.recommendedClub?.clubName, isNot('6 Iron'));
    });

    test('Handles metric meters unit recommendation', () {
      final result = MobileClubRecommendationEngine.recommend(
        remainingDistance: 110.0,
        unit: DistanceUnitType.meters,
        clubs: sampleClubs,
      );

      expect(result.hasRecommendation, isTrue);
      expect(result.recommendedClub?.clubName, '9 Iron');
      expect(result.recommendedClub?.averageDistance, 110.0);
    });
  });
}

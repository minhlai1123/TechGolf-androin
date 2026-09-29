import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';
import 'package:mobile/features/shots/models/shot_models.dart';

void main() {
  group('Shot & Club Models Tests', () {
    test('ClubDistanceModel parses from JSON correctly', () {
      final json = {
        'id': 'club-123',
        'clubType': 'IRON_7',
        'customName': 'Titleist T200 7i',
        'averageDistanceMeters': 142.5,
        'averageDistanceYards': 155.8,
        'totalShotsRecorded': 28,
        'isActive': true,
      };

      final model = ClubDistanceModel.fromJson(json);
      expect(model.id, 'club-123');
      expect(model.clubType, 'IRON_7');
      expect(model.displayName, 'Titleist T200 7i');
      expect(model.averageDistanceMeters, 142.5);
      expect(model.totalShotsRecorded, 28);
      expect(model.isActive, isTrue);

      final outJson = model.toJson();
      expect(outJson['id'], 'club-123');
      expect(outJson['customName'], 'Titleist T200 7i');
    });

    test('ShotModel parses and serializes lifecycle states properly', () {
      final json = {
        'id': 'shot-456',
        'roundId': 'round-789',
        'playerId': 'player-001',
        'holeId': 'hole-002',
        'clubId': 'club-123',
        'status': 'SAVED',
        'startLatitude': 21.028511,
        'startLongitude': 105.854444,
        'startElevation': 12.0,
        'endLatitude': 21.029800,
        'endLongitude': 105.855200,
        'endElevation': 18.0,
        'elevationDelta': 6.0,
        'distance': 165.4,
        'distanceUnit': 'YARDS',
        'syncStatus': 'synced',
        'createdAt': '2026-09-29T10:00:00.000Z',
      };

      final shot = ShotModel.fromJson(json);
      expect(shot.id, 'shot-456');
      expect(shot.status, ShotLifecycle.saved);
      expect(shot.distance, 165.4);
      expect(shot.distanceUnit, DistanceUnitType.yards);
      expect(shot.syncStatus, ShotSyncStatus.synced);
      expect(shot.elevationDelta, 6.0);

      final copy = shot.copyWith(distance: 170.0, syncStatus: ShotSyncStatus.pending);
      expect(copy.distance, 170.0);
      expect(copy.syncStatus, ShotSyncStatus.pending);
      expect(copy.id, shot.id);

      final outJson = shot.toJson();
      expect(outJson['status'], 'SAVED');
      expect(outJson['distanceUnit'], 'YARDS');
    });
  });
}

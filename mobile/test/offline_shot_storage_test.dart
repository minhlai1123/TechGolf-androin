import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';
import 'package:mobile/features/shots/models/shot_models.dart';
import 'package:mobile/features/shots/services/offline_shot_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineShotStorage Tests', () {
    const roundId = 'round-test-111';
    final shot1 = ShotModel(
      id: 'shot-local-1',
      roundId: roundId,
      playerId: 'player-1',
      holeId: 'hole-1',
      clubId: 'club-7i',
      clubName: '7 Iron',
      status: ShotLifecycle.saved,
      startLatitude: 21.028,
      startLongitude: 105.854,
      endLatitude: 21.029,
      endLongitude: 105.855,
      distance: 155.0,
      distanceUnit: DistanceUnitType.yards,
      syncStatus: ShotSyncStatus.pending,
      createdAt: DateTime.now(),
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and retrieves shots locally for offline usage', () async {
      await OfflineShotStorage.saveShot(shot1);

      final retrieved = await OfflineShotStorage.getShotsForRound(roundId);
      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'shot-local-1');
      expect(retrieved.first.distance, 155.0);
      expect(retrieved.first.syncStatus, ShotSyncStatus.pending);
    });

    test('Updates sync status to synced when backend confirms save', () async {
      await OfflineShotStorage.saveShot(shot1);
      await OfflineShotStorage.markShotSynced(roundId, 'shot-local-1');

      final retrieved = await OfflineShotStorage.getShotsForRound(roundId);
      expect(retrieved.first.syncStatus, ShotSyncStatus.synced);
    });

    test('Clears all shots for a round when round cache is reset', () async {
      await OfflineShotStorage.saveShot(shot1);
      await OfflineShotStorage.clearRoundShots(roundId);

      final retrieved = await OfflineShotStorage.getShotsForRound(roundId);
      expect(retrieved, isEmpty);
    });
  });
}

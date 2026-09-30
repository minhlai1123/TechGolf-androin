import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/geo/distance_engine.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/offline_course_storage.dart';
import 'package:mobile/core/storage/offline_score_storage.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/rounds/models/round_models.dart';
import 'package:mobile/features/shots/models/shot_models.dart';
import 'package:mobile/features/shots/services/offline_shot_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Phase 9: Offline Integration & Synchronization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('OfflineScoreStorage preserves scores and manages pending sync queue', () async {
      final score1 = RoundScoreModel(
        id: 's-1',
        roundId: 'round-offline-1',
        playerId: 'p-1',
        holeId: 'h-1',
        grossScore: 4,
        putts: 2,
        penalties: 0,
        fairwayHit: FairwayHit.straight,
        gir: true,
      );

      final score2 = RoundScoreModel(
        id: 's-2',
        roundId: 'round-offline-1',
        playerId: 'p-1',
        holeId: 'h-2',
        grossScore: 5,
        putts: 3,
        penalties: 0,
        fairwayHit: FairwayHit.left,
        gir: false,
      );

      // 1. Save scores as pending (entered offline)
      await OfflineScoreStorage.saveScore(score1, isPending: true);
      await OfflineScoreStorage.saveScore(score2, isPending: true);

      expect(await OfflineScoreStorage.hasPendingScores('round-offline-1'), isTrue);

      // 2. Retrieve offline scores
      final retrieved = await OfflineScoreStorage.getScoresForRound('round-offline-1');
      expect(retrieved.length, 2);
      expect(retrieved['p-1-h-1']?.grossScore, 4);
      expect(retrieved['p-1-h-2']?.grossScore, 5);

      // 3. Simulate sync failure (still offline)
      final failingClient = ApiClient(
        client: MockClient((request) async {
          throw Exception('Connection refused');
        }),
      );

      final failedCount = await OfflineScoreStorage.syncPendingScores(failingClient, 'round-offline-1');
      expect(failedCount, 0);
      // Data MUST NOT be lost on failed sync
      expect(await OfflineScoreStorage.hasPendingScores('round-offline-1'), isTrue);
      final preserved = await OfflineScoreStorage.getScoresForRound('round-offline-1');
      expect(preserved.length, 2);

      // 4. Simulate network restored (successful sync)
      int networkCalls = 0;
      final successClient = ApiClient(
        client: MockClient((request) async {
          networkCalls++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'score-backend-$networkCalls',
              'roundId': 'round-offline-1',
              'playerId': body['playerId'],
              'holeId': body['holeId'],
              'grossScore': body['grossScore'],
              'putts': body['putts'],
              'penalties': body['penalties'],
            }),
            200,
          );
        }),
      );

      final syncedCount = await OfflineScoreStorage.syncPendingScores(successClient, 'round-offline-1');
      expect(syncedCount, 2);
      expect(networkCalls, 2);
      expect(await OfflineScoreStorage.hasPendingScores('round-offline-1'), isFalse);
    });

    test('OfflineShotStorage saves pending shots and syncs when online resumes', () async {
      final shot = ShotModel(
        id: 'shot-offline-101',
        roundId: 'round-offline-2',
        playerId: 'p-1',
        holeId: 'h-1',
        clubId: 'club-7i',
        clubName: '7 Iron',
        status: ShotLifecycle.saved,
        startLatitude: 21.028511,
        startLongitude: 105.854444,
        endLatitude: 21.029811,
        endLongitude: 105.855444,
        distance: 165.0,
        distanceUnit: DistanceUnitType.yards,
        syncStatus: ShotSyncStatus.pending,
        createdAt: DateTime.now(),
      );

      // 1. Save shot locally as pending
      await OfflineShotStorage.saveShot(shot);
      expect(await OfflineShotStorage.hasPendingShots('round-offline-2'), isTrue);

      final cachedShots = await OfflineShotStorage.getShotsForRound('round-offline-2');
      expect(cachedShots.length, 1);
      expect(cachedShots.first.id, 'shot-offline-101');
      expect(cachedShots.first.distance, 165.0);

      // 2. Simulate sync failure (offline)
      final failingClient = ApiClient(
        client: MockClient((request) async {
          throw Exception('Offline error');
        }),
      );

      final failedShots = await OfflineShotStorage.syncPendingShots(failingClient, 'round-offline-2');
      expect(failedShots, 0);
      expect(await OfflineShotStorage.hasPendingShots('round-offline-2'), isTrue);

      // 3. Simulate sync success when online resumes
      final successClient = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.contains('/shots/start')) {
            return http.Response(jsonEncode({'id': 'backend-shot-101'}), 200);
          }
          return http.Response(jsonEncode({'status': 'saved'}), 200);
        }),
      );

      final syncedShots = await OfflineShotStorage.syncPendingShots(successClient, 'round-offline-2');
      expect(syncedShots, 1);
      expect(await OfflineShotStorage.hasPendingShots('round-offline-2'), isFalse);
    });

    test('Preloaded CourseBundle enables full offline F/M/B calculation without internet', () async {
      final prefs = await SharedPreferences.getInstance();
      final courseStorage = OfflineCourseStorage(prefs);

      const courseBundleJson = '''{
        "course": {"id": "course-offline-1", "name": "Ha Noi Golf Club", "holesCount": 1},
        "tees": [{"id": "tee-1", "courseId": "course-offline-1", "teeName": "Blue", "teeColorHex": "#0000FF", "courseRating": 72.0, "slopeRating": 130}],
        "holes": [{
          "id": "hole-1",
          "courseId": "course-offline-1",
          "holeNumber": 1,
          "par": 4,
          "handicapIndex": 5,
          "greenCenterLat": 21.030000,
          "greenCenterLng": 105.850000,
          "greenFrontLat": 21.029800,
          "greenFrontLng": 105.850000,
          "greenBackLat": 21.030200,
          "greenBackLng": 105.850000,
          "tees": [],
          "polygons": []
        }],
        "downloadedAt": "2026-09-30T12:00:00.000Z"
      }''';

      // Save offline
      await courseStorage.saveBundle('course-offline-1', courseBundleJson);
      expect(courseStorage.isCourseSaved('course-offline-1'), isTrue);

      // Load offline
      final loadedBundle = courseStorage.getBundle('course-offline-1');
      expect(loadedBundle, isNotNull);
      expect(loadedBundle!.holes.length, 1);

      final h1 = loadedBundle.holes.first;

      // Player stands at distance away from green
      final playerLat = 21.028000;
      final playerLng = 105.850000;

      // Calculate distances offline using geodesic engine
      final distFront = DistanceEngine.distanceBetweenMeters(playerLat, playerLng, h1.greenFrontLat!, h1.greenFrontLng!);
      final distCenter = DistanceEngine.distanceBetweenMeters(playerLat, playerLng, h1.greenCenterLat!, h1.greenCenterLng!);
      final distBack = DistanceEngine.distanceBetweenMeters(playerLat, playerLng, h1.greenBackLat!, h1.greenBackLng!);

      // Front is closer than Center, which is closer than Back
      expect(distFront < distCenter, isTrue);
      expect(distCenter < distBack, isTrue);

      final yardsCenter = DistanceEngine.metersToYards(distCenter);
      expect(yardsCenter > 100, isTrue);
    });

    test('Data integrity preserved across mock app restarts without duplication', () async {
      // Round scores saved
      final score = RoundScoreModel(
        id: 's-persistent-1',
        roundId: 'round-persistent',
        playerId: 'p-1',
        holeId: 'h-1',
        grossScore: 4,
        putts: 2,
        penalties: 0,
        gir: true,
      );

      await OfflineScoreStorage.saveScore(score, isPending: true);

      // Simulate App Restart by retrieving freshly
      final reloaded = await OfflineScoreStorage.getScoresForRound('round-persistent');
      expect(reloaded.containsKey('p-1-h-1'), isTrue);
      expect(reloaded['p-1-h-1']!.grossScore, 4);

      // Re-saving same score updates in place without duplicating
      final updatedScore = RoundScoreModel(
        id: 's-persistent-1',
        roundId: 'round-persistent',
        playerId: 'p-1',
        holeId: 'h-1',
        grossScore: 3, // birdied!
        putts: 1,
        penalties: 0,
        gir: true,
      );

      await OfflineScoreStorage.saveScore(updatedScore, isPending: true);

      final updatedMap = await OfflineScoreStorage.getScoresForRound('round-persistent');
      expect(updatedMap.length, 1); // exactly 1 item, no duplicate!
      expect(updatedMap['p-1-h-1']!.grossScore, 3);
      expect(updatedMap['p-1-h-1']!.putts, 1);
    });
  });
}

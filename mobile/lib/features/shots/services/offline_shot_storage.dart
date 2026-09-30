import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/geo/plays_like_engine.dart';
import '../../../core/network/api_client.dart';
import '../models/shot_models.dart';

class OfflineShotStorage {
  static const String _prefix = 'techgolf_offline_shots_';
  static const String _pendingKey = 'techgolf_pending_sync_shot_ids';

  /// Save or update a shot in local offline storage
  static Future<void> saveShot(ShotModel shot) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_prefix${shot.roundId}';

    final List<ShotModel> shots = await getShotsForRound(shot.roundId);
    final int index = shots.indexWhere((s) => s.id == shot.id);

    if (index >= 0) {
      shots[index] = shot;
    } else {
      shots.add(shot);
    }

    final String jsonStr = jsonEncode(shots.map((s) => s.toJson()).toList());
    await prefs.setString(key, jsonStr);

    // Track pending sync if applicable
    if (shot.syncStatus == ShotSyncStatus.pending) {
      final List<String> pendingIds = prefs.getStringList(_pendingKey) ?? [];
      if (!pendingIds.contains(shot.id)) {
        pendingIds.add(shot.id);
        await prefs.setStringList(_pendingKey, pendingIds);
      }
    }
  }

  /// Retrieve all locally cached shots for a specific round
  static Future<List<ShotModel>> getShotsForRound(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_prefix$roundId';
    final String? jsonStr = prefs.getString(key);

    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => ShotModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mark a locally saved shot as synced with the backend
  static Future<void> markShotSynced(String roundId, String shotId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ShotModel> shots = await getShotsForRound(roundId);
    final int index = shots.indexWhere((s) => s.id == shotId);

    if (index >= 0) {
      shots[index] = shots[index].copyWith(syncStatus: ShotSyncStatus.synced);
      final String key = '$_prefix$roundId';
      await prefs.setString(key, jsonEncode(shots.map((s) => s.toJson()).toList()));
    }

    final List<String> pendingIds = prefs.getStringList(_pendingKey) ?? [];
    pendingIds.remove(shotId);
    await prefs.setStringList(_pendingKey, pendingIds);
  }

  /// Check whether there are pending unsynced shots
  static Future<bool> hasPendingShots(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingIds = prefs.getStringList(_pendingKey) ?? [];
    if (pendingIds.isEmpty) return false;
    final shots = await getShotsForRound(roundId);
    return shots.any((s) => pendingIds.contains(s.id));
  }

  /// Sync all pending shots for a round to backend
  /// Never deletes pending shots on network failure
  static Future<int> syncPendingShots(ApiClient apiClient, String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingIds = prefs.getStringList(_pendingKey) ?? [];
    if (pendingIds.isEmpty) return 0;

    final List<ShotModel> shots = await getShotsForRound(roundId);
    int syncedCount = 0;

    for (final shot in shots) {
      if (pendingIds.contains(shot.id)) {
        try {
          final startRes = await apiClient.startShot(
            roundId: roundId,
            playerId: shot.playerId,
            holeId: shot.holeId,
            latitude: shot.startLatitude,
            longitude: shot.startLongitude,
            clubId: shot.clubId,
            elevation: shot.startElevation,
            unit: shot.distanceUnit.nameUpper,
          );

          final backendShotId = startRes['id'] as String;

          await apiClient.saveShot(
            roundId: roundId,
            shotId: backendShotId,
            clubId: shot.clubId ?? '',
            latitude: shot.endLatitude ?? shot.startLatitude,
            longitude: shot.endLongitude ?? shot.startLongitude,
            elevation: shot.endElevation,
            unit: shot.distanceUnit.nameUpper,
          );

          await markShotSynced(roundId, shot.id);
          syncedCount++;
        } catch (_) {
          // Keep in pending queue on network error
        }
      }
    }

    return syncedCount;
  }

  /// Clear all offline shots for a round
  static Future<void> clearRoundShots(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$roundId');
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Clear all offline shots for a round
  static Future<void> clearRoundShots(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$roundId');
  }
}

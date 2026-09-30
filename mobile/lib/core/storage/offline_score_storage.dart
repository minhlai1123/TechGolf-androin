import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/rounds/models/round_models.dart';
import '../network/api_client.dart';

/// Local offline storage and sync manager for round hole scores
class OfflineScoreStorage {
  static const String _scoresPrefix = 'techgolf_offline_scores_';
  static const String _pendingPrefix = 'techgolf_pending_score_keys_';

  static String _scoreKey(String playerId, String holeId) => '$playerId-$holeId';

  /// Save or update a score in local storage
  static Future<void> saveScore(RoundScoreModel score, {bool isPending = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_scoresPrefix${score.roundId}';

    final scoresMap = await getScoresForRound(score.roundId);
    final mapKey = _scoreKey(score.playerId, score.holeId);
    scoresMap[mapKey] = score;

    final List<Map<String, dynamic>> rawList = scoresMap.values.map((s) => s.toJson()).toList();
    await prefs.setString(key, jsonEncode(rawList));

    if (isPending) {
      final pendingKey = '$_pendingPrefix${score.roundId}';
      final List<String> pendingKeys = prefs.getStringList(pendingKey) ?? [];
      if (!pendingKeys.contains(mapKey)) {
        pendingKeys.add(mapKey);
        await prefs.setStringList(pendingKey, pendingKeys);
      }
    }
  }

  /// Retrieve all locally cached scores for a round as a Map keyed by 'playerId-holeId'
  static Future<Map<String, RoundScoreModel>> getScoresForRound(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_scoresPrefix$roundId';
    final String? jsonStr = prefs.getString(key);

    if (jsonStr == null || jsonStr.isEmpty) {
      return {};
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      final Map<String, RoundScoreModel> map = {};
      for (final item in list) {
        final score = RoundScoreModel.fromJson(item as Map<String, dynamic>);
        map[_scoreKey(score.playerId, score.holeId)] = score;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Mark a locally saved score as synced with the backend
  static Future<void> markScoreSynced(String roundId, String playerId, String holeId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = '$_pendingPrefix$roundId';
    final List<String> pendingKeys = prefs.getStringList(pendingKey) ?? [];
    final mapKey = _scoreKey(playerId, holeId);
    if (pendingKeys.remove(mapKey)) {
      await prefs.setStringList(pendingKey, pendingKeys);
    }
  }

  /// Check whether there are pending unsynced scores for a round
  static Future<bool> hasPendingScores(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = '$_pendingPrefix$roundId';
    final List<String> pendingKeys = prefs.getStringList(pendingKey) ?? [];
    return pendingKeys.isNotEmpty;
  }

  /// Sync all pending scores to backend via ApiClient
  /// Never deletes pending scores on failure
  static Future<int> syncPendingScores(ApiClient apiClient, String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = '$_pendingPrefix$roundId';
    final List<String> pendingKeys = prefs.getStringList(pendingKey) ?? [];

    if (pendingKeys.isEmpty) return 0;

    final scoresMap = await getScoresForRound(roundId);
    int syncedCount = 0;
    final List<String> remainingKeys = List<String>.from(pendingKeys);

    for (final mapKey in pendingKeys) {
      final score = scoresMap[mapKey];
      if (score != null) {
        try {
          await apiClient.saveScore(
            roundId: roundId,
            playerId: score.playerId,
            holeId: score.holeId,
            grossScore: score.grossScore,
            putts: score.putts,
            penalties: score.penalties,
            fairwayHit: score.fairwayHit,
            gir: score.gir,
          );

          remainingKeys.remove(mapKey);
          syncedCount++;
        } catch (_) {
          // Keep remainingKeys on network error, proceed to try others
        }
      } else {
        remainingKeys.remove(mapKey);
      }
    }

    await prefs.setStringList(pendingKey, remainingKeys);
    return syncedCount;
  }

  /// Clear offline scores for a round
  static Future<void> clearRoundScores(String roundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_scoresPrefix$roundId');
    await prefs.remove('$_pendingPrefix$roundId');
  }
}

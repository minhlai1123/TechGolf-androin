import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../features/courses/models/course_bundle_models.dart';
import '../../features/rounds/models/round_models.dart';
import '../../features/game_modes/game_mode_engine.dart';
import '../../features/handicap/models/handicap_models.dart';
import '../../features/statistics/models/statistics_models.dart';
import '../../features/strokes_gained/models/strokes_gained_models.dart';

class CourseBundleResponse {
  final CourseBundle bundle;
  final String rawJson;

  const CourseBundleResponse({
    required this.bundle,
    required this.rawJson,
  });
}

/// HTTP API Client for TechGolf backend
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? authToken;

  ApiClient({
    String? baseUrl,
    http.Client? client,
    this.authToken,
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return AppConstants.localhostBaseUrl;
    }
    try {
      if (Platform.isAndroid) {
        return AppConstants.apiBaseUrl; // 10.0.2.2:3000
      }
    } catch (_) {}
    return AppConstants.localhostBaseUrl;
  }

  /// Fetches course list from backend
  Future<List<CourseInfo>> getCourses() async {
    final uri = Uri.parse('$baseUrl/courses');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CourseInfo.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load courses: ${response.statusCode}');
    }
  }

  /// Downloads full course bundle
  Future<CourseBundleResponse> getCourseBundle(String courseId) async {
    final uri = Uri.parse('$baseUrl/courses/$courseId/bundle');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final bundle = CourseBundle.fromJson(data);
      return CourseBundleResponse(
        bundle: bundle,
        rawJson: response.body,
      );
    } else {
      throw Exception('Failed to load course bundle ($courseId): ${response.statusCode}');
    }
  }

  /// Creates a new round with 1 to 4 players
  Future<RoundModel> createRound({
    required String courseId,
    required GameMode gameMode,
    required List<Map<String, dynamic>> players,
  }) async {
    final uri = Uri.parse('$baseUrl/rounds');
    final payload = jsonEncode({
      'courseId': courseId,
      'gameMode': gameMode.value,
      'players': players,
    });

    final response = await _client
        .post(uri, headers: _headers, body: payload)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoundModel.fromJson(data);
    } else {
      throw Exception('Failed to create round: ${response.statusCode} - ${response.body}');
    }
  }

  /// Retrieves round details
  Future<RoundModel> getRound(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoundModel.fromJson(data);
    } else {
      throw Exception('Failed to get round: ${response.statusCode}');
    }
  }

  /// Starts a round
  Future<RoundModel> startRound(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/start');
    final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoundModel.fromJson(data);
    } else {
      throw Exception('Failed to start round: ${response.statusCode}');
    }
  }

  /// Updates current hole number
  Future<void> updateCurrentHole(String roundId, int currentHole) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/current-hole');
    final payload = jsonEncode({'currentHole': currentHole});
    final response = await _client
        .patch(uri, headers: _headers, body: payload)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to update current hole: ${response.statusCode}');
    }
  }

  /// Finishes a round
  Future<RoundModel> finishRound(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/finish');
    final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoundModel.fromJson(data);
    } else {
      throw Exception('Failed to finish round: ${response.statusCode}');
    }
  }

  /// Saves or updates a score for a player on a hole
  Future<RoundScoreModel> saveScore({
    required String roundId,
    required String playerId,
    required String holeId,
    required int grossScore,
    int putts = 0,
    int penalties = 0,
    FairwayHit? fairwayHit,
    bool? gir,
  }) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/scores');
    final payload = jsonEncode({
      'playerId': playerId,
      'holeId': holeId,
      'grossScore': grossScore,
      'putts': putts,
      'penalties': penalties,
      'fairwayHit': fairwayHit?.value,
      'gir': gir,
    });

    final response = await _client
        .post(uri, headers: _headers, body: payload)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoundScoreModel.fromJson(data);
    } else {
      throw Exception('Failed to save score: ${response.statusCode} - ${response.body}');
    }
  }

  /// Retrieves full scorecard matrix
  Future<ScorecardMatrix> getScorecard(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/scorecard');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ScorecardMatrix.fromJson(data);
    } else {
      throw Exception('Failed to get scorecard: ${response.statusCode}');
    }
  }

  /// Retrieves game mode result
  Future<Map<String, dynamic>> getRoundResult(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/result');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get round result: ${response.statusCode}');
    }
  }

  /// Start a shot in a round
  Future<Map<String, dynamic>> startShot({
    required String roundId,
    required String playerId,
    required String holeId,
    required double latitude,
    required double longitude,
    String? clubId,
    double? elevation,
    String unit = 'YARDS',
  }) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/shots/start');
    final Map<String, dynamic> payload = {
      'playerId': playerId,
      'holeId': holeId,
      'latitude': latitude,
      'longitude': longitude,
      'unit': unit,
    };
    if (clubId != null) payload['clubId'] = clubId;
    if (elevation != null) payload['elevation'] = elevation;
    final body = jsonEncode(payload);

    final response = await _client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 10));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start shot: ${response.statusCode} - ${response.body}');
    }
  }

  /// Save completed shot with end coordinates and club
  Future<Map<String, dynamic>> saveShot({
    required String roundId,
    required String shotId,
    required String clubId,
    required double latitude,
    required double longitude,
    double? elevation,
    String unit = 'YARDS',
  }) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/shots/$shotId/save');
    final Map<String, dynamic> payload = {
      'clubId': clubId,
      'latitude': latitude,
      'longitude': longitude,
      'unit': unit,
    };
    if (elevation != null) payload['elevation'] = elevation;
    final body = jsonEncode(payload);

    final response = await _client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save shot: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get shots in round
  Future<List<dynamic>> getShotsByRound(String roundId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/shots');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get round shots: ${response.statusCode}');
    }
  }

  /// Get shots for hole
  Future<List<dynamic>> getShotsByHole(String roundId, String holeId) async {
    final uri = Uri.parse('$baseUrl/rounds/$roundId/holes/$holeId/shots');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get hole shots: ${response.statusCode}');
    }
  }

  /// Get user's club average distances
  Future<List<dynamic>> getClubDistances() async {
    final uri = Uri.parse('$baseUrl/bag/clubs/distances');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get club distances: ${response.statusCode}');
    }
  }

  /// Recommend club based on distance and elevation
  Future<Map<String, dynamic>> recommendClub({
    required double remainingDistance,
    String unit = 'YARDS',
    double? startElevation,
    double? targetElevation,
  }) async {
    final uri = Uri.parse('$baseUrl/bag/clubs/recommend');
    final Map<String, dynamic> payload = {
      'remainingDistance': remainingDistance,
      'unit': unit,
    };
    if (startElevation != null) payload['startElevation'] = startElevation;
    if (targetElevation != null) payload['targetElevation'] = targetElevation;
    final body = jsonEncode(payload);

    final response = await _client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get club recommendation: ${response.statusCode}');
    }
  }

  /// Get current WHS Handicap Index
  Future<HandicapCurrentModel> getCurrentHandicap() async {
    final uri = Uri.parse('$baseUrl/handicap/current');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return HandicapCurrentModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get current handicap: ${response.statusCode}');
    }
  }

  /// Get chronological handicap history
  Future<List<HandicapHistoryModel>> getHandicapHistory() async {
    final uri = Uri.parse('$baseUrl/handicap/history');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => HandicapHistoryModel.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get handicap history: ${response.statusCode}');
    }
  }

  /// Get recorded score differentials
  Future<List<ScoreDifferentialModel>> getScoreDifferentials() async {
    final uri = Uri.parse('$baseUrl/handicap/differentials');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => ScoreDifferentialModel.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get score differentials: ${response.statusCode}');
    }
  }

  /// Recalculate WHS Handicap Index
  Future<Map<String, dynamic>> recalculateHandicap() async {
    final uri = Uri.parse('$baseUrl/handicap/recalculate');
    final response = await _client.post(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to recalculate handicap: ${response.statusCode}');
    }
  }

  /// Get golf statistics overview
  Future<StatsOverviewModel> getStatsOverview({int? limit}) async {
    final query = limit != null ? '?limit=$limit' : '';
    final uri = Uri.parse('$baseUrl/stats/overview$query');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return StatsOverviewModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get stats overview: ${response.statusCode}');
    }
  }

  /// Get chronological performance trends
  Future<List<TrendPointModel>> getStatsTrends({int? limit}) async {
    final query = limit != null ? '?limit=$limit' : '';
    final uri = Uri.parse('$baseUrl/stats/trends$query');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => TrendPointModel.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to get stats trends: ${response.statusCode}');
    }
  }

  /// Get Strokes Gained analytics
  Future<StrokesGainedSummaryModel> getStrokesGained({String? roundId}) async {
    final query = roundId != null ? '?roundId=$roundId' : '';
    final uri = Uri.parse('$baseUrl/stats/strokes-gained$query');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return StrokesGainedSummaryModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get strokes gained: ${response.statusCode}');
    }
  }

  void close() {
    _client.close();
  }
}

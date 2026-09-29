import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../features/courses/models/course_bundle_models.dart';

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

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _client = client ?? http.Client();

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
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

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
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));

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

  void close() {
    _client.close();
  }
}

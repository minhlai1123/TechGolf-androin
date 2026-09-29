import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/courses/models/course_bundle_models.dart';

/// Local offline storage for Course Bundles using SharedPreferences
class OfflineCourseStorage {
  static const String _bundlePrefix = 'techgolf_course_bundle_';
  static const String _savedCoursesKey = 'techgolf_saved_courses_ids';

  final SharedPreferences _prefs;

  OfflineCourseStorage(this._prefs);

  static Future<OfflineCourseStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineCourseStorage(prefs);
  }

  /// Saves a full course bundle to local storage
  Future<bool> saveBundle(String courseId, String bundleJson) async {
    try {
      final success = await _prefs.setString('$_bundlePrefix$courseId', bundleJson);
      if (success) {
        final List<String> savedList = _prefs.getStringList(_savedCoursesKey) ?? [];
        if (!savedList.contains(courseId)) {
          savedList.add(courseId);
          await _prefs.setStringList(_savedCoursesKey, savedList);
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Loads course bundle from local storage
  CourseBundle? getBundle(String courseId) {
    try {
      final jsonStr = _prefs.getString('$_bundlePrefix$courseId');
      if (jsonStr == null) return null;
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return CourseBundle.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Checks if course bundle is saved offline
  bool isCourseSaved(String courseId) {
    return _prefs.containsKey('$_bundlePrefix$courseId');
  }

  /// Removes saved course bundle
  Future<bool> removeCourse(String courseId) async {
    final removed = await _prefs.remove('$_bundlePrefix$courseId');
    final List<String> savedList = _prefs.getStringList(_savedCoursesKey) ?? [];
    if (savedList.contains(courseId)) {
      savedList.remove(courseId);
      await _prefs.setStringList(_savedCoursesKey, savedList);
    }
    return removed;
  }

  /// List all offline course IDs
  List<String> getOfflineCourseIds() {
    return _prefs.getStringList(_savedCoursesKey) ?? [];
  }
}

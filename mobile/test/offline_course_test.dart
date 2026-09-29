import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/offline_course_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OfflineCourseStorage Tests', () {
    late OfflineCourseStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = OfflineCourseStorage(prefs);
    });

    test('Saves, retrieves, and removes CourseBundle locally for offline usage', () async {
      const courseId = 'course-pine-valley-123';
      final bundleData = {
        'course': {
          'id': courseId,
          'name': 'Pine Valley Golf Club',
          'holesCount': 18,
          'isVerified': true,
        },
        'tees': [],
        'holes': [
          {
            'id': 'hole-1',
            'courseId': courseId,
            'holeNumber': 1,
            'par': 4,
            'greenCenterLat': 39.7892,
            'greenCenterLng': -74.9754,
            'tees': [],
            'map': {'type': 'FeatureCollection', 'features': []},
          }
        ],
        'downloadedAt': '2026-09-29T12:00:00.000Z',
      };
      final bundleJson = jsonEncode(bundleData);

      // 1. Initial state: not saved
      expect(storage.isCourseSaved(courseId), isFalse);
      expect(storage.getBundle(courseId), isNull);
      expect(storage.getOfflineCourseIds(), isEmpty);

      // 2. Save bundle
      final saveResult = await storage.saveBundle(courseId, bundleJson);
      expect(saveResult, isTrue);
      expect(storage.isCourseSaved(courseId), isTrue);
      expect(storage.getOfflineCourseIds(), contains(courseId));

      // 3. Retrieve and parse bundle
      final loadedBundle = storage.getBundle(courseId);
      expect(loadedBundle, isNotNull);
      expect(loadedBundle!.course.id, equals(courseId));
      expect(loadedBundle.course.name, equals('Pine Valley Golf Club'));
      expect(loadedBundle.holes.length, equals(1));
      expect(loadedBundle.holes.first.greenCenterLat, equals(39.7892));

      // 4. Remove bundle
      final removeResult = await storage.removeCourse(courseId);
      expect(removeResult, isTrue);
      expect(storage.isCourseSaved(courseId), isFalse);
      expect(storage.getBundle(courseId), isNull);
      expect(storage.getOfflineCourseIds(), isEmpty);
    });
  });
}

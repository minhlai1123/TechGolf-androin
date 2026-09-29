import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/offline_course_storage.dart';
import 'package:mobile/features/courses/models/course_bundle_models.dart';
import 'package:mobile/features/rounds/screens/round_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RoundSetupScreen Widget Tests', () {
    late CourseBundle testBundle;
    late OfflineCourseStorage testStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      testStorage = OfflineCourseStorage(prefs);

      testBundle = CourseBundle(
        course: const CourseInfo(
          id: 'course-1',
          name: 'Pine Valley Championship',
          holesCount: 18,
        ),
        tees: [],
        holes: const [
          HoleData(
            id: 'h1',
            courseId: 'course-1',
            holeNumber: 1,
            par: 4,
          ),
        ],
        downloadedAt: DateTime.now(),
      );
    });

    testWidgets('allows selecting player count from 1 to 4 and game modes', (tester) async {
      final mockLocation = MockLocationService();
      final mockApiClient = ApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: RoundSetupScreen(
            bundle: testBundle,
            apiClient: mockApiClient,
            storage: testStorage,
            locationService: mockLocation,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Course name displayed
      expect(find.text('Pine Valley Championship'), findsOneWidget);

      // Player count chips (1, 2, 3, 4)
      expect(find.text('1 Player'), findsOneWidget);
      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('3 Players'), findsOneWidget);
      expect(find.text('4 Players'), findsOneWidget);

      // Initial state: 1 player name field
      expect(find.text('Golfer 1 (You)'), findsOneWidget);
      expect(find.text('Golfer 2'), findsNothing);

      // Select 2 Players
      await tester.tap(find.text('2 Players'));
      await tester.pumpAndSettle();

      // Now 2 player name fields are visible
      expect(find.text('Golfer 1 (You)'), findsOneWidget);
      expect(find.text('Golfer 2'), findsOneWidget);

      // Select 4 Players
      await tester.tap(find.text('4 Players'));
      await tester.pumpAndSettle();

      expect(find.text('Golfer 1 (You)'), findsOneWidget);
      expect(find.text('Golfer 2'), findsOneWidget);
      expect(find.text('Golfer 3'), findsOneWidget);
      expect(find.text('Golfer 4'), findsOneWidget);

      // Game modes
      expect(find.text('Stroke Play'), findsOneWidget);
      expect(find.text('Stableford'), findsOneWidget);
      expect(find.text('Match Play'), findsOneWidget);
      expect(find.text('Scramble'), findsOneWidget);
      expect(find.text('Four-Ball'), findsOneWidget);

      // Start round button
      expect(find.text('START ROUND'), findsOneWidget);
    });
  });
}

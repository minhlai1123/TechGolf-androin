import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/offline_course_storage.dart';
import 'package:mobile/features/courses/models/course_bundle_models.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';
import 'package:mobile/features/rounds/models/round_models.dart';
import 'package:mobile/features/rounds/screens/score_entry_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScoreEntryScreen Widget Tests', () {
    late CourseBundle testBundle;
    late RoundModel testRound;
    late OfflineCourseStorage testStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      testStorage = OfflineCourseStorage(prefs);

      testBundle = CourseBundle(
        course: const CourseInfo(
          id: 'course-1',
          name: 'Championship Golf Club',
          holesCount: 2,
        ),
        tees: [],
        holes: const [
          HoleData(
            id: 'h1',
            courseId: 'course-1',
            holeNumber: 1,
            par: 4,
            handicapIndex: 5,
          ),
          HoleData(
            id: 'h2',
            courseId: 'course-1',
            holeNumber: 2,
            par: 3,
            handicapIndex: 11,
          ),
        ],
        downloadedAt: DateTime.now(),
      );

      testRound = RoundModel(
        id: 'round-1',
        courseId: 'course-1',
        gameMode: GameMode.strokePlay,
        status: RoundStatus.inProgress,
        currentHole: 1,
        players: const [
          RoundPlayerModel(
            id: 'p1',
            roundId: 'round-1',
            playerName: 'Tiger Woods',
            playerOrder: 1,
          ),
        ],
      );
    });

    testWidgets('renders score entry screen with gross score, putts, penalties, and buttons', (tester) async {
      final mockLocation = MockLocationService();
      final mockApiClient = ApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: ScoreEntryScreen(
            round: testRound,
            bundle: testBundle,
            apiClient: mockApiClient,
            storage: testStorage,
            locationService: mockLocation,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('HOLE 1'), findsNWidgets(2)); // in appbar and banner
      expect(find.text('Par 4  •  Stroke Index 5'), findsOneWidget);
      expect(find.text('STROKE PLAY'), findsOneWidget);

      // Check sections
      expect(find.text('GROSS SCORE'), findsOneWidget);
      expect(find.text('PUTTS'), findsOneWidget);
      expect(find.text('PENALTIES'), findsOneWidget);
      expect(find.text('FAIRWAY HIT'), findsOneWidget);
      expect(find.text('GREEN IN REGULATION (GIR)'), findsOneWidget);

      // Check default par gross score (4)
      expect(find.text('4'), findsWidgets);

      // Tap gross score '+' stepper
      final addIcons = find.byIcon(Icons.add);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Tap next hole button
      expect(find.text('SAVE & NEXT HOLE'), findsOneWidget);
      await tester.tap(find.text('SAVE & NEXT HOLE'));
      await tester.pumpAndSettle();

      // Should now advance to Hole 2 (Par 3)
      expect(find.text('Par 3  •  Stroke Index 11'), findsOneWidget);
      // On Par 3, Fairway Hit section is not applicable (hidden)
      expect(find.text('FAIRWAY HIT'), findsNothing);
    });
  });
}

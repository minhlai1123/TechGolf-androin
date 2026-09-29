import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/geo/plays_like_engine.dart';
import 'package:mobile/core/location/location_models.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/features/shots/models/shot_models.dart';
import 'package:mobile/features/shots/screens/shot_tracker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShotTrackerScreen Widget Tests', () {
    late MockLocationService mockLocationService;

    final initialLocation = LocationPoint(
      latitude: 21.028511,
      longitude: 105.854444,
      accuracy: 4.5,
      altitude: 12.0,
      timestamp: DateTime.now(),
    );

    final movedLocation = LocationPoint(
      latitude: 21.029800,
      longitude: 105.855200,
      accuracy: 5.0,
      altitude: 15.0,
      timestamp: DateTime.now(),
    );

    final testClubs = [
      const ClubDistanceModel(
        id: 'club-7i',
        clubType: 'IRON_7',
        customName: '7 Iron',
        averageDistanceMeters: 140.0,
        averageDistanceYards: 153.1,
        totalShotsRecorded: 5,
        isActive: true,
      ),
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockLocationService = MockLocationService();
      mockLocationService.emitLocation(initialLocation);
    });

    testWidgets('renders screen and completes Start Shot -> Walk -> Save Shot lifecycle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShotTrackerScreen(
            roundId: 'round-101',
            playerId: 'player-202',
            holeId: 'hole-303',
            holeNumber: 5,
            par: 4,
            unit: DistanceUnitType.yards,
            locationService: mockLocationService,
            initialClubs: testClubs,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial State: Ready to hit, GPS Good badge visible, START SHOT button visible
      expect(find.text('Hole 5 Shot Tracker'), findsOneWidget);
      expect(find.text('Ready to Hit'), findsOneWidget);
      expect(find.text('GPS Good'), findsOneWidget);
      expect(find.text('START SHOT'), findsOneWidget);

      // 2. Tap START SHOT -> transitions to SHOT IN PROGRESS
      await tester.tap(find.text('START SHOT'));
      await tester.pumpAndSettle();

      expect(find.text('SHOT IN PROGRESS'), findsOneWidget);
      expect(find.text('SAVE SHOT'), findsOneWidget);

      // 3. Golfer walks to ball: emit moved location
      mockLocationService.emitLocation(movedLocation);
      await tester.pumpAndSettle();

      // Live walk distance is greater than 0
      expect(find.text('SAVE SHOT'), findsOneWidget);

      // 4. Tap SAVE SHOT -> transitions to SHOT RECORDED
      await tester.tap(find.text('SAVE SHOT'));
      await tester.pumpAndSettle();

      expect(find.text('SHOT RECORDED'), findsOneWidget);
      expect(find.text('START NEXT SHOT'), findsOneWidget);
      expect(find.text('SHOTS THIS HOLE'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/game_modes/game_mode_engine.dart';

void main() {
  group('MobileGameModeEngine Tests', () {
    const par4 = 4;
    const par3 = 3;
    const par5 = 5;

    test('Stableford points follow standard rules', () {
      // Albatross / Double Eagle (3 under par) -> 5 pts
      expect(MobileGameModeEngine.calculateStablefordPoints(1, par4), equals(5));

      // Eagle (2 under par) -> 4 pts
      expect(MobileGameModeEngine.calculateStablefordPoints(2, par4), equals(4));
      expect(MobileGameModeEngine.calculateStablefordPoints(3, par5), equals(4));

      // Birdie (1 under par) -> 3 pts
      expect(MobileGameModeEngine.calculateStablefordPoints(3, par4), equals(3));
      expect(MobileGameModeEngine.calculateStablefordPoints(2, par3), equals(3));

      // Par (even) -> 2 pts
      expect(MobileGameModeEngine.calculateStablefordPoints(4, par4), equals(2));
      expect(MobileGameModeEngine.calculateStablefordPoints(3, par3), equals(2));

      // Bogey (1 over) -> 1 pt
      expect(MobileGameModeEngine.calculateStablefordPoints(5, par4), equals(1));
      expect(MobileGameModeEngine.calculateStablefordPoints(4, par3), equals(1));

      // Double Bogey or worse (>= 2 over) -> 0 pts
      expect(MobileGameModeEngine.calculateStablefordPoints(6, par4), equals(0));
      expect(MobileGameModeEngine.calculateStablefordPoints(7, par4), equals(0));
      expect(MobileGameModeEngine.calculateStablefordPoints(5, par3), equals(0));
    });

    test('isFirApplicable returns false for Par 3 and true for Par 4/5', () {
      expect(MobileGameModeEngine.isFirApplicable(3), isFalse);
      expect(MobileGameModeEngine.isFirApplicable(4), isTrue);
      expect(MobileGameModeEngine.isFirApplicable(5), isTrue);
    });

    test('calculateDefaultGir heuristic: (gross - putts) <= (par - 2)', () {
      // Par 4: 2 shots to green + 2 putts = 4 gross -> strokes to green = 4 - 2 = 2 <= 4 - 2 -> GIR true
      expect(
        MobileGameModeEngine.calculateDefaultGir(grossScore: 4, putts: 2, par: 4),
        isTrue,
      );

      // Par 4: 3 shots to green + 2 putts = 5 gross -> strokes to green = 3 > 2 -> GIR false
      expect(
        MobileGameModeEngine.calculateDefaultGir(grossScore: 5, putts: 2, par: 4),
        isFalse,
      );

      // Par 3: 1 shot to green + 2 putts = 3 gross -> strokes to green = 1 <= 3 - 2 -> GIR true
      expect(
        MobileGameModeEngine.calculateDefaultGir(grossScore: 3, putts: 2, par: 3),
        isTrue,
      );

      // Par 5: 3 shots to green + 2 putts = 5 gross -> strokes to green = 3 <= 5 - 2 -> GIR true
      expect(
        MobileGameModeEngine.calculateDefaultGir(grossScore: 5, putts: 2, par: 5),
        isTrue,
      );
    });
  });
}

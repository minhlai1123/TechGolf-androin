import 'distance_engine.dart';

enum DistanceUnitType {
  yards,
  meters,
}

extension DistanceUnitTypeExtension on DistanceUnitType {
  String get label => this == DistanceUnitType.yards ? 'yd' : 'm';
  String get nameUpper => this == DistanceUnitType.yards ? 'YARDS' : 'METERS';

  static DistanceUnitType fromString(String? str) {
    if (str != null && str.toUpperCase() == 'METERS') {
      return DistanceUnitType.meters;
    }
    return DistanceUnitType.yards;
  }
}

/// Plays Like result details
class PlaysLikeCalculationResult {
  final double actualDistance;
  final double? startElevation;
  final double? targetElevation;
  final double? elevationDeltaMeters;
  final double? elevationDeltaUnit;
  final double adjustment;
  final double playsLikeDistance;
  final DistanceUnitType unit;
  final bool hasElevation;
  final String explanation;

  const PlaysLikeCalculationResult({
    required this.actualDistance,
    this.startElevation,
    this.targetElevation,
    this.elevationDeltaMeters,
    this.elevationDeltaUnit,
    required this.adjustment,
    required this.playsLikeDistance,
    required this.unit,
    required this.hasElevation,
    required this.explanation,
  });
}

/// Plays Like Distance Engine implementing golf physics slope adjustments
class PlaysLikeDistanceEngine {
  /// Standard golf slope empirical adjustment factor:
  /// 1 unit of elevation difference translates to approximately 1.0 unit of distance adjustment
  static const double defaultSlopeFactor = 1.0;

  /// Calculates Plays Like Distance given horizontal geodesic distance and elevation points.
  ///
  /// Formula:
  /// PlaysLikeDistance = ActualDistance + (elevationDeltaInUnit * slopeFactor)
  ///
  /// - Uphill (target > start): Ball lands early on rising ground, effectively playing longer.
  /// - Downhill (target < start): Ball remains airborne longer, effectively playing shorter.
  /// - Flat / No elevation: Plays Like equals actual distance.
  static PlaysLikeCalculationResult calculate({
    required double actualDistance,
    double? startElevationMeters,
    double? targetElevationMeters,
    DistanceUnitType unit = DistanceUnitType.yards,
    double slopeFactor = defaultSlopeFactor,
  }) {
    final validActual = actualDistance < 0 ? 0.0 : actualDistance;

    if (startElevationMeters == null || targetElevationMeters == null) {
      return PlaysLikeCalculationResult(
        actualDistance: double.parse(validActual.toStringAsFixed(1)),
        startElevation: null,
        targetElevation: null,
        elevationDeltaMeters: null,
        elevationDeltaUnit: null,
        adjustment: 0.0,
        playsLikeDistance: double.parse(validActual.toStringAsFixed(1)),
        unit: unit,
        hasElevation: false,
        explanation: 'Elevation data unavailable. Plays Like equals actual distance.',
      );
    }

    final double deltaMeters = targetElevationMeters - startElevationMeters;
    final double deltaUnit = unit == DistanceUnitType.yards
        ? DistanceEngine.metersToYards(deltaMeters)
        : deltaMeters;

    final double adjustment = deltaUnit * slopeFactor;
    final double playsLike = (validActual + adjustment).clamp(0.0, double.infinity);

    String slopeType = 'Flat';
    if (deltaMeters > 0.5) {
      slopeType = 'Uphill';
    } else if (deltaMeters < -0.5) {
      slopeType = 'Downhill';
    }

    final String unitStr = unit.label;
    final String sign = deltaMeters >= 0 ? '+' : '';
    final String adjSign = adjustment >= 0 ? '+' : '';

    return PlaysLikeCalculationResult(
      actualDistance: double.parse(validActual.toStringAsFixed(1)),
      startElevation: double.parse(startElevationMeters.toStringAsFixed(1)),
      targetElevation: double.parse(targetElevationMeters.toStringAsFixed(1)),
      elevationDeltaMeters: double.parse(deltaMeters.toStringAsFixed(1)),
      elevationDeltaUnit: double.parse(deltaUnit.toStringAsFixed(1)),
      adjustment: double.parse(adjustment.toStringAsFixed(1)),
      playsLikeDistance: double.parse(playsLike.toStringAsFixed(1)),
      unit: unit,
      hasElevation: true,
      explanation: '$slopeType: $sign${deltaMeters.toStringAsFixed(1)}m ($sign${deltaUnit.toStringAsFixed(1)} $unitStr), adjustment: $adjSign${adjustment.toStringAsFixed(1)} $unitStr',
    );
  }
}

import 'package:latlong2/latlong.dart';
import '../../../core/geo/distance_engine.dart';

/// Distance display unit
enum DistanceUnit {
  yards,
  meters,
}

extension DistanceUnitExtension on DistanceUnit {
  String get label => this == DistanceUnit.yards ? 'YD' : 'M';

  /// Format distance from meters to selected unit with null safety
  String format(double? meters) {
    if (meters == null) return '---';
    if (this == DistanceUnit.yards) {
      final yards = DistanceEngine.metersToYards(meters);
      return yards.round().toString();
    } else {
      return meters.round().toString();
    }
  }
}

/// Front / Middle / Back distance model
class FmbDistances {
  final double? frontMeters;
  final double? centerMeters;
  final double? backMeters;

  const FmbDistances({
    this.frontMeters,
    this.centerMeters,
    this.backMeters,
  });

  double? get frontYards => frontMeters != null ? DistanceEngine.metersToYards(frontMeters!) : null;
  double? get centerYards => centerMeters != null ? DistanceEngine.metersToYards(centerMeters!) : null;
  double? get backYards => backMeters != null ? DistanceEngine.metersToYards(backMeters!) : null;

  String formatFront(DistanceUnit unit) => unit.format(frontMeters);
  String formatCenter(DistanceUnit unit) => unit.format(centerMeters);
  String formatBack(DistanceUnit unit) => unit.format(backMeters);
}

/// Target / Layup drag point model
class TargetLayupPoint {
  final LatLng position;
  final double? distanceFromPlayerMeters;
  final double? distanceToGreenMeters;

  const TargetLayupPoint({
    required this.position,
    this.distanceFromPlayerMeters,
    this.distanceToGreenMeters,
  });

  String formatPlayerDistance(DistanceUnit unit) => unit.format(distanceFromPlayerMeters);
  String formatGreenDistance(DistanceUnit unit) => unit.format(distanceToGreenMeters);
}

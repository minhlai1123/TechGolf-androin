import 'package:flutter/material.dart';
import '../../../core/location/location_models.dart';
import '../../../core/theme/app_theme.dart';
import '../models/golf_map_models.dart';

/// Outdoor high-contrast Front/Middle/Back Distance Dashboard
class FmbDistanceDashboard extends StatelessWidget {
  final FmbDistances distances;
  final DistanceUnit unit;
  final LocationAccuracyStatus accuracyStatus;
  final double? accuracyMeters;
  final VoidCallback onToggleUnit;

  const FmbDistanceDashboard({
    super.key,
    required this.distances,
    required this.unit,
    required this.accuracyStatus,
    this.accuracyMeters,
    required this.onToggleUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GPS Status Row + Unit Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGpsStatusBadge(),
              InkWell(
                onTap: onToggleUnit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryGreen),
                  ),
                  child: Text(
                    unit.label,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // F / M / B Columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // FRONT
              _buildDistanceColumn(
                label: 'FRONT',
                value: distances.formatFront(unit),
                fontSize: 26,
                labelColor: Colors.white70,
              ),

              // CENTER / MIDDLE (HERO NUMBER)
              _buildDistanceColumn(
                label: 'CENTER',
                value: distances.formatCenter(unit),
                fontSize: 50,
                isHero: true,
                labelColor: AppTheme.primaryGreen,
              ),

              // BACK
              _buildDistanceColumn(
                label: 'BACK',
                value: distances.formatBack(unit),
                fontSize: 26,
                labelColor: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGpsStatusBadge() {
    Color dotColor;
    String text;

    switch (accuracyStatus) {
      case LocationAccuracyStatus.good:
        dotColor = const Color(0xFF00E676);
        text = accuracyMeters != null
            ? 'GPS OK (±${accuracyMeters!.round()}m)'
            : 'GPS OK';
        break;
      case LocationAccuracyStatus.poor:
        dotColor = const Color(0xFFFFB300);
        text = accuracyMeters != null
            ? 'GPS WEAK (±${accuracyMeters!.round()}m)'
            : 'GPS WEAK';
        break;
      case LocationAccuracyStatus.unavailable:
        dotColor = const Color(0xFFFF1744);
        text = 'SEARCHING GPS...';
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: dotColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceColumn({
    required String label,
    required String value,
    required double fontSize,
    bool isHero = false,
    required Color labelColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: isHero ? AppTheme.textHighContrast : Colors.white,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isHero ? 11 : 10,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

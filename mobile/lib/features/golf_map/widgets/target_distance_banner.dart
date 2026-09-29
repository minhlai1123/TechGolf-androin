import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/golf_map_models.dart';

/// Floating banner showing dual target layup distances (You -> Target, Target -> Green)
class TargetDistanceBanner extends StatelessWidget {
  final TargetLayupPoint target;
  final DistanceUnit unit;
  final VoidCallback onClose;

  const TargetDistanceBanner({
    super.key,
    required this.target,
    required this.unit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed, color: AppTheme.goldAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSegment(
                  title: 'TO TARGET',
                  distance: target.formatPlayerDistance(unit),
                  unit: unit.label,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white24,
                ),
                _buildSegment(
                  title: 'TO GREEN',
                  distance: target.formatGreenDistance(unit),
                  unit: unit.label,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
            tooltip: 'Dismiss Target',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String title,
    required String distance,
    required String unit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: distance,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

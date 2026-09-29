import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Floating map action buttons (recenter, fit hole, target layup, map layer toggle, distance arcs toggle)
class MapControlsOverlay extends StatelessWidget {
  final bool isTargetActive;
  final bool isSatellite;
  final bool areArcsVisible;
  final VoidCallback onToggleTarget;
  final VoidCallback onRecenterPlayer;
  final VoidCallback onFitHole;
  final VoidCallback onToggleMapLayer;
  final VoidCallback onToggleArcs;
  final VoidCallback? onOpenCaddie;
  final VoidCallback? onOpenShotTracker;

  const MapControlsOverlay({
    super.key,
    required this.isTargetActive,
    required this.isSatellite,
    required this.areArcsVisible,
    required this.onToggleTarget,
    required this.onRecenterPlayer,
    required this.onFitHole,
    required this.onToggleMapLayer,
    required this.onToggleArcs,
    this.onOpenCaddie,
    this.onOpenShotTracker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caddie Insights Button
        if (onOpenCaddie != null) ...[
          _buildFab(
            icon: Icons.psychology_outlined,
            label: 'Caddie',
            isActive: false,
            activeColor: AppTheme.accentGold,
            onTap: onOpenCaddie!,
          ),
          const SizedBox(height: 8),
        ],

        // Shot Tracker Button
        if (onOpenShotTracker != null) ...[
          _buildFab(
            icon: Icons.sports_golf,
            label: 'Shot',
            isActive: false,
            activeColor: AppTheme.primaryGreen,
            onTap: onOpenShotTracker!,
          ),
          const SizedBox(height: 8),
        ],

        // Target / Layup Drag Toggle
        _buildFab(
          icon: Icons.gps_fixed,
          label: 'Target',
          isActive: isTargetActive,
          activeColor: AppTheme.goldAccent,
          onTap: onToggleTarget,
        ),
        const SizedBox(height: 8),

        // Distance Arcs (150y/200y/250y) Toggle
        _buildFab(
          icon: Icons.all_inclusive,
          label: 'Arcs',
          isActive: areArcsVisible,
          activeColor: AppTheme.primaryGreen,
          onTap: onToggleArcs,
        ),
        const SizedBox(height: 8),

        // Satellite / Map Layer Toggle
        _buildFab(
          icon: isSatellite ? Icons.satellite_alt : Icons.map_outlined,
          label: isSatellite ? 'Sat' : 'Map',
          isActive: isSatellite,
          activeColor: Colors.lightBlueAccent,
          onTap: onToggleMapLayer,
        ),
        const SizedBox(height: 8),

        // Fit Hole
        _buildFab(
          icon: Icons.fullscreen_exit_rounded,
          label: 'Hole',
          isActive: false,
          activeColor: Colors.white,
          onTap: onFitHole,
        ),
        const SizedBox(height: 8),

        // Recenter on Player GPS
        _buildFab(
          icon: Icons.my_location_rounded,
          label: 'GPS',
          isActive: false,
          activeColor: Colors.white,
          onTap: onRecenterPlayer,
        ),
      ],
    );
  }

  Widget _buildFab({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.25)
                : AppTheme.darkSurface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : Colors.white24,
              width: isActive ? 1.8 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? activeColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

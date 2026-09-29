import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../courses/models/course_bundle_models.dart';

/// Bottom bar for Hole selection, Par, Handicap, and quick hole picker sheet
class HoleNavigationBar extends StatelessWidget {
  final HoleData currentHole;
  final List<HoleData> allHoles;
  final ValueChanged<int> onHoleSelected;

  const HoleNavigationBar({
    super.key,
    required this.currentHole,
    required this.allHoles,
    required this.onHoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final int currentIndex = allHoles.indexWhere((h) => h.holeNumber == currentHole.holeNumber);
    final bool hasPrev = currentIndex > 0;
    final bool hasNext = currentIndex >= 0 && currentIndex < allHoles.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Colors.white12)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev Hole Button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: hasPrev ? Colors.white : Colors.white24,
              onPressed: hasPrev
                  ? () => onHoleSelected(allHoles[currentIndex - 1].holeNumber)
                  : null,
              tooltip: 'Previous Hole',
            ),

            // Hole Details & Picker Trigger
            InkWell(
              onTap: () => _showHolePicker(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HOLE ${currentHole.holeNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGreen, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PAR ${currentHole.par}  •  SI ${currentHole.handicapIndex ?? "-"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next Hole Button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              color: hasNext ? Colors.white : Colors.white24,
              onPressed: hasNext
                  ? () => onHoleSelected(allHoles[currentIndex + 1].holeNumber)
                  : null,
              tooltip: 'Next Hole',
            ),
          ],
        ),
      ),
    );
  }

  void _showHolePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SELECT HOLE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: allHoles.length,
                  itemBuilder: (context, index) {
                    final hole = allHoles[index];
                    final bool isCurrent = hole.holeNumber == currentHole.holeNumber;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onHoleSelected(hole.holeNumber);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primaryGreen
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.primaryGreen
                                : Colors.white12,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${hole.holeNumber}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.black : Colors.white,
                              ),
                            ),
                            Text(
                              'P${hole.par}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isCurrent ? Colors.black87 : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

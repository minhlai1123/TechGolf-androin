import 'package:flutter/material.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_course_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../golf_map/screens/golf_map_screen.dart';
import '../models/course_bundle_models.dart';

/// Screen showing course details, tee box selection, and round start trigger
class CourseDetailScreen extends StatefulWidget {
  final CourseInfo courseInfo;
  final ApiClient apiClient;
  final OfflineCourseStorage storage;
  final LocationService locationService;

  const CourseDetailScreen({
    super.key,
    required this.courseInfo,
    required this.apiClient,
    required this.storage,
    required this.locationService,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseBundle? _bundle;
  CourseTee? _selectedTee;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Try loading from offline cache
    final cachedBundle = widget.storage.getBundle(widget.courseInfo.id);
    if (cachedBundle != null) {
      setState(() {
        _bundle = cachedBundle;
        if (cachedBundle.tees.isNotEmpty) {
          _selectedTee = cachedBundle.tees.first;
        }
        _isLoading = false;
      });
      return;
    }

    // 2. Fetch from backend if not cached
    try {
      final response = await widget.apiClient.getCourseBundle(widget.courseInfo.id);
      // Auto cache bundle
      await widget.storage.saveBundle(widget.courseInfo.id, response.rawJson);

      if (mounted) {
        setState(() {
          _bundle = response.bundle;
          if (response.bundle.tees.isNotEmpty) {
            _selectedTee = response.bundle.tees.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load course details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleOfflineBundle() async {
    final courseId = widget.courseInfo.id;
    final isSaved = widget.storage.isCourseSaved(courseId);

    if (isSaved) {
      await widget.storage.removeCourse(courseId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline course data removed.')),
        );
      }
    } else {
      setState(() {
        _isDownloading = true;
      });
      try {
        final response = await widget.apiClient.getCourseBundle(courseId);
        await widget.storage.saveBundle(courseId, response.rawJson);
        setState(() {
          _bundle = response.bundle;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course saved for offline play!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    }
  }

  void _startRound() {
    if (_bundle == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GolfMapScreen(
          bundle: _bundle!,
          selectedTee: _selectedTee,
          locationService: widget.locationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = widget.storage.isCourseSaved(widget.courseInfo.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseInfo.name.toUpperCase()),
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
              ),
            )
          else
            IconButton(
              icon: Icon(
                isSaved ? Icons.offline_pin : Icons.download_rounded,
                color: isSaved ? AppTheme.primaryGreen : Colors.white70,
              ),
              tooltip: isSaved ? 'Remove offline copy' : 'Save offline',
              onPressed: _toggleOfflineBundle,
            ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: _bundle != null ? _buildStartButton() : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourseData,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('RETRY', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    final bundle = _bundle!;
    final totalPar = bundle.holes.fold<int>(0, (sum, h) => sum + h.par);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.course.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  [bundle.course.city, bundle.course.state, bundle.course.country]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', '),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatPill('HOLES', '${bundle.holes.length}'),
                    const SizedBox(width: 12),
                    _buildStatPill('TOTAL PAR', '$totalPar'),
                    const SizedBox(width: 12),
                    _buildStatPill('VERIFIED', bundle.course.isVerified ? 'YES' : 'NO'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tees Selector Section
          if (bundle.tees.isNotEmpty) ...[
            const Text(
              'SELECT TEE BOX',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bundle.tees.map((tee) {
                final isSelected = _selectedTee?.id == tee.id;
                Color chipColor = Colors.grey;
                if (tee.teeColorHex != null && tee.teeColorHex!.isNotEmpty) {
                  try {
                    final hex = tee.teeColorHex!.replaceAll('#', '');
                    chipColor = Color(int.parse('FF$hex', radix: 16));
                  } catch (_) {}
                }

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chipColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tee.teeName),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
                  backgroundColor: AppTheme.darkSurface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white24,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTee = tee;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Holes Breakdown Overview
          const Text(
            'HOLES OVERVIEW',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bundle.holes.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final hole = bundle.holes[index];
              final teeData = _selectedTee != null
                  ? hole.tees.cast<HoleTee?>().firstWhere(
                        (t) => t?.teeId == _selectedTee!.id,
                        orElse: () => null,
                      )
                  : null;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Text(
                    '${hole.holeNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                title: Text('Par ${hole.par}  •  SI ${hole.handicapIndex ?? "-"}'),
                trailing: Text(
                  teeData?.distanceYards != null ? '${teeData!.distanceYards} YD' : '---',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startRound,
            icon: const Icon(Icons.navigation_rounded, color: Colors.black),
            label: const Text(
              'START GPS MAP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/offline_course_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../models/course_bundle_models.dart';
import '../../health/screens/health_dashboard_screen.dart';
import '../../health/services/health_service.dart';
import '../../statistics/screens/stats_dashboard_screen.dart';
import 'course_detail_screen.dart';

/// Screen listing available golf courses with offline download management
class CourseListScreen extends StatefulWidget {
  final ApiClient apiClient;
  final OfflineCourseStorage storage;
  final LocationService locationService;
  final IHealthService? healthService;

  const CourseListScreen({
    super.key,
    required this.apiClient,
    required this.storage,
    required this.locationService,
    this.healthService,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<CourseInfo> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _downloadingCourseIds = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await widget.apiClient.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Offline fallback: load from cached bundles
      final offlineIds = widget.storage.getOfflineCourseIds();
      final List<CourseInfo> cachedCourses = [];
      for (final id in offlineIds) {
        final bundle = widget.storage.getBundle(id);
        if (bundle != null) {
          cachedCourses.add(bundle.course);
        }
      }

      if (mounted) {
        setState(() {
          _courses = cachedCourses;
          _isLoading = false;
          if (cachedCourses.isEmpty) {
            _errorMessage = 'Could not connect to server and no offline courses are saved.';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offline mode: Showing cached courses'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _downloadCourse(CourseInfo course) async {
    setState(() {
      _downloadingCourseIds.add(course.id);
    });

    try {
      final response = await widget.apiClient.getCourseBundle(course.id);
      await widget.storage.saveBundle(course.id, response.rawJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.name} downloaded for offline play!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingCourseIds.remove(course.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOLF COURSES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppTheme.primaryRed),
            tooltip: 'Health Integration',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthDashboardScreen(
                    healthService: widget.healthService ?? HealthService(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white70),
            tooltip: 'Golf Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsDashboardScreen(
                    apiClient: widget.apiClient,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: 'Refresh courses',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.cloud_off, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCourses,
                icon: const Icon(Icons.refresh),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses found.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final isSaved = widget.storage.isCourseSaved(course.id);
        final isDownloading = _downloadingCourseIds.contains(course.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailScreen(
                    courseInfo: course,
                    apiClient: widget.apiClient,
                    storage: widget.storage,
                    locationService: widget.locationService,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (course.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.verified, color: AppTheme.primaryGreen, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [course.city, course.state, course.country].where((s) => s != null && s.isNotEmpty).join(', '),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${course.holesCount} HOLES',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (isSaved) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.offline_pin, color: AppTheme.primaryGreen, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'OFFLINE READY',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (isDownloading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryGreen,
                              ),
                            )
                          else if (!isSaved)
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: Colors.white70),
                              tooltip: 'Download for offline use',
                              onPressed: () => _downloadCourse(course),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

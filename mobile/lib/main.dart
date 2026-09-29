import 'package:flutter/material.dart';
import 'core/location/location_service.dart';
import 'core/network/api_client.dart';
import 'core/storage/offline_course_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/courses/screens/course_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await OfflineCourseStorage.init();
  final apiClient = ApiClient();
  final locationService = GeolocatorLocationService();

  runApp(TechGolfApp(
    storage: storage,
    apiClient: apiClient,
    locationService: locationService,
  ));
}

class TechGolfApp extends StatelessWidget {
  final OfflineCourseStorage storage;
  final ApiClient apiClient;
  final LocationService locationService;

  const TechGolfApp({
    super.key,
    required this.storage,
    required this.apiClient,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechGolf GPS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: CourseListScreen(
        storage: storage,
        apiClient: apiClient,
        locationService: locationService,
      ),
    );
  }
}

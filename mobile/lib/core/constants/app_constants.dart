/// Global App Constants for TechGolf Mobile
class AppConstants {
  static const String appName = 'TechGolf';
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1'; // Android Emulator default
  static const String localhostBaseUrl = 'http://localhost:3000/api/v1'; // Web / Desktop / iOS Sim

  // ESRI World Imagery Satellite Tile URL
  static const String esriSatelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  // OpenStreetMap Fallback Tile URL
  static const String osmFallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Geofencing default radii (meters)
  static const double greenExitRadiusMeters = 35.0;
  static const double nextTeeEntryRadiusMeters = 30.0;

  // Maximum allowed GPS accuracy (meters) for auto geofence triggers to prevent jitter
  static const double maxGeofenceAccuracyMeters = 15.0;

  // Layup distance arcs in yards
  static const double arc150Yd = 150.0;
  static const double arc200Yd = 200.0;
  static const double arc250Yd = 250.0;
}

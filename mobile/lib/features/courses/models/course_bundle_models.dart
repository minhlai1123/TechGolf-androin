import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Supported Golf Polygon Types matching Backend and PDF specifications
enum GolfPolygonType {
  fairway,
  rough,
  green,
  bunker,
  waterHazard,
  tee,
  unknown,
}

extension GolfPolygonTypeExtension on GolfPolygonType {
  static GolfPolygonType fromString(String? type) {
    if (type == null) return GolfPolygonType.unknown;
    switch (type.toUpperCase()) {
      case 'FAIRWAY':
        return GolfPolygonType.fairway;
      case 'ROUGH':
        return GolfPolygonType.rough;
      case 'GREEN':
        return GolfPolygonType.green;
      case 'BUNKER':
        return GolfPolygonType.bunker;
      case 'WATER_HAZARD':
        return GolfPolygonType.waterHazard;
      case 'TEE':
        return GolfPolygonType.tee;
      default:
        return GolfPolygonType.unknown;
    }
  }

  Color get fillColor {
    switch (this) {
      case GolfPolygonType.green:
        return const Color(0xFF2E7D32).withValues(alpha: 0.65);
      case GolfPolygonType.fairway:
        return const Color(0xFF4CAF50).withValues(alpha: 0.50);
      case GolfPolygonType.tee:
        return const Color(0xFF81C784).withValues(alpha: 0.60);
      case GolfPolygonType.bunker:
        return const Color(0xFFFDD835).withValues(alpha: 0.70);
      case GolfPolygonType.waterHazard:
        return const Color(0xFF0288D1).withValues(alpha: 0.65);
      case GolfPolygonType.rough:
        return const Color(0xFF1B5E20).withValues(alpha: 0.35);
      case GolfPolygonType.unknown:
        return Colors.grey.withValues(alpha: 0.30);
    }
  }

  Color get strokeColor {
    switch (this) {
      case GolfPolygonType.green:
        return const Color(0xFF1B5E20);
      case GolfPolygonType.fairway:
        return const Color(0xFF388E3C);
      case GolfPolygonType.tee:
        return const Color(0xFF4CAF50);
      case GolfPolygonType.bunker:
        return const Color(0xFFFBC02D);
      case GolfPolygonType.waterHazard:
        return const Color(0xFF01579B);
      case GolfPolygonType.rough:
        return const Color(0xFF1B5E20);
      case GolfPolygonType.unknown:
        return Colors.grey;
    }
  }
}

/// Course Information
class CourseInfo {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final int holesCount;
  final bool isVerified;

  const CourseInfo({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    required this.holesCount,
    this.isVerified = false,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      holesCount: json['holesCount'] as int? ?? 18,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'holesCount': holesCount,
        'isVerified': isVerified,
      };
}

/// Course Tee
class CourseTee {
  final String id;
  final String courseId;
  final String teeName;
  final String? teeColorHex;
  final double? courseRating;
  final int? slopeRating;

  const CourseTee({
    required this.id,
    required this.courseId,
    required this.teeName,
    this.teeColorHex,
    this.courseRating,
    this.slopeRating,
  });

  factory CourseTee.fromJson(Map<String, dynamic> json) {
    return CourseTee(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      teeName: json['teeName'] as String,
      teeColorHex: json['teeColorHex'] as String?,
      courseRating: json['courseRating'] != null ? (json['courseRating'] as num).toDouble() : null,
      slopeRating: json['slopeRating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'teeName': teeName,
        'teeColorHex': teeColorHex,
        'courseRating': courseRating,
        'slopeRating': slopeRating,
      };
}

/// Hole Tee
class HoleTee {
  final String id;
  final String holeId;
  final String teeId;
  final int? distanceYards;
  final int? distanceMeters;
  final double? teeMarkerLat;
  final double? teeMarkerLng;

  const HoleTee({
    required this.id,
    required this.holeId,
    required this.teeId,
    this.distanceYards,
    this.distanceMeters,
    this.teeMarkerLat,
    this.teeMarkerLng,
  });

  LatLng? get markerPoint {
    if (teeMarkerLat != null && teeMarkerLng != null) {
      return LatLng(teeMarkerLat!, teeMarkerLng!);
    }
    return null;
  }

  factory HoleTee.fromJson(Map<String, dynamic> json) {
    return HoleTee(
      id: json['id'] as String,
      holeId: json['holeId'] as String,
      teeId: json['teeId'] as String,
      distanceYards: json['distanceYards'] as int?,
      distanceMeters: json['distanceMeters'] as int?,
      teeMarkerLat: json['teeMarkerLat'] != null ? (json['teeMarkerLat'] as num).toDouble() : null,
      teeMarkerLng: json['teeMarkerLng'] != null ? (json['teeMarkerLng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'holeId': holeId,
        'teeId': teeId,
        'distanceYards': distanceYards,
        'distanceMeters': distanceMeters,
        'teeMarkerLat': teeMarkerLat,
        'teeMarkerLng': teeMarkerLng,
      };
}

/// Vector Polygon parsed from GeoJSON Feature
class GolfPolygonFeature {
  final String? id;
  final GolfPolygonType type;
  final List<LatLng> coordinates;

  const GolfPolygonFeature({
    this.id,
    required this.type,
    required this.coordinates,
  });
}

/// Hole Data with Green F/M/B, Tees, and Polygons
class HoleData {
  final String id;
  final String courseId;
  final int holeNumber;
  final int par;
  final int? handicapIndex;
  final double? greenCenterLat;
  final double? greenCenterLng;
  final double? greenFrontLat;
  final double? greenFrontLng;
  final double? greenBackLat;
  final double? greenBackLng;
  final List<HoleTee> tees;
  final List<GolfPolygonFeature> polygons;

  const HoleData({
    required this.id,
    required this.courseId,
    required this.holeNumber,
    required this.par,
    this.handicapIndex,
    this.greenCenterLat,
    this.greenCenterLng,
    this.greenFrontLat,
    this.greenFrontLng,
    this.greenBackLat,
    this.greenBackLng,
    this.tees = const [],
    this.polygons = const [],
  });

  LatLng? get greenCenter {
    if (greenCenterLat != null && greenCenterLng != null) {
      return LatLng(greenCenterLat!, greenCenterLng!);
    }
    return null;
  }

  LatLng? get greenFront {
    if (greenFrontLat != null && greenFrontLng != null) {
      return LatLng(greenFrontLat!, greenFrontLng!);
    }
    return null;
  }

  LatLng? get greenBack {
    if (greenBackLat != null && greenBackLng != null) {
      return LatLng(greenBackLat!, greenBackLng!);
    }
    return null;
  }

  factory HoleData.fromJson(Map<String, dynamic> json) {
    // Parse tees
    final List<HoleTee> teesList = [];
    if (json['tees'] is List) {
      for (final item in json['tees']) {
        if (item is Map<String, dynamic>) {
          teesList.add(HoleTee.fromJson(item));
        }
      }
    }

    // Parse polygons from GeoJSON FeatureCollection in `map`
    final List<GolfPolygonFeature> polygonList = [];
    if (json['map'] is Map<String, dynamic>) {
      final mapData = json['map'] as Map<String, dynamic>;
      if (mapData['features'] is List) {
        for (final feature in mapData['features']) {
          if (feature is Map<String, dynamic>) {
            final properties = feature['properties'] as Map<String, dynamic>? ?? {};
            final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
            final geomType = geometry['type'] as String?;

            if (geomType == 'Polygon') {
              final polyType = GolfPolygonTypeExtension.fromString(
                properties['polygonType'] as String?,
              );
              final rawCoordinates = geometry['coordinates'];
              if (rawCoordinates is List && rawCoordinates.isNotEmpty) {
                final ring = rawCoordinates[0] as List;
                final List<LatLng> latLngs = [];
                for (final coord in ring) {
                  if (coord is List && coord.length >= 2) {
                    final lng = (coord[0] as num).toDouble();
                    final lat = (coord[1] as num).toDouble();
                    latLngs.add(LatLng(lat, lng));
                  }
                }
                if (latLngs.isNotEmpty) {
                  polygonList.add(
                    GolfPolygonFeature(
                      id: properties['id'] as String?,
                      type: polyType,
                      coordinates: latLngs,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    return HoleData(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      holeNumber: json['holeNumber'] as int,
      par: json['par'] as int,
      handicapIndex: json['handicapIndex'] as int?,
      greenCenterLat: json['greenCenterLat'] != null ? (json['greenCenterLat'] as num).toDouble() : null,
      greenCenterLng: json['greenCenterLng'] != null ? (json['greenCenterLng'] as num).toDouble() : null,
      greenFrontLat: json['greenFrontLat'] != null ? (json['greenFrontLat'] as num).toDouble() : null,
      greenFrontLng: json['greenFrontLng'] != null ? (json['greenFrontLng'] as num).toDouble() : null,
      greenBackLat: json['greenBackLat'] != null ? (json['greenBackLat'] as num).toDouble() : null,
      greenBackLng: json['greenBackLng'] != null ? (json['greenBackLng'] as num).toDouble() : null,
      tees: teesList,
      polygons: polygonList,
    );
  }
}

/// Full Course Offline Data Bundle
class CourseBundle {
  final CourseInfo course;
  final List<CourseTee> tees;
  final List<HoleData> holes;
  final DateTime downloadedAt;

  const CourseBundle({
    required this.course,
    required this.tees,
    required this.holes,
    required this.downloadedAt,
  });

  factory CourseBundle.fromJson(Map<String, dynamic> json) {
    final course = CourseInfo.fromJson(json['course'] as Map<String, dynamic>);

    final List<CourseTee> tees = [];
    if (json['tees'] is List) {
      for (final item in json['tees']) {
        if (item is Map<String, dynamic>) {
          tees.add(CourseTee.fromJson(item));
        }
      }
    }

    final List<HoleData> holes = [];
    if (json['holes'] is List) {
      for (final item in json['holes']) {
        if (item is Map<String, dynamic>) {
          holes.add(HoleData.fromJson(item));
        }
      }
    }
    // Sort holes by holeNumber
    holes.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));

    DateTime downloadedAt = DateTime.now();
    if (json['downloadedAt'] != null) {
      try {
        downloadedAt = DateTime.parse(json['downloadedAt'] as String);
      } catch (_) {}
    }

    return CourseBundle(
      course: course,
      tees: tees,
      holes: holes,
      downloadedAt: downloadedAt,
    );
  }
}

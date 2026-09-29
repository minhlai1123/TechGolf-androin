import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/courses/models/course_bundle_models.dart';

void main() {
  group('GeoJSON Parser & CourseBundle Models Tests', () {
    test('Parses HoleData with GeoJSON polygons and pins correctly', () {
      final json = {
        'id': 'hole-uuid-1',
        'courseId': 'course-uuid-1',
        'holeNumber': 1,
        'par': 4,
        'handicapIndex': 5,
        'greenCenterLat': 39.78920,
        'greenCenterLng': -74.97540,
        'greenFrontLat': 39.78910,
        'greenFrontLng': -74.97500,
        'greenBackLat': 39.78930,
        'greenBackLng': -74.97580,
        'tees': [
          {
            'id': 'ht-1',
            'holeId': 'hole-uuid-1',
            'teeId': 'tee-black',
            'distanceYards': 420,
            'distanceMeters': 384,
            'teeMarkerLat': 39.79008,
            'teeMarkerLng': -74.97210,
          },
        ],
        'map': {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {
                'id': 'poly-green-1',
                'polygonType': 'GREEN',
              },
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-74.9755, 39.7891],
                    [-74.9753, 39.7891],
                    [-74.9753, 39.7893],
                    [-74.9755, 39.7893],
                    [-74.9755, 39.7891],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {
                'id': 'poly-bunker-1',
                'polygonType': 'BUNKER',
              },
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-74.9750, 39.7890],
                    [-74.9748, 39.7890],
                    [-74.9748, 39.7892],
                    [-74.9750, 39.7890],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {
                'id': 'poly-water-1',
                'polygonType': 'WATER_HAZARD',
              },
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-74.9740, 39.7895],
                    [-74.9738, 39.7895],
                    [-74.9740, 39.7895],
                  ],
                ],
              },
            },
          ],
        },
      };

      final hole = HoleData.fromJson(json);

      expect(hole.id, equals('hole-uuid-1'));
      expect(hole.holeNumber, equals(1));
      expect(hole.par, equals(4));
      expect(hole.handicapIndex, equals(5));

      // Check Green Pins
      expect(hole.greenCenter?.latitude, equals(39.78920));
      expect(hole.greenCenter?.longitude, equals(-74.97540));
      expect(hole.greenFront?.latitude, equals(39.78910));
      expect(hole.greenBack?.latitude, equals(39.78930));

      // Check Tees
      expect(hole.tees.length, equals(1));
      expect(hole.tees.first.distanceYards, equals(420));
      expect(hole.tees.first.markerPoint?.latitude, equals(39.79008));

      // Check Polygons
      expect(hole.polygons.length, equals(3));
      expect(hole.polygons[0].type, equals(GolfPolygonType.green));
      expect(hole.polygons[0].coordinates.length, equals(5));
      expect(hole.polygons[1].type, equals(GolfPolygonType.bunker));
      expect(hole.polygons[2].type, equals(GolfPolygonType.waterHazard));
    });

    test('Parses full CourseBundle accurately', () {
      final bundleJson = {
        'course': {
          'id': 'course-1',
          'name': 'Pine Valley Championship',
          'city': 'Pine Valley',
          'state': 'NJ',
          'country': 'USA',
          'latitude': 39.789,
          'longitude': -74.975,
          'holesCount': 18,
          'isVerified': true,
        },
        'tees': [
          {
            'id': 'tee-1',
            'courseId': 'course-1',
            'teeName': 'Championship',
            'teeColorHex': '#000000',
            'courseRating': 75.2,
            'slopeRating': 148,
          },
        ],
        'holes': [
          {
            'id': 'hole-1',
            'courseId': 'course-1',
            'holeNumber': 1,
            'par': 4,
            'tees': [],
            'map': {'type': 'FeatureCollection', 'features': []},
          },
          {
            'id': 'hole-2',
            'courseId': 'course-1',
            'holeNumber': 2,
            'par': 4,
            'tees': [],
            'map': {'type': 'FeatureCollection', 'features': []},
          },
        ],
        'downloadedAt': '2026-09-29T12:00:00.000Z',
      };

      final bundle = CourseBundle.fromJson(bundleJson);

      expect(bundle.course.name, equals('Pine Valley Championship'));
      expect(bundle.course.isVerified, isTrue);
      expect(bundle.tees.length, equals(1));
      expect(bundle.tees.first.teeName, equals('Championship'));
      expect(bundle.holes.length, equals(2));
      expect(bundle.holes.first.holeNumber, equals(1));
      expect(bundle.holes.last.holeNumber, equals(2));
    });
  });
}

import { BadRequestException } from '@nestjs/common';
import { GeoJsonHelper } from '../src/common/gis/geojson.helper';

describe('GeoJsonHelper Spatial Tests', () => {
  it('should convert point [lng, lat] to PostGIS WKT', () => {
    const wkt = GeoJsonHelper.pointToWkt(105.8542, 21.0285);
    expect(wkt).toBe('SRID=4326;POINT(105.8542 21.0285)');
  });

  it('should parse WKT point back to GeoJSON Point', () => {
    const geoJson = GeoJsonHelper.toGeoJsonPoint('SRID=4326;POINT(105.8542 21.0285)');
    expect(geoJson).toEqual({
      type: 'Point',
      coordinates: [105.8542, 21.0285],
    });
  });

  it('should convert closed Polygon rings to PostGIS WKT', () => {
    const coords: number[][][] = [
      [
        [105.85, 21.02],
        [105.86, 21.02],
        [105.86, 21.03],
        [105.85, 21.03],
        [105.85, 21.02],
      ],
    ];
    const wkt = GeoJsonHelper.polygonToWkt(coords);
    expect(wkt).toContain('SRID=4326;POLYGON((105.85 21.02, 105.86 21.02, 105.86 21.03, 105.85 21.03, 105.85 21.02))');
  });

  it('should reject unclosed polygon rings', () => {
    const unclosedCoords: number[][][] = [
      [
        [105.85, 21.02],
        [105.86, 21.02],
        [105.86, 21.03],
        [105.85, 21.03],
      ],
    ];
    expect(() => GeoJsonHelper.polygonToWkt(unclosedCoords)).toThrow(BadRequestException);
  });
});

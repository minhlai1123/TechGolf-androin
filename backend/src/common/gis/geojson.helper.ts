import { BadRequestException } from '@nestjs/common';

export interface GeoJsonPoint {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
}

export interface GeoJsonPolygon {
  type: 'Polygon';
  coordinates: number[][][]; // array of linear rings [[ [lng, lat], ... ]]
}

export interface GeoJsonFeature {
  type: 'Feature';
  id?: string;
  geometry: GeoJsonPoint | GeoJsonPolygon | null;
  properties: Record<string, any>;
}

export interface GeoJsonFeatureCollection {
  type: 'FeatureCollection';
  features: GeoJsonFeature[];
}

export class GeoJsonHelper {
  /**
   * Validate GeoJSON Polygon coordinates:
   * - Must have at least 1 linear ring.
   * - Linear ring must have at least 4 points.
   * - First and last points must be identical (closed ring).
   * - Longitude between -180 and 180, Latitude between -90 and 90.
   */
  static validatePolygonCoordinates(coordinates: number[][][]): void {
    if (!Array.isArray(coordinates) || coordinates.length === 0) {
      throw new BadRequestException('Polygon coordinates must be a non-empty array of linear rings');
    }

    const exteriorRing = coordinates[0];
    if (!Array.isArray(exteriorRing) || exteriorRing.length < 4) {
      throw new BadRequestException(
        'Polygon exterior ring must contain at least 4 coordinate positions (first and last must close)',
      );
    }

    for (const ring of coordinates) {
      if (!Array.isArray(ring) || ring.length < 4) {
        throw new BadRequestException('Each linear ring must contain at least 4 coordinate points');
      }

      for (const pt of ring) {
        if (!Array.isArray(pt) || pt.length < 2 || typeof pt[0] !== 'number' || typeof pt[1] !== 'number') {
          throw new BadRequestException('Each coordinate must be [longitude, latitude] numbers');
        }
        const [lng, lat] = pt;
        if (lng < -180 || lng > 180) {
          throw new BadRequestException(`Longitude out of bounds [-180, 180]: ${lng}`);
        }
        if (lat < -90 || lat > 90) {
          throw new BadRequestException(`Latitude out of bounds [-90, 90]: ${lat}`);
        }
      }

      // Check if ring is closed
      const first = ring[0];
      const last = ring[ring.length - 1];
      if (first[0] !== last[0] || first[1] !== last[1]) {
        throw new BadRequestException('Linear ring is not closed: first and last positions must be identical');
      }
    }
  }

  /**
   * Validates a point [lng, lat]
   */
  static validatePointCoordinates(coordinates: [number, number]): void {
    if (!Array.isArray(coordinates) || coordinates.length < 2) {
      throw new BadRequestException('Point coordinates must be [longitude, latitude]');
    }
    const [lng, lat] = coordinates;
    if (typeof lng !== 'number' || typeof lat !== 'number') {
      throw new BadRequestException('Coordinates must be numeric');
    }
    if (lng < -180 || lng > 180) {
      throw new BadRequestException(`Longitude out of bounds [-180, 180]: ${lng}`);
    }
    if (lat < -90 || lat > 90) {
      throw new BadRequestException(`Latitude out of bounds [-90, 90]: ${lat}`);
    }
  }

  /**
   * Convert longitude and latitude to PostGIS WKT Point string
   */
  static pointToWkt(lng: number, lat: number): string {
    return `SRID=4326;POINT(${lng} ${lat})`;
  }

  /**
   * Convert GeoJSON Polygon coordinates to PostGIS WKT Polygon string
   */
  static polygonToWkt(coordinates: number[][][]): string {
    this.validatePolygonCoordinates(coordinates);
    const ringsWkt = coordinates
      .map((ring) => `(${ring.map(([lng, lat]) => `${lng} ${lat}`).join(', ')})`)
      .join(', ');
    return `SRID=4326;POLYGON(${ringsWkt})`;
  }

  /**
   * Parse WKT Point or raw object to GeoJSON Point
   */
  static toGeoJsonPoint(geom: any): GeoJsonPoint | null {
    if (!geom) return null;
    if (typeof geom === 'object' && geom.type === 'Point' && Array.isArray(geom.coordinates)) {
      return { type: 'Point', coordinates: [geom.coordinates[0], geom.coordinates[1]] };
    }
    if (typeof geom === 'string') {
      // WKT format: "POINT(105.85 21.02)" or "SRID=4326;POINT(105.85 21.02)"
      const match = geom.match(/POINT\s*\(\s*([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s*\)/i);
      if (match) {
        return {
          type: 'Point',
          coordinates: [parseFloat(match[1]), parseFloat(match[2])],
        };
      }
    }
    return null;
  }

  /**
   * Parse WKT Polygon or raw object to GeoJSON Polygon
   */
  static toGeoJsonPolygon(geom: any): GeoJsonPolygon | null {
    if (!geom) return null;
    if (typeof geom === 'object' && geom.type === 'Polygon' && Array.isArray(geom.coordinates)) {
      return { type: 'Polygon', coordinates: geom.coordinates };
    }
    if (typeof geom === 'string') {
      // Parse WKT POLYGON((lng lat, lng lat, ...))
      const ringsMatch = geom.match(/POLYGON\s*\(\s*\((.+)\)\s*\)/i);
      if (ringsMatch) {
        const ringStr = ringsMatch[1];
        const points = ringStr.split(',').map((p) => {
          const parts = p.trim().split(/\s+/);
          return [parseFloat(parts[0]), parseFloat(parts[1])];
        });
        return {
          type: 'Polygon',
          coordinates: [points],
        };
      }
    }
    return null;
  }
}

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { HolePolygonsService } from '../src/courses/hole-polygons.service';
import { HolePolygonsController } from '../src/courses/hole-polygons.controller';
import { HolePolygon, PolygonType } from '../src/courses/entities/hole-polygon.entity';
import { Hole } from '../src/courses/entities/hole.entity';

describe('HolePolygonsModule Tests', () => {
  let controller: HolePolygonsController;

  const holeId = 'hole-uuid-1111';
  const polyId = 'poly-uuid-2222';

  const validCoords: number[][][] = [
    [
      [-74.972, 39.7905],
      [-74.970, 39.7915],
      [-74.969, 39.7922],
      [-74.971, 39.7912],
      [-74.972, 39.7905],
    ],
  ];

  const mockPolygon: Partial<HolePolygon> = {
    id: polyId,
    hole_id: holeId,
    polygon_type: PolygonType.FAIRWAY,
    geometry: 'SRID=4326;POLYGON((-74.972 39.7905, -74.970 39.7915, -74.969 39.7922, -74.971 39.7912, -74.972 39.7905))',
    metadata: { note: 'Landing zone' },
  };

  const mockPolyRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  const mockHoleRepo = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HolePolygonsController],
      providers: [
        HolePolygonsService,
        {
          provide: getRepositoryToken(HolePolygon),
          useValue: mockPolyRepo,
        },
        {
          provide: getRepositoryToken(Hole),
          useValue: mockHoleRepo,
        },
      ],
    }).compile();

    controller = module.get<HolePolygonsController>(HolePolygonsController);
  });

  describe('create polygon', () => {
    it('should create polygon and store PostGIS WKT', async () => {
      mockHoleRepo.findOne.mockResolvedValue({ id: holeId });
      mockPolyRepo.create.mockReturnValue({ ...mockPolygon });
      mockPolyRepo.save.mockResolvedValue({ ...mockPolygon });

      const result = await controller.create(holeId, {
        polygon_type: PolygonType.FAIRWAY,
        coordinates: validCoords,
      });

      expect(result.polygon_type).toBe(PolygonType.FAIRWAY);
      expect(mockPolyRepo.save).toHaveBeenCalled();
    });

    it('should throw BadRequestException if polygon ring has less than 4 points', async () => {
      mockHoleRepo.findOne.mockResolvedValue({ id: holeId });

      const invalidCoords = [
        [
          [-74.972, 39.7905],
          [-74.970, 39.7915],
          [-74.972, 39.7905],
        ],
      ];

      await expect(
        controller.create(holeId, {
          polygon_type: PolygonType.BUNKER,
          coordinates: invalidCoords,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if linear ring is not closed', async () => {
      mockHoleRepo.findOne.mockResolvedValue({ id: holeId });

      const openRing = [
        [
          [-74.972, 39.7905],
          [-74.970, 39.7915],
          [-74.969, 39.7922],
          [-74.971, 39.7912],
        ],
      ];

      await expect(
        controller.create(holeId, {
          polygon_type: PolygonType.GREEN,
          coordinates: openRing,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('remove polygon', () => {
    it('should remove polygon', async () => {
      mockPolyRepo.findOne.mockResolvedValue(mockPolygon);
      mockPolyRepo.remove.mockResolvedValue(mockPolygon);

      const result = await controller.remove(polyId);
      expect(result.success).toBe(true);
      expect(mockPolyRepo.remove).toHaveBeenCalled();
    });
  });
});

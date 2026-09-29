import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, ConflictException } from '@nestjs/common';
import { HolesService } from '../src/courses/holes.service';
import { HolesController } from '../src/courses/holes.controller';
import { Hole } from '../src/courses/entities/hole.entity';
import { Course } from '../src/courses/entities/course.entity';
import { PolygonType } from '../src/courses/entities/hole-polygon.entity';

describe('HolesModule Tests', () => {
  let controller: HolesController;

  const courseId = 'course-uuid-1111';
  const holeId = 'hole-uuid-2222';

  const mockCourse: Partial<Course> = {
    id: courseId,
    name: 'Sample Course',
  };

  const mockHole: Partial<Hole> = {
    id: holeId,
    course_id: courseId,
    hole_number: 1,
    par: 4,
    handicap_index: 7,
    green_center: 'SRID=4326;POINT(-74.9688 39.7925)',
    green_front: 'SRID=4326;POINT(-74.9691 39.7923)',
    green_back: 'SRID=4326;POINT(-74.9685 39.7927)',
    tees: [
      {
        id: 'ht-1',
        hole_id: holeId,
        course_tee_id: 'ct-1',
        tee_position: 'SRID=4326;POINT(-74.9721 39.7902)',
        distance_meters: 380,
        courseTee: {
          id: 'ct-1',
          name: 'Blue',
          color: '#2563EB',
        } as any,
      } as any,
    ],
    polygons: [
      {
        id: 'poly-1',
        hole_id: holeId,
        polygon_type: PolygonType.FAIRWAY,
        geometry: 'SRID=4326;POLYGON((-74.972 39.7905, -74.970 39.7915, -74.969 39.7922, -74.971 39.7912, -74.972 39.7905))',
        metadata: {},
      } as any,
    ],
  };

  const mockHoleRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  const mockCourseRepo = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HolesController],
      providers: [
        HolesService,
        {
          provide: getRepositoryToken(Hole),
          useValue: mockHoleRepo,
        },
        {
          provide: getRepositoryToken(Course),
          useValue: mockCourseRepo,
        },
      ],
    }).compile();

    controller = module.get<HolesController>(HolesController);
  });

  describe('findByCourse', () => {
    it('should return list of holes for course', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);
      mockHoleRepo.find.mockResolvedValue([mockHole]);

      const result = await controller.findByCourse(courseId);
      expect(result).toEqual([mockHole]);
    });

    it('should throw NotFoundException if course does not exist', async () => {
      mockCourseRepo.findOne.mockResolvedValue(null);

      await expect(controller.findByCourse('unknown-course')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('should create hole when course exists and hole number is unique', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);
      mockHoleRepo.findOne.mockResolvedValue(null);
      mockHoleRepo.create.mockReturnValue({ ...mockHole });
      mockHoleRepo.save.mockResolvedValue({ ...mockHole });

      const result = await controller.create(courseId, {
        hole_number: 1,
        par: 4,
        handicap_index: 7,
        green_center: [-74.9688, 39.7925],
      });

      expect(result.hole_number).toBe(1);
      expect(mockHoleRepo.save).toHaveBeenCalled();
    });

    it('should throw ConflictException on duplicate hole number for course', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);
      mockHoleRepo.findOne.mockResolvedValue(mockHole);

      await expect(
        controller.create(courseId, {
          hole_number: 1,
          par: 4,
          handicap_index: 7,
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('getHoleMap (GeoJSON FeatureCollection)', () => {
    it('should return GeoJSON FeatureCollection containing green points, tee markers, and polygons', async () => {
      mockHoleRepo.findOne.mockResolvedValue(mockHole);

      const mapData = await controller.getHoleMap(holeId);

      expect(mapData.type).toBe('FeatureCollection');
      expect(Array.isArray(mapData.features)).toBe(true);

      // Verify Green Center feature
      const greenCenter = mapData.features.find(
        (f) => f.properties.element === 'GREEN_POINT' && f.properties.target === 'CENTER',
      );
      expect(greenCenter).toBeDefined();
      expect(greenCenter?.geometry?.type).toBe('Point');

      // Verify Tee Marker feature
      const teeMarker = mapData.features.find((f) => f.properties.element === 'TEE_MARKER');
      expect(teeMarker).toBeDefined();
      expect(teeMarker?.properties.tee_name).toBe('Blue');

      // Verify Fairway Polygon feature
      const fairway = mapData.features.find((f) => f.properties.type === PolygonType.FAIRWAY);
      expect(fairway).toBeDefined();
      expect(fairway?.geometry?.type).toBe('Polygon');
    });
  });
});

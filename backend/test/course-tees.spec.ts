import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { CourseTeesService } from '../src/courses/course-tees.service';
import { CourseTeesController } from '../src/courses/course-tees.controller';
import { CourseTee } from '../src/courses/entities/course-tee.entity';
import { HoleTee } from '../src/courses/entities/hole-tee.entity';
import { Course } from '../src/courses/entities/course.entity';
import { Hole } from '../src/courses/entities/hole.entity';

describe('CourseTeesModule Tests', () => {
  let controller: CourseTeesController;

  const courseId = 'course-uuid-1111';
  const teeId = 'tee-uuid-2222';
  const holeId = 'hole-uuid-3333';

  const mockCourseTee: Partial<CourseTee> = {
    id: teeId,
    course_id: courseId,
    name: 'Blue',
    color: '#2563EB',
    rating: 73.5,
    slope_rating: 135,
    total_yardage: 6850,
  };

  const mockHoleTee: Partial<HoleTee> = {
    id: 'ht-uuid-4444',
    hole_id: holeId,
    course_tee_id: teeId,
    tee_position: 'SRID=4326;POINT(-74.9721 39.7902)',
    distance_meters: 385,
  };

  const mockCourseTeeRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  const mockHoleTeeRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  const mockCourseRepo = {
    findOne: jest.fn(),
  };

  const mockHoleRepo = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CourseTeesController],
      providers: [
        CourseTeesService,
        {
          provide: getRepositoryToken(CourseTee),
          useValue: mockCourseTeeRepo,
        },
        {
          provide: getRepositoryToken(HoleTee),
          useValue: mockHoleTeeRepo,
        },
        {
          provide: getRepositoryToken(Course),
          useValue: mockCourseRepo,
        },
        {
          provide: getRepositoryToken(Hole),
          useValue: mockHoleRepo,
        },
      ],
    }).compile();

    controller = module.get<CourseTeesController>(CourseTeesController);
  });

  describe('createCourseTee', () => {
    it('should create course tee when course exists', async () => {
      mockCourseRepo.findOne.mockResolvedValue({ id: courseId });
      mockCourseTeeRepo.create.mockReturnValue({ ...mockCourseTee });
      mockCourseTeeRepo.save.mockResolvedValue({ ...mockCourseTee });

      const result = await controller.createCourseTee(courseId, {
        name: 'Blue',
        color: '#2563EB',
        rating: 73.5,
        slope_rating: 135,
        total_yardage: 6850,
      });

      expect(result.name).toBe('Blue');
      expect(result.slope_rating).toBe(135);
    });

    it('should throw NotFoundException if course does not exist', async () => {
      mockCourseRepo.findOne.mockResolvedValue(null);

      await expect(
        controller.createCourseTee('unknown-course', {
          name: 'Blue',
          color: '#2563EB',
          rating: 73.5,
          slope_rating: 135,
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('setHoleTee marker placement', () => {
    it('should place tee marker on hole with spatial point', async () => {
      mockHoleRepo.findOne.mockResolvedValue({ id: holeId });
      mockCourseTeeRepo.findOne.mockResolvedValue(mockCourseTee);
      mockHoleTeeRepo.findOne.mockResolvedValue(null);
      mockHoleTeeRepo.create.mockReturnValue({ ...mockHoleTee });
      mockHoleTeeRepo.save.mockResolvedValue({ ...mockHoleTee });

      const result = await controller.setHoleTee(holeId, {
        course_tee_id: teeId,
        tee_position: [-74.9721, 39.7902],
        distance_meters: 385,
      });

      expect(result.distance_meters).toBe(385);
      expect(mockHoleTeeRepo.save).toHaveBeenCalled();
    });
  });
});

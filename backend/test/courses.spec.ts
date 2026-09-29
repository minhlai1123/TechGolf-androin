import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { CoursesService } from '../src/courses/courses.service';
import { CoursesController } from '../src/courses/courses.controller';
import { Course, CourseStatus } from '../src/courses/entities/course.entity';

describe('CoursesModule Tests', () => {
  let controller: CoursesController;

  const courseId = 'course-uuid-1111';

  const mockCourse: Partial<Course> = {
    id: courseId,
    name: 'Augusta National Golf Club',
    address: '2604 Washington Rd',
    city: 'Augusta',
    country: 'United States',
    latitude: 33.5021,
    longitude: -82.0226,
    timezone: 'America/New_York',
    total_holes: 18,
    status: CourseStatus.ACTIVE,
    tees: [],
    holes: [],
    created_at: new Date(),
    updated_at: new Date(),
  };

  const mockRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CoursesController],
      providers: [
        CoursesService,
        {
          provide: getRepositoryToken(Course),
          useValue: mockRepository,
        },
      ],
    }).compile();

    controller = module.get<CoursesController>(CoursesController);
  });

  describe('findAll', () => {
    it('should return list of courses with optional search filter', async () => {
      mockRepository.find.mockResolvedValue([mockCourse]);

      const result = await controller.findAll('Augusta', 'Augusta');
      expect(result).toEqual([mockCourse]);
      expect(mockRepository.find).toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('should return course by ID', async () => {
      mockRepository.findOne.mockResolvedValue(mockCourse);

      const result = await controller.findOne(courseId);
      expect(result.id).toBe(courseId);
    });

    it('should throw NotFoundException if course not found', async () => {
      mockRepository.findOne.mockResolvedValue(null);

      await expect(controller.findOne('non-existent-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('should create and return new golf course with spatial point', async () => {
      mockRepository.create.mockReturnValue({ ...mockCourse });
      mockRepository.save.mockResolvedValue({ ...mockCourse });

      const result = await controller.create({
        name: 'Augusta National Golf Club',
        address: '2604 Washington Rd',
        city: 'Augusta',
        country: 'United States',
        latitude: 33.5021,
        longitude: -82.0226,
      });

      expect(result.name).toBe('Augusta National Golf Club');
      expect(mockRepository.create).toHaveBeenCalled();
      expect(mockRepository.save).toHaveBeenCalled();
    });
  });

  describe('update', () => {
    it('should update course details', async () => {
      const existing = { ...mockCourse };
      mockRepository.findOne.mockResolvedValue(existing);
      mockRepository.save.mockImplementation(async (c) => c);

      const result = await controller.update(courseId, {
        name: 'Augusta National Golf Club (Updated)',
        total_holes: 18,
      });

      expect(result.name).toBe('Augusta National Golf Club (Updated)');
    });
  });

  describe('remove', () => {
    it('should remove course', async () => {
      mockRepository.findOne.mockResolvedValue(mockCourse);
      mockRepository.remove.mockResolvedValue(mockCourse);

      const result = await controller.remove(courseId);
      expect(result.success).toBe(true);
      expect(mockRepository.remove).toHaveBeenCalled();
    });
  });
});

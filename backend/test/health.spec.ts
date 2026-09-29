import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { HealthService } from '../src/health/health.service';
import { HealthController } from '../src/health/health.controller';

describe('HealthModule Tests', () => {
  let healthService: HealthService;
  let healthController: HealthController;

  const mockDataSource = {
    isInitialized: true,
    query: jest.fn().mockResolvedValue([{ '?column?': 1 }]),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'redis.url') return 'redis://localhost:6379';
      return null;
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        HealthService,
        {
          provide: DataSource,
          useValue: mockDataSource,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    healthService = module.get<HealthService>(HealthService);
    healthController = module.get<HealthController>(HealthController);
  });

  it('should return backend status up', async () => {
    // Mock internal methods to simulate healthy checks
    jest
      .spyOn(healthService as any, 'checkDatabase')
      .mockResolvedValue({ status: 'up' });
    jest
      .spyOn(healthService as any, 'checkRedis')
      .mockResolvedValue({ status: 'up' });

    const result = await healthController.check();

    expect(result.status).toBe('ok');
    expect(result.services.backend.status).toBe('up');
    expect(result.services.database.status).toBe('up');
    expect(result.services.redis.status).toBe('up');
    expect(result).toHaveProperty('timestamp');
    expect(result).toHaveProperty('uptime');
  });

  it('should return degraded if database or redis is down', async () => {
    jest
      .spyOn(healthService as any, 'checkDatabase')
      .mockResolvedValue({ status: 'down', message: 'Connection refused' });
    jest
      .spyOn(healthService as any, 'checkRedis')
      .mockResolvedValue({ status: 'up' });

    const result = await healthService.checkHealth();

    expect(result.status).toBe('degraded');
    expect(result.services.backend.status).toBe('up');
    expect(result.services.database.status).toBe('down');
  });
});

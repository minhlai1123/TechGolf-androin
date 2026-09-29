import { Injectable, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export interface HealthCheckResult {
  status: 'ok' | 'degraded' | 'error';
  timestamp: string;
  uptime: number;
  services: {
    backend: { status: 'up' | 'down'; message?: string };
    database: { status: 'up' | 'down'; message?: string };
    redis: { status: 'up' | 'down'; message?: string };
  };
}

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly configService: ConfigService,
  ) {}

  async checkHealth(): Promise<HealthCheckResult> {
    const dbStatus = await this.checkDatabase();
    const redisStatus = await this.checkRedis();

    const isAllOk =
      dbStatus.status === 'up' && redisStatus.status === 'up';

    return {
      status: isAllOk ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      services: {
        backend: { status: 'up' },
        database: dbStatus,
        redis: redisStatus,
      },
    };
  }

  private async checkDatabase(): Promise<{ status: 'up' | 'down'; message?: string }> {
    try {
      if (this.dataSource.isInitialized) {
        await this.dataSource.query('SELECT 1');
        return { status: 'up' };
      }
      return { status: 'down', message: 'DataSource not initialized' };
    } catch (error) {
      this.logger.error(`Database health check failed: ${error.message}`);
      return { status: 'down', message: error.message };
    }
  }

  private async checkRedis(): Promise<{ status: 'up' | 'down'; message?: string }> {
    let client: Redis | null = null;
    try {
      const redisUrl = this.configService.get<string>('redis.url') || 'redis://localhost:6379';
      client = new Redis(redisUrl, {
        connectTimeout: 2000,
        maxRetriesPerRequest: 1,
        lazyConnect: true,
      });

      await client.connect();
      const pingRes = await client.ping();
      await client.quit();

      if (pingRes === 'PONG') {
        return { status: 'up' };
      }
      return { status: 'down', message: `Unexpected response: ${pingRes}` };
    } catch (error) {
      this.logger.warn(`Redis health check failed: ${error.message}`);
      return { status: 'down', message: error.message };
    } finally {
      if (client) {
        try {
          client.disconnect();
        } catch {
          // ignore cleanup errors
        }
      }
    }
  }
}

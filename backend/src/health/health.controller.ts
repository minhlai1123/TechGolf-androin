import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { HealthService } from './health.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  @ApiOperation({ summary: 'Check health status of backend, database, and redis' })
  @ApiResponse({ status: 200, description: 'Health check result' })
  async check() {
    return this.healthService.checkHealth();
  }
}

import {
  Controller,
  Get,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { StatisticsService } from './statistics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Golf Statistics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('stats')
export class StatisticsController {
  constructor(private readonly statsService: StatisticsService) {}

  @Get('overview')
  @ApiOperation({ summary: 'Get comprehensive golf statistics overview for current user' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Sample size of recent rounds (e.g. 5, 10, 20)' })
  @ApiResponse({ status: 200, description: 'Aggregated statistics overview' })
  async getOverview(
    @CurrentUser() user: UserPayload,
    @Query('limit') limit?: string,
  ) {
    const roundsLimit = limit ? parseInt(limit, 10) : undefined;
    return this.statsService.getOverview(user.userId, roundsLimit);
  }

  @Get('trends')
  @ApiOperation({ summary: 'Get chronological performance trends across rounds' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Number of recent rounds (e.g. 5, 10, 20)' })
  @ApiResponse({ status: 200, description: 'Chronological performance trend points' })
  async getTrends(
    @CurrentUser() user: UserPayload,
    @Query('limit') limit?: string,
  ) {
    const roundsLimit = limit ? parseInt(limit, 10) : undefined;
    return this.statsService.getTrends(user.userId, roundsLimit);
  }

  @Get('fir-gir')
  @ApiOperation({ summary: 'Get detailed Fairways and Greens in Regulation statistics' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getFirGir(
    @CurrentUser() user: UserPayload,
    @Query('limit') limit?: string,
  ) {
    const roundsLimit = limit ? parseInt(limit, 10) : undefined;
    return this.statsService.getFirGir(user.userId, roundsLimit);
  }

  @Get('putting')
  @ApiOperation({ summary: 'Get detailed putting performance analytics' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getPutting(
    @CurrentUser() user: UserPayload,
    @Query('limit') limit?: string,
  ) {
    const roundsLimit = limit ? parseInt(limit, 10) : undefined;
    return this.statsService.getPutting(user.userId, roundsLimit);
  }

  @Get('scrambling')
  @ApiOperation({ summary: 'Get detailed scrambling (up-and-down) performance analytics' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getScrambling(
    @CurrentUser() user: UserPayload,
    @Query('limit') limit?: string,
  ) {
    const roundsLimit = limit ? parseInt(limit, 10) : undefined;
    return this.statsService.getScrambling(user.userId, roundsLimit);
  }
}

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
import { StrokesGainedService } from './strokes-gained.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Strokes Gained Analytics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('stats/strokes-gained')
export class StrokesGainedController {
  constructor(private readonly sgService: StrokesGainedService) {}

  @Get()
  @ApiOperation({
    summary: 'Get Strokes Gained analysis for Driving, Approach, Short Game, and Putting',
    description:
      'Evaluates shot tracking against benchmark tables. If benchmark datasets are unavailable, explicitly reports UNAVAILABLE status.',
  })
  @ApiQuery({ name: 'roundId', required: false, type: String, description: 'Optional round UUID to scope calculation' })
  @ApiResponse({ status: 200, description: 'Strokes gained summary with category distribution' })
  async getStrokesGained(
    @CurrentUser() user: UserPayload,
    @Query('roundId') roundId?: string,
  ) {
    return this.sgService.getStrokesGained(user.userId, roundId);
  }
}

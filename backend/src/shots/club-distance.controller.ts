import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { ShotsService } from './shots.service';
import { RecommendClubDto } from './dto/recommend-club.dto';
import { DistanceUnit } from './entities/shot.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Virtual Golf Bag Club Distances & Caddie')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('bag/clubs')
export class ClubDistanceController {
  constructor(private readonly shotsService: ShotsService) {}

  @Get('distances')
  @ApiOperation({ summary: 'Get calculated average distances for all clubs in user bag' })
  @ApiResponse({ status: 200, description: 'List of clubs with yard and meter averages' })
  async getClubDistances(@CurrentUser() user: UserPayload) {
    return this.shotsService.getClubDistances(user.userId);
  }

  @Get(':clubId/shots')
  @ApiOperation({ summary: 'Get saved shot history for a specific club' })
  @ApiParam({ name: 'clubId', description: 'Club UUID' })
  @ApiResponse({ status: 200, description: 'List of historical saved shots' })
  @ApiResponse({ status: 404, description: 'Club not found' })
  async getClubShotHistory(
    @CurrentUser() user: UserPayload,
    @Param('clubId', ParseUUIDPipe) clubId: string,
  ) {
    return this.shotsService.getClubShotHistory(user.userId, clubId);
  }

  @Post('recommend')
  @ApiOperation({ summary: 'Recommend optimal club based on remaining distance and elevation' })
  @ApiResponse({ status: 200, description: 'Recommendation and Plays Like computation' })
  async recommendClub(
    @CurrentUser() user: UserPayload,
    @Body() dto: RecommendClubDto,
  ) {
    return this.shotsService.recommendClub(user.userId, dto);
  }

  @Get('recommendation')
  @ApiOperation({ summary: 'Query club recommendation via query parameters' })
  @ApiQuery({ name: 'distance', type: Number, example: 150 })
  @ApiQuery({ name: 'unit', enum: DistanceUnit, required: false, example: DistanceUnit.YARDS })
  @ApiQuery({ name: 'startElevation', type: Number, required: false, example: 10.0 })
  @ApiQuery({ name: 'targetElevation', type: Number, required: false, example: 18.0 })
  async getRecommendationQuery(
    @CurrentUser() user: UserPayload,
    @Query('distance') distance: string,
    @Query('unit') unit?: DistanceUnit,
    @Query('startElevation') startElevation?: string,
    @Query('targetElevation') targetElevation?: string,
  ) {
    const dto: RecommendClubDto = {
      remainingDistance: parseFloat(distance) || 0,
      unit: unit || DistanceUnit.YARDS,
      startElevation: startElevation ? parseFloat(startElevation) : undefined,
      targetElevation: targetElevation ? parseFloat(targetElevation) : undefined,
    };
    return this.shotsService.recommendClub(user.userId, dto);
  }
}

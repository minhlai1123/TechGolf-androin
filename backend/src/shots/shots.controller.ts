import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { ShotsService } from './shots.service';
import { StartShotDto } from './dto/start-shot.dto';
import { SaveShotDto } from './dto/save-shot.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Shot Tracking')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('rounds/:roundId')
export class ShotsController {
  constructor(private readonly shotsService: ShotsService) {}

  @Post('shots/start')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Start a shot at initial GPS location' })
  @ApiParam({ name: 'roundId', description: 'Round UUID' })
  @ApiResponse({ status: 201, description: 'Shot initiated in STARTED state' })
  @ApiResponse({ status: 400, description: 'Invalid coordinates or player/hole' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Round or Hole not found' })
  async startShot(
    @CurrentUser() user: UserPayload,
    @Param('roundId', ParseUUIDPipe) roundId: string,
    @Body() dto: StartShotDto,
  ) {
    return this.shotsService.startShot(user.userId, roundId, dto);
  }

  @Post('shots/:shotId/save')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Save shot after arriving at ball with end coordinates and club' })
  @ApiParam({ name: 'roundId', description: 'Round UUID' })
  @ApiParam({ name: 'shotId', description: 'Shot UUID' })
  @ApiResponse({ status: 200, description: 'Shot calculated and saved in SAVED state' })
  @ApiResponse({ status: 400, description: 'Shot not in STARTED state or invalid coordinates' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Shot or Club not found' })
  async saveShot(
    @CurrentUser() user: UserPayload,
    @Param('roundId', ParseUUIDPipe) roundId: string,
    @Param('shotId', ParseUUIDPipe) shotId: string,
    @Body() dto: SaveShotDto,
  ) {
    return this.shotsService.saveShot(user.userId, roundId, shotId, dto);
  }

  @Get('shots')
  @ApiOperation({ summary: 'Get all recorded shots for this round' })
  @ApiParam({ name: 'roundId', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'List of shots for round' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Round not found' })
  async getShotsByRound(
    @CurrentUser() user: UserPayload,
    @Param('roundId', ParseUUIDPipe) roundId: string,
  ) {
    return this.shotsService.getShotsByRound(roundId, user.userId);
  }

  @Get('holes/:holeId/shots')
  @ApiOperation({ summary: 'Get recorded shots for a specific hole in this round' })
  @ApiParam({ name: 'roundId', description: 'Round UUID' })
  @ApiParam({ name: 'holeId', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'List of shots for specific hole' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Round not found' })
  async getShotsByHole(
    @CurrentUser() user: UserPayload,
    @Param('roundId', ParseUUIDPipe) roundId: string,
    @Param('holeId', ParseUUIDPipe) holeId: string,
  ) {
    return this.shotsService.getShotsByHole(roundId, holeId, user.userId);
  }
}

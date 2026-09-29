import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { RoundsService } from './rounds.service';
import { CreateRoundDto } from './dto/create-round.dto';
import { SaveScoreDto } from './dto/save-score.dto';
import { UpdateCurrentHoleDto } from './dto/update-current-hole.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Rounds & Scorecards')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('rounds')
export class RoundsController {
  constructor(private readonly roundsService: RoundsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new round with 1 to 4 players' })
  @ApiResponse({ status: 201, description: 'Round created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid round or player input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  async createRound(
    @CurrentUser() user: UserPayload,
    @Body() dto: CreateRoundDto,
  ) {
    return this.roundsService.createRound(user.userId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get round details' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Round retrieved successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Round not found' })
  async getRound(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.roundsService.getRound(id, user.userId);
  }

  @Post(':id/start')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Start a round' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Round started successfully' })
  @ApiResponse({ status: 400, description: 'Round already started or completed' })
  async startRound(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.roundsService.startRound(id, user.userId);
  }

  @Patch(':id/current-hole')
  @ApiOperation({ summary: 'Update current hole of the round' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Current hole updated' })
  async updateCurrentHole(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCurrentHoleDto,
  ) {
    return this.roundsService.updateCurrentHole(id, user.userId, dto.currentHole);
  }

  @Post(':id/finish')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Finish a round' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Round completed successfully' })
  async finishRound(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.roundsService.finishRound(id, user.userId);
  }

  @Get(':id/scorecard')
  @ApiOperation({ summary: 'Get full scorecard matrix for round' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Scorecard retrieved successfully' })
  async getScorecard(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.roundsService.getScorecard(id, user.userId);
  }

  @Post(':id/scores')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Record or update a hole score for a player' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 201, description: 'Score saved successfully' })
  @ApiResponse({ status: 400, description: 'Validation failed (e.g., putts > gross score)' })
  async saveScore(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveScoreDto,
  ) {
    return this.roundsService.saveScore(id, user.userId, dto);
  }

  @Put(':id/scores/:scoreId')
  @ApiOperation({ summary: 'Update an existing score' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiParam({ name: 'scoreId', description: 'Score UUID' })
  @ApiResponse({ status: 200, description: 'Score updated successfully' })
  async updateScore(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('scoreId', ParseUUIDPipe) scoreId: string,
    @Body() dto: SaveScoreDto,
  ) {
    return this.roundsService.updateScore(id, scoreId, user.userId, dto);
  }

  @Get(':id/result')
  @ApiOperation({ summary: 'Get game mode result summary for round' })
  @ApiParam({ name: 'id', description: 'Round UUID' })
  @ApiResponse({ status: 200, description: 'Game mode result returned' })
  async getRoundResult(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.roundsService.getRoundResult(id, user.userId);
  }
}

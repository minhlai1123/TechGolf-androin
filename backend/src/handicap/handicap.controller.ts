import {
  Controller,
  Get,
  Post,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { HandicapService } from './handicap.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('WHS Handicap')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('handicap')
export class HandicapController {
  constructor(private readonly handicapService: HandicapService) {}

  @Get('current')
  @ApiOperation({ summary: 'Get current WHS Handicap Index for logged-in user' })
  @ApiResponse({ status: 200, description: 'Current handicap index and establishment status' })
  async getCurrentHandicap(@CurrentUser() user: UserPayload) {
    return this.handicapService.getCurrentHandicap(user.userId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get chronological history of handicap index calculations' })
  @ApiResponse({ status: 200, description: 'List of handicap history records' })
  async getHandicapHistory(@CurrentUser() user: UserPayload) {
    return this.handicapService.getHandicapHistory(user.userId);
  }

  @Get('differentials')
  @ApiOperation({ summary: 'Get all recorded score differentials for user rounds' })
  @ApiResponse({ status: 200, description: 'List of score differentials with course and tee information' })
  async getScoreDifferentials(@CurrentUser() user: UserPayload) {
    return this.handicapService.getScoreDifferentials(user.userId);
  }

  @Post('recalculate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Recalculate WHS Handicap Index from completed rounds' })
  @ApiResponse({ status: 200, description: 'Recalculation result with newly computed differentials' })
  async recalculateHandicap(@CurrentUser() user: UserPayload) {
    return this.handicapService.recalculateHandicap(user.userId);
  }
}

import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { GolfBagService } from './golf-bag.service';
import { CreateClubDto } from './dto/create-club.dto';
import { UpdateClubDto } from './dto/update-club.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, UserPayload } from '../common/decorators/current-user.decorator';

@ApiTags('Virtual Golf Bag')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('bag/clubs')
export class GolfBagController {
  constructor(private readonly golfBagService: GolfBagService) {}

  @Get()
  @ApiOperation({ summary: 'Get all clubs in user virtual golf bag' })
  @ApiResponse({ status: 200, description: 'List of clubs returned' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getClubs(@CurrentUser() user: UserPayload) {
    return this.golfBagService.getClubsByUser(user.userId);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a new club to virtual golf bag' })
  @ApiResponse({ status: 201, description: 'Club created successfully' })
  @ApiResponse({ status: 400, description: 'Bad Request - Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async createClub(
    @CurrentUser() user: UserPayload,
    @Body() dto: CreateClubDto,
  ) {
    return this.golfBagService.createClub(user.userId, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update an existing club in golf bag' })
  @ApiParam({ name: 'id', description: 'Club UUID' })
  @ApiResponse({ status: 200, description: 'Club updated successfully' })
  @ApiResponse({ status: 400, description: 'Bad Request - Invalid UUID or data' })
  @ApiResponse({ status: 403, description: 'Forbidden - Cannot modify other users club' })
  @ApiResponse({ status: 404, description: 'Club not found' })
  async updateClub(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateClubDto,
  ) {
    return this.golfBagService.updateClub(user.userId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a club from virtual golf bag' })
  @ApiParam({ name: 'id', description: 'Club UUID' })
  @ApiResponse({ status: 200, description: 'Club removed successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Cannot delete other users club' })
  @ApiResponse({ status: 404, description: 'Club not found' })
  async deleteClub(
    @CurrentUser() user: UserPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.golfBagService.deleteClub(user.userId, id);
  }
}

import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { HolesService } from './holes.service';
import { CreateHoleDto } from './dto/create-hole.dto';
import { UpdateHoleDto } from './dto/update-hole.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('Holes & Golf Course Map')
@Controller()
export class HolesController {
  constructor(private readonly holesService: HolesService) {}

  @Get('courses/:courseId/holes')
  @ApiOperation({ summary: 'List all holes belonging to a course' })
  @ApiParam({ name: 'courseId', description: 'Course UUID' })
  @ApiResponse({ status: 200, description: 'Holes list returned' })
  async findByCourse(@Param('courseId', ParseUUIDPipe) courseId: string) {
    return this.holesService.findByCourse(courseId);
  }

  @Post('courses/:courseId/holes')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: '[Admin] Add a hole to a golf course' })
  @ApiParam({ name: 'courseId', description: 'Course UUID' })
  @ApiResponse({ status: 201, description: 'Hole created' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  @ApiResponse({ status: 409, description: 'Conflict - Duplicate hole number on course' })
  async create(
    @Param('courseId', ParseUUIDPipe) courseId: string,
    @Body() dto: CreateHoleDto,
  ) {
    return this.holesService.create(courseId, dto);
  }

  @Get('holes/:id')
  @ApiOperation({ summary: 'Get hole details including tees and polygons' })
  @ApiParam({ name: 'id', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'Hole details returned' })
  @ApiResponse({ status: 404, description: 'Hole not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.holesService.findById(id);
  }

  @Patch('holes/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Update hole properties and green points' })
  @ApiParam({ name: 'id', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'Hole updated' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  @ApiResponse({ status: 404, description: 'Hole not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateHoleDto,
  ) {
    return this.holesService.update(id, dto);
  }

  @Delete('holes/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Delete a hole' })
  @ApiParam({ name: 'id', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'Hole deleted' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.holesService.remove(id);
  }

  @Get('holes/:id/map')
  @ApiOperation({
    summary: 'Get complete GeoJSON FeatureCollection of the hole for map rendering (Green F/M/B, Tee Markers, Vector Polygons)',
  })
  @ApiParam({ name: 'id', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'GeoJSON FeatureCollection returned' })
  @ApiResponse({ status: 404, description: 'Hole not found' })
  async getHoleMap(@Param('id', ParseUUIDPipe) id: string) {
    return this.holesService.getHoleMapData(id);
  }
}

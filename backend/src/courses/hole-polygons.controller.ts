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
import { HolePolygonsService } from './hole-polygons.service';
import { CreateHolePolygonDto } from './dto/create-hole-polygon.dto';
import { UpdateHolePolygonDto } from './dto/update-hole-polygon.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('Vector Polygons (Course Mapping)')
@Controller()
export class HolePolygonsController {
  constructor(private readonly holePolygonsService: HolePolygonsService) {}

  @Get('holes/:holeId/polygons')
  @ApiOperation({ summary: 'Get all vector polygons for a specific hole' })
  @ApiParam({ name: 'holeId', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'List of hole polygons' })
  async findByHole(@Param('holeId', ParseUUIDPipe) holeId: string) {
    return this.holePolygonsService.findByHole(holeId);
  }

  @Post('holes/:holeId/polygons')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: '[Admin] Draw and save a vector polygon on a hole (Fairway, Rough, Green, Bunker, Water Hazard, Tee)',
  })
  @ApiParam({ name: 'holeId', description: 'Hole UUID' })
  @ApiResponse({ status: 201, description: 'Polygon saved to PostGIS' })
  @ApiResponse({ status: 400, description: 'Bad Request - Invalid polygon geometry coordinates' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async create(
    @Param('holeId', ParseUUIDPipe) holeId: string,
    @Body() dto: CreateHolePolygonDto,
  ) {
    return this.holePolygonsService.create(holeId, dto);
  }

  @Patch('polygons/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Update coordinates or type of a vector polygon' })
  @ApiParam({ name: 'id', description: 'Polygon UUID' })
  @ApiResponse({ status: 200, description: 'Polygon updated' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  @ApiResponse({ status: 404, description: 'Polygon not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateHolePolygonDto,
  ) {
    return this.holePolygonsService.update(id, dto);
  }

  @Delete('polygons/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Delete a vector polygon from a hole' })
  @ApiParam({ name: 'id', description: 'Polygon UUID' })
  @ApiResponse({ status: 200, description: 'Polygon deleted' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  @ApiResponse({ status: 404, description: 'Polygon not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.holePolygonsService.remove(id);
  }
}

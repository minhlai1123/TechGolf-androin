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
import { CourseTeesService } from './course-tees.service';
import { CreateCourseTeeDto } from './dto/create-course-tee.dto';
import { UpdateCourseTeeDto } from './dto/update-course-tee.dto';
import { SetHoleTeeDto } from './dto/set-hole-tee.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('Tees (Course & Hole Markers)')
@Controller()
export class CourseTeesController {
  constructor(private readonly courseTeesService: CourseTeesService) {}

  @Get('courses/:courseId/tees')
  @ApiOperation({ summary: 'List all tees configured for a golf course' })
  @ApiParam({ name: 'courseId', description: 'Course UUID' })
  @ApiResponse({ status: 200, description: 'List of course tees' })
  async findCourseTees(@Param('courseId', ParseUUIDPipe) courseId: string) {
    return this.courseTeesService.findByCourse(courseId);
  }

  @Post('courses/:courseId/tees')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: '[Admin] Add a tee category to course (e.g. Red, Blue, White, Black)' })
  @ApiParam({ name: 'courseId', description: 'Course UUID' })
  @ApiResponse({ status: 201, description: 'Course tee created' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async createCourseTee(
    @Param('courseId', ParseUUIDPipe) courseId: string,
    @Body() dto: CreateCourseTeeDto,
  ) {
    return this.courseTeesService.createCourseTee(courseId, dto);
  }

  @Patch('course-tees/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Update course tee ratings or yardage' })
  @ApiParam({ name: 'id', description: 'Course Tee UUID' })
  @ApiResponse({ status: 200, description: 'Course tee updated' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async updateCourseTee(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCourseTeeDto,
  ) {
    return this.courseTeesService.updateCourseTee(id, dto);
  }

  @Delete('course-tees/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Delete a course tee' })
  @ApiParam({ name: 'id', description: 'Course Tee UUID' })
  @ApiResponse({ status: 200, description: 'Course tee deleted' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async removeCourseTee(@Param('id', ParseUUIDPipe) id: string) {
    return this.courseTeesService.removeCourseTee(id);
  }

  // --- Hole Tee Marker Placement ---

  @Get('holes/:holeId/tees')
  @ApiOperation({ summary: 'Get tee markers placed on a specific hole' })
  @ApiParam({ name: 'holeId', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'Hole tees returned' })
  async findHoleTees(@Param('holeId', ParseUUIDPipe) holeId: string) {
    return this.courseTeesService.findHoleTees(holeId);
  }

  @Post('holes/:holeId/tees')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Place or update tee marker position on a hole' })
  @ApiParam({ name: 'holeId', description: 'Hole UUID' })
  @ApiResponse({ status: 200, description: 'Hole tee placed successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async setHoleTee(
    @Param('holeId', ParseUUIDPipe) holeId: string,
    @Body() dto: SetHoleTeeDto,
  ) {
    return this.courseTeesService.setHoleTee(holeId, dto);
  }

  @Delete('hole-tees/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Remove a tee marker from a hole' })
  @ApiParam({ name: 'id', description: 'Hole Tee Marker UUID' })
  @ApiResponse({ status: 200, description: 'Hole tee marker removed' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin role required' })
  async removeHoleTee(@Param('id', ParseUUIDPipe) id: string) {
    return this.courseTeesService.removeHoleTee(id);
  }
}

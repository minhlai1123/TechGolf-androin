import { PartialType } from '@nestjs/swagger';
import { CreateCourseTeeDto } from './create-course-tee.dto';

export class UpdateCourseTeeDto extends PartialType(CreateCourseTeeDto) {}

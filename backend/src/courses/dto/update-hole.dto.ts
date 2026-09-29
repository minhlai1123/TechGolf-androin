import { PartialType } from '@nestjs/swagger';
import { CreateHoleDto } from './create-hole.dto';

export class UpdateHoleDto extends PartialType(CreateHoleDto) {}

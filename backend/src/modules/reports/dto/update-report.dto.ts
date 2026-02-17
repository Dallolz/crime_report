import {
  IsString,
  IsOptional,
  IsNumber,
  IsEnum,
  IsDateString,
} from 'class-validator';
import { Urgence, Statut } from '../../../entities/report.entity.js';

export class UpdateReportDto {
  @IsString()
  @IsOptional()
  titre?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  typeCrime?: string;

  @IsDateString()
  @IsOptional()
  dateIncident?: string;

  @IsString()
  @IsOptional()
  lieu?: string;

  @IsNumber()
  @IsOptional()
  latitude?: number;

  @IsNumber()
  @IsOptional()
  longitude?: number;

  @IsEnum(Urgence)
  @IsOptional()
  urgence?: Urgence;

  @IsEnum(Statut)
  @IsOptional()
  statut?: Statut;
}

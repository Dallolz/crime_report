import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsEnum,
  IsDateString,
} from 'class-validator';
import { Urgence, Statut } from '../../../entities/report.entity.js';

export class CreateReportDto {
  @IsString()
  @IsNotEmpty()
  titre: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsString()
  @IsNotEmpty()
  typeCrime: string;

  @IsDateString()
  @IsNotEmpty()
  dateIncident: string;

  @IsString()
  @IsNotEmpty()
  lieu: string;

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

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CrimeCategory } from '../../entities/crime-category.entity.js';
import { CrimesController } from './crimes.controller.js';
import { CrimesService } from './crimes.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([CrimeCategory])],
  controllers: [CrimesController],
  providers: [CrimesService],
  exports: [CrimesService],
})
export class CrimesModule {}

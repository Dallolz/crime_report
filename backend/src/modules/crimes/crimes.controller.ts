import { Controller, Get } from '@nestjs/common';
import { CrimesService } from './crimes.service.js';

@Controller('crimes')
export class CrimesController {
  constructor(private readonly crimesService: CrimesService) {}

  @Get('categories')
  async getCategories() {
    return this.crimesService.findAllCategories();
  }
}

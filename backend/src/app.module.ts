import { Module, OnModuleInit } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity.js';
import { Report } from './entities/report.entity.js';
import { CrimeCategory } from './entities/crime-category.entity.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { ReportsModule } from './modules/reports/reports.module.js';
import { CrimesModule } from './modules/crimes/crimes.module.js';
import { StatsModule } from './modules/stats/stats.module.js';
import { CrimesService } from './modules/crimes/crimes.service.js';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: './signalcrime.db',
      entities: [User, Report, CrimeCategory],
      synchronize: true,
    }),
    AuthModule,
    ReportsModule,
    CrimesModule,
    StatsModule,
  ],
})
export class AppModule implements OnModuleInit {
  constructor(private readonly crimesService: CrimesService) {}

  async onModuleInit() {
    await this.crimesService.seedCategories();
  }
}

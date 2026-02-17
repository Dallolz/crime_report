import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Report } from '../../entities/report.entity.js';

@Injectable()
export class StatsService {
  constructor(
    @InjectRepository(Report)
    private readonly reportRepository: Repository<Report>,
  ) {}

  async getStats() {
    const totalReports = await this.reportRepository.count();

    const reportsByType = await this.reportRepository
      .createQueryBuilder('report')
      .select('report.typeCrime', 'typeCrime')
      .addSelect('COUNT(*)', 'count')
      .groupBy('report.typeCrime')
      .getRawMany();

    const reportsByUrgence = await this.reportRepository
      .createQueryBuilder('report')
      .select('report.urgence', 'urgence')
      .addSelect('COUNT(*)', 'count')
      .groupBy('report.urgence')
      .getRawMany();

    const reportsByStatut = await this.reportRepository
      .createQueryBuilder('report')
      .select('report.statut', 'statut')
      .addSelect('COUNT(*)', 'count')
      .groupBy('report.statut')
      .getRawMany();

    // Reports by month (last 12 months)
    const reportsByMonth = await this.reportRepository
      .createQueryBuilder('report')
      .select("strftime('%Y-%m', report.createdAt)", 'month')
      .addSelect('COUNT(*)', 'count')
      .where(
        "report.createdAt >= date('now', '-12 months')",
      )
      .groupBy("strftime('%Y-%m', report.createdAt)")
      .orderBy("strftime('%Y-%m', report.createdAt)", 'ASC')
      .getRawMany();

    // Recent reports (last 10)
    const recentReports = await this.reportRepository.find({
      order: { createdAt: 'DESC' },
      take: 10,
      relations: ['user'],
    });

    // Remove password from user data in recent reports
    const sanitizedRecentReports = recentReports.map((report) => {
      if (report.user) {
        const { password, ...userWithoutPassword } = report.user;
        report.user = userWithoutPassword as any;
      }
      return report;
    });

    return {
      total: totalReports,
      parType: reportsByType,
      parUrgence: reportsByUrgence,
      parStatut: reportsByStatut,
      parMois: reportsByMonth.map((r) => ({ mois: r.month, count: r.count })),
      recents: sanitizedRecentReports,
    };
  }
}

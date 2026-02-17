import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Report } from '../../entities/report.entity.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { UpdateReportDto } from './dto/update-report.dto.js';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Report)
    private readonly reportRepository: Repository<Report>,
  ) {}

  private sanitizeReport(report: Report): Report {
    if (report.user) {
      const { password, ...userWithoutPassword } = report.user;
      report.user = userWithoutPassword as any;
    }
    return report;
  }

  async findAll(filters: {
    statut?: string;
    typeCrime?: string;
    urgence?: string;
  }): Promise<Report[]> {
    const queryBuilder = this.reportRepository
      .createQueryBuilder('report')
      .leftJoinAndSelect('report.user', 'user')
      .orderBy('report.createdAt', 'DESC');

    if (filters.statut) {
      queryBuilder.andWhere('report.statut = :statut', {
        statut: filters.statut,
      });
    }

    if (filters.typeCrime) {
      queryBuilder.andWhere('report.typeCrime = :typeCrime', {
        typeCrime: filters.typeCrime,
      });
    }

    if (filters.urgence) {
      queryBuilder.andWhere('report.urgence = :urgence', {
        urgence: filters.urgence,
      });
    }

    const reports = await queryBuilder.getMany();
    return reports.map((report) => this.sanitizeReport(report));
  }

  async findOne(id: number): Promise<Report> {
    const report = await this.reportRepository.findOne({
      where: { id },
      relations: ['user'],
    });

    if (!report) {
      throw new NotFoundException(`Signalement #${id} introuvable`);
    }

    return this.sanitizeReport(report);
  }

  async create(createReportDto: CreateReportDto, userId: number): Promise<Report> {
    const report = this.reportRepository.create({
      ...createReportDto,
      userId,
    });

    return this.reportRepository.save(report);
  }

  async update(id: number, updateReportDto: UpdateReportDto): Promise<Report> {
    const report = await this.reportRepository.findOne({ where: { id } });

    if (!report) {
      throw new NotFoundException(`Signalement #${id} introuvable`);
    }

    Object.assign(report, updateReportDto);
    await this.reportRepository.save(report);

    const updated = await this.reportRepository.findOne({
      where: { id },
      relations: ['user'],
    });

    return this.sanitizeReport(updated!);
  }

  async remove(id: number): Promise<void> {
    const report = await this.reportRepository.findOne({ where: { id } });

    if (!report) {
      throw new NotFoundException(`Signalement #${id} introuvable`);
    }

    await this.reportRepository.remove(report);
  }
}

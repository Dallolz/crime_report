import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CrimeCategory } from '../../entities/crime-category.entity.js';

@Injectable()
export class CrimesService {
  constructor(
    @InjectRepository(CrimeCategory)
    private readonly crimeCategoryRepository: Repository<CrimeCategory>,
  ) {}

  async findAllCategories(): Promise<CrimeCategory[]> {
    return this.crimeCategoryRepository.find({ order: { id: 'ASC' } });
  }

  async seedCategories(): Promise<void> {
    const count = await this.crimeCategoryRepository.count();
    if (count > 0) {
      return;
    }

    const categories: Partial<CrimeCategory>[] = [
      {
        nom: 'Vol / Cambriolage',
        description: 'Vol à la tire, cambriolage, vol de véhicule',
        icone: 'lock-open',
      },
      {
        nom: 'Agression physique',
        description: 'Coups et blessures, agression à main armée',
        icone: 'person-falling',
      },
      {
        nom: 'Agression verbale / Menaces',
        description: 'Insultes, menaces, intimidation',
        icone: 'comment-exclamation',
      },
      {
        nom: 'Vandalisme / Dégradation',
        description: 'Dégradation de biens publics ou privés, graffitis',
        icone: 'hammer',
      },
      {
        nom: 'Fraude / Escroquerie',
        description: 'Arnaque, fraude bancaire, usurpation d\'identité',
        icone: 'file-invoice-dollar',
      },
      {
        nom: 'Cybercriminalité',
        description: 'Piratage informatique, phishing, ransomware',
        icone: 'laptop-code',
      },
      {
        nom: 'Trafic de stupéfiants',
        description: 'Vente ou consommation de drogues illicites',
        icone: 'pills',
      },
      {
        nom: 'Violence domestique',
        description: 'Violence conjugale, maltraitance familiale',
        icone: 'house-crack',
      },
      {
        nom: 'Harcèlement',
        description: 'Harcèlement moral, sexuel, stalking',
        icone: 'user-shield',
      },
      {
        nom: 'Autre',
        description: 'Autre type d\'infraction non catégorisée',
        icone: 'circle-question',
      },
    ];

    await this.crimeCategoryRepository.save(categories);
  }
}

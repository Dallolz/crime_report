import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity.js';

export enum Urgence {
  FAIBLE = 'faible',
  MOYEN = 'moyen',
  ELEVE = 'eleve',
  CRITIQUE = 'critique',
}

export enum Statut {
  BROUILLON = 'brouillon',
  SOUMIS = 'soumis',
  EN_COURS = 'en_cours',
  RESOLU = 'resolu',
  CLASSE = 'classe',
}

@Entity('reports')
export class Report {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  titre: string;

  @Column({ type: 'text' })
  description: string;

  @Column()
  typeCrime: string;

  @Column({ type: 'date' })
  dateIncident: Date;

  @Column()
  lieu: string;

  @Column({ type: 'float', nullable: true })
  latitude: number | null;

  @Column({ type: 'float', nullable: true })
  longitude: number | null;

  @Column({
    type: 'text',
    default: Urgence.MOYEN,
  })
  urgence: Urgence;

  @Column({
    type: 'text',
    default: Statut.BROUILLON,
  })
  statut: Statut;

  @Column()
  userId: number;

  @ManyToOne(() => User, (user) => user.reports, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

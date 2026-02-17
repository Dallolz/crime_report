import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('crime_categories')
export class CrimeCategory {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nom: string;

  @Column()
  description: string;

  @Column()
  icone: string;
}

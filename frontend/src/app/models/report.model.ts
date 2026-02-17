export interface Report {
  id: number;
  titre: string;
  description: string;
  typeCrime: string;
  dateIncident: string;
  lieu: string;
  latitude?: number;
  longitude?: number;
  urgence: 'faible' | 'moyen' | 'eleve' | 'critique';
  statut: 'brouillon' | 'soumis' | 'en_cours' | 'resolu' | 'classe';
  userId: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateReport {
  titre: string;
  description: string;
  typeCrime: string;
  dateIncident: string;
  lieu: string;
  latitude?: number;
  longitude?: number;
  urgence: 'faible' | 'moyen' | 'eleve' | 'critique';
}

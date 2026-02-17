export interface Stats {
  total: number;
  parType: { typeCrime: string; count: number }[];
  parUrgence: { urgence: string; count: number }[];
  parStatut: { statut: string; count: number }[];
  parMois: { mois: string; count: number }[];
  recents: any[];
}

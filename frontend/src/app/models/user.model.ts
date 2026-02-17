export interface User {
  id: number;
  email: string;
  nom: string;
  prenom: string;
  role: 'citoyen' | 'police' | 'admin';
}

export interface LoginResponse {
  access_token: string;
  user: User;
}

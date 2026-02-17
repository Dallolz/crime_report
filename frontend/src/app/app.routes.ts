import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  {
    path: 'dashboard',
    loadComponent: () =>
      import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent),
  },
  {
    path: 'nouveau-signalement',
    loadComponent: () =>
      import('./pages/nouveau-signalement/nouveau-signalement.component').then(
        (m) => m.NouveauSignalementComponent
      ),
  },
  {
    path: 'mes-signalements',
    loadComponent: () =>
      import('./pages/mes-signalements/mes-signalements.component').then(
        (m) => m.MesSignalementsComponent
      ),
  },
  {
    path: 'carte',
    loadComponent: () =>
      import('./pages/carte/carte.component').then((m) => m.CarteComponent),
  },
  {
    path: 'connexion',
    loadComponent: () =>
      import('./pages/connexion/connexion.component').then((m) => m.ConnexionComponent),
  },
];

import { Component } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { CommonModule } from '@angular/common';
import { SidebarComponent } from './components/layout/sidebar.component';
import { HeaderComponent } from './components/layout/header.component';
import { filter } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, SidebarComponent, HeaderComponent],
  template: `
    <div class="flex h-screen bg-background">
      <app-sidebar [(mobileOpen)]="sidebarMobileOpen" />
      <div class="flex-1 flex flex-col overflow-hidden">
        <app-header [pageTitle]="pageTitle" (toggleSidebar)="sidebarMobileOpen = !sidebarMobileOpen" />
        <main class="flex-1 overflow-y-auto p-6">
          <router-outlet />
        </main>
      </div>
    </div>
  `,
})
export class App {
  pageTitle = 'Tableau de bord';
  sidebarMobileOpen = false;

  private pageTitles: Record<string, string> = {
    '/dashboard': 'Tableau de bord',
    '/nouveau-signalement': 'Nouveau signalement',
    '/mes-signalements': 'Mes signalements',
    '/carte': 'Carte 3D',
    '/connexion': 'Connexion',
  };

  constructor(private router: Router) {
    this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe((event) => {
        this.pageTitle = this.pageTitles[event.urlAfterRedirects] || 'SignalCrime';
      });
  }
}

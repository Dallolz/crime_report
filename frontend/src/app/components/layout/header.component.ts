import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user.model';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <header class="flex items-center justify-between h-16 px-6 border-b bg-background">
      <div class="flex items-center gap-4">
        <!-- Mobile menu toggle -->
        <button
          class="lg:hidden p-2 rounded-md hover:bg-accent transition-colors cursor-pointer"
          (click)="toggleMobile()"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/>
          </svg>
        </button>
        <h1 class="text-xl font-semibold text-foreground">{{ pageTitle }}</h1>
      </div>

      <div class="flex items-center gap-3">
        @if (currentUser) {
          <div class="flex items-center gap-2">
            <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-foreground text-sm font-medium">
              {{ currentUser.prenom.charAt(0) }}{{ currentUser.nom.charAt(0) }}
            </div>
            <span class="hidden sm:inline text-sm font-medium text-foreground">{{ currentUser.prenom }}</span>
          </div>
        } @else {
          <a
            routerLink="/connexion"
            class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium h-9 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90 transition-colors"
          >
            Connexion
          </a>
        }
      </div>
    </header>
  `,
})
export class HeaderComponent {
  @Input() pageTitle = '';
  @Output() toggleSidebar = new EventEmitter<void>();

  currentUser: User | null = null;

  constructor(private authService: AuthService) {
    this.authService.currentUser$.subscribe((user) => {
      this.currentUser = user;
    });
  }

  toggleMobile(): void {
    this.toggleSidebar.emit();
  }
}

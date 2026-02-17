import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import {
  CardComponent,
  CardHeaderComponent,
  CardTitleComponent,
  CardDescriptionComponent,
  CardContentComponent,
} from '../../components/ui/card.component';
import { ButtonComponent } from '../../components/ui/button.component';
import { InputComponent } from '../../components/ui/input.component';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-connexion',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    CardComponent,
    CardHeaderComponent,
    CardTitleComponent,
    CardDescriptionComponent,
    CardContentComponent,
    ButtonComponent,
    InputComponent,
  ],
  template: `
    <div class="flex items-center justify-center min-h-[calc(100vh-12rem)]">
      <div class="w-full max-w-md">
        <ui-card>
          <ui-card-header className="text-center">
            <div class="flex justify-center mb-4">
              <div class="flex items-center justify-center w-12 h-12 rounded-lg bg-primary">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>
                </svg>
              </div>
            </div>
            <ui-card-title>{{ isLogin ? 'Connexion' : 'Inscription' }}</ui-card-title>
            <ui-card-description>
              {{ isLogin ? 'Connectez-vous a votre compte SignalCrime' : 'Creez votre compte SignalCrime' }}
            </ui-card-description>
          </ui-card-header>

          <ui-card-content>
            <!-- Tabs -->
            <div class="flex mb-6 border-b">
              <button
                (click)="switchTab(true)"
                [class]="'flex-1 py-2.5 text-sm font-medium text-center transition-colors cursor-pointer ' + (isLogin ? 'border-b-2 border-primary text-primary' : 'text-muted-foreground hover:text-foreground')"
              >
                Connexion
              </button>
              <button
                (click)="switchTab(false)"
                [class]="'flex-1 py-2.5 text-sm font-medium text-center transition-colors cursor-pointer ' + (!isLogin ? 'border-b-2 border-primary text-primary' : 'text-muted-foreground hover:text-foreground')"
              >
                Inscription
              </button>
            </div>

            @if (isLogin) {
              <form [formGroup]="loginForm" (ngSubmit)="onLogin()" class="space-y-4">
                <ui-input
                  label="Email"
                  type="email"
                  placeholder="votre@email.com"
                  inputId="login-email"
                  formControlName="email"
                />
                <ui-input
                  label="Mot de passe"
                  type="password"
                  placeholder="Votre mot de passe"
                  inputId="login-password"
                  formControlName="password"
                />

                @if (errorMessage) {
                  <div class="rounded-md bg-red-50 border border-red-200 p-3">
                    <p class="text-sm text-red-800">{{ errorMessage }}</p>
                  </div>
                }

                <ui-button type="submit" [disabled]="loginForm.invalid || submitting" className="w-full">
                  {{ submitting ? 'Connexion en cours...' : 'Se connecter' }}
                </ui-button>
              </form>
            } @else {
              <form [formGroup]="registerForm" (ngSubmit)="onRegister()" class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                  <ui-input
                    label="Prenom"
                    placeholder="Jean"
                    inputId="register-prenom"
                    formControlName="prenom"
                  />
                  <ui-input
                    label="Nom"
                    placeholder="Dupont"
                    inputId="register-nom"
                    formControlName="nom"
                  />
                </div>
                <ui-input
                  label="Email"
                  type="email"
                  placeholder="votre@email.com"
                  inputId="register-email"
                  formControlName="email"
                />
                <ui-input
                  label="Mot de passe"
                  type="password"
                  placeholder="Choisissez un mot de passe"
                  inputId="register-password"
                  formControlName="password"
                />

                @if (errorMessage) {
                  <div class="rounded-md bg-red-50 border border-red-200 p-3">
                    <p class="text-sm text-red-800">{{ errorMessage }}</p>
                  </div>
                }

                <ui-button type="submit" [disabled]="registerForm.invalid || submitting" className="w-full">
                  {{ submitting ? 'Inscription en cours...' : 'Creer un compte' }}
                </ui-button>
              </form>
            }
          </ui-card-content>
        </ui-card>
      </div>
    </div>
  `,
})
export class ConnexionComponent {
  isLogin = true;
  submitting = false;
  errorMessage = '';

  loginForm = new FormGroup({
    email: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.email] }),
    password: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
  });

  registerForm = new FormGroup({
    prenom: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    nom: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    email: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.email] }),
    password: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.minLength(6)] }),
  });

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  switchTab(isLogin: boolean): void {
    this.isLogin = isLogin;
    this.errorMessage = '';
  }

  onLogin(): void {
    if (this.loginForm.invalid) return;

    this.submitting = true;
    this.errorMessage = '';

    const { email, password } = this.loginForm.getRawValue();

    this.authService.login(email, password).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.submitting = false;
        this.errorMessage = err?.error?.message || 'Identifiants incorrects';
      },
    });
  }

  onRegister(): void {
    if (this.registerForm.invalid) return;

    this.submitting = true;
    this.errorMessage = '';

    const { email, password, nom, prenom } = this.registerForm.getRawValue();

    this.authService.register(email, password, nom, prenom).subscribe({
      next: () => {
        this.submitting = false;
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.submitting = false;
        this.errorMessage = err?.error?.message || 'Erreur lors de l\'inscription';
      },
    });
  }
}

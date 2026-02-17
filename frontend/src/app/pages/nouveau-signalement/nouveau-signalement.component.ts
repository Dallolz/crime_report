import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormGroup, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import {
  CardComponent,
  CardHeaderComponent,
  CardTitleComponent,
  CardDescriptionComponent,
  CardContentComponent,
  CardFooterComponent,
} from '../../components/ui/card.component';
import { ButtonComponent } from '../../components/ui/button.component';
import { InputComponent } from '../../components/ui/input.component';
import { TextareaComponent } from '../../components/ui/textarea.component';
import { SelectComponent } from '../../components/ui/select.component';
import { ApiService } from '../../services/api.service';
import { CrimeCategory } from '../../models/crime-category.model';

@Component({
  selector: 'app-nouveau-signalement',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    CardComponent,
    CardHeaderComponent,
    CardTitleComponent,
    CardDescriptionComponent,
    CardContentComponent,
    CardFooterComponent,
    ButtonComponent,
    InputComponent,
    TextareaComponent,
    SelectComponent,
  ],
  template: `
    <div class="max-w-2xl mx-auto">
      <ui-card>
        <ui-card-header>
          <ui-card-title>Nouveau signalement</ui-card-title>
          <ui-card-description>
            Remplissez le formulaire ci-dessous pour signaler un incident
          </ui-card-description>
        </ui-card-header>
        <ui-card-content>
          <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
            <ui-input
              label="Titre"
              placeholder="Titre du signalement"
              inputId="titre"
              formControlName="titre"
            />

            <ui-select
              label="Type de crime"
              placeholder="Selectionnez un type"
              selectId="typeCrime"
              [options]="crimeTypeOptions"
              formControlName="typeCrime"
            />

            <ui-input
              label="Date de l'incident"
              type="date"
              inputId="dateIncident"
              formControlName="dateIncident"
            />

            <ui-input
              label="Lieu"
              placeholder="Adresse ou description du lieu"
              inputId="lieu"
              formControlName="lieu"
            />

            <ui-textarea
              label="Description"
              placeholder="Decrivez l'incident en detail..."
              textareaId="description"
              [rows]="5"
              formControlName="description"
            />

            <ui-select
              label="Niveau d'urgence"
              placeholder="Selectionnez le niveau d'urgence"
              selectId="urgence"
              [options]="urgenceOptions"
              formControlName="urgence"
            />

            @if (successMessage) {
              <div class="rounded-md bg-green-50 border border-green-200 p-4">
                <p class="text-sm text-green-800">{{ successMessage }}</p>
              </div>
            }

            @if (errorMessage) {
              <div class="rounded-md bg-red-50 border border-red-200 p-4">
                <p class="text-sm text-red-800">{{ errorMessage }}</p>
              </div>
            }

            <ui-card-footer className="px-0 pb-0">
              <ui-button type="submit" [disabled]="form.invalid || submitting">
                {{ submitting ? 'Envoi en cours...' : 'Soumettre le signalement' }}
              </ui-button>
            </ui-card-footer>
          </form>
        </ui-card-content>
      </ui-card>
    </div>
  `,
})
export class NouveauSignalementComponent implements OnInit {
  form = new FormGroup({
    titre: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    typeCrime: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    dateIncident: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    lieu: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    description: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    urgence: new FormControl<'faible' | 'moyen' | 'eleve' | 'critique'>('moyen', {
      nonNullable: true,
      validators: [Validators.required],
    }),
  });

  crimeTypeOptions: { value: string; label: string }[] = [
    { value: 'Vol', label: 'Vol' },
    { value: 'Agression', label: 'Agression' },
    { value: 'Cambriolage', label: 'Cambriolage' },
    { value: 'Vandalisme', label: 'Vandalisme' },
    { value: 'Fraude', label: 'Fraude' },
    { value: 'Violence', label: 'Violence' },
    { value: 'Trafic', label: 'Trafic de stupéfiants' },
    { value: 'Autre', label: 'Autre' },
  ];

  urgenceOptions: { value: string; label: string }[] = [
    { value: 'faible', label: 'Faible' },
    { value: 'moyen', label: 'Moyen' },
    { value: 'eleve', label: 'Eleve' },
    { value: 'critique', label: 'Critique' },
  ];

  submitting = false;
  successMessage = '';
  errorMessage = '';

  constructor(
    private apiService: ApiService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCategories();
  }

  loadCategories(): void {
    this.apiService.getCategories().subscribe({
      next: (categories: CrimeCategory[]) => {
        if (categories.length > 0) {
          this.crimeTypeOptions = categories.map((c) => ({
            value: c.nom,
            label: c.nom,
          }));
        }
      },
      error: () => {
        // Keep default options
      },
    });
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    this.submitting = true;
    this.successMessage = '';
    this.errorMessage = '';

    const formValue = this.form.getRawValue();

    this.apiService
      .createReport({
        titre: formValue.titre,
        description: formValue.description,
        typeCrime: formValue.typeCrime,
        dateIncident: formValue.dateIncident,
        lieu: formValue.lieu,
        urgence: formValue.urgence,
      })
      .subscribe({
        next: () => {
          this.submitting = false;
          this.successMessage = 'Signalement soumis avec succes!';
          this.form.reset();
          setTimeout(() => {
            this.router.navigate(['/mes-signalements']);
          }, 1500);
        },
        error: (err) => {
          this.submitting = false;
          this.errorMessage =
            err?.error?.message || 'Erreur lors de la soumission. Veuillez reessayer.';
        },
      });
  }
}

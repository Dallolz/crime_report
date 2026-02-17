import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  CardComponent,
  CardHeaderComponent,
  CardTitleComponent,
  CardDescriptionComponent,
  CardContentComponent,
} from '../../components/ui/card.component';
import { ButtonComponent } from '../../components/ui/button.component';
import { BadgeComponent } from '../../components/ui/badge.component';
import { SelectComponent } from '../../components/ui/select.component';
import { DialogComponent } from '../../components/ui/dialog.component';
import {
  TableComponent,
  TableHeaderComponent,
  TableBodyComponent,
  TableRowComponent,
  TableHeadComponent,
  TableCellComponent,
} from '../../components/ui/table.component';
import { ApiService } from '../../services/api.service';
import { Report } from '../../models/report.model';

@Component({
  selector: 'app-mes-signalements',
  standalone: true,
  imports: [
    CommonModule,
    CardComponent,
    CardHeaderComponent,
    CardTitleComponent,
    CardDescriptionComponent,
    CardContentComponent,
    ButtonComponent,
    BadgeComponent,
    SelectComponent,
    DialogComponent,
    TableComponent,
    TableHeaderComponent,
    TableBodyComponent,
    TableRowComponent,
    TableHeadComponent,
    TableCellComponent,
  ],
  template: `
    <div class="space-y-6">
      <ui-card>
        <ui-card-header>
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <ui-card-title>Mes signalements</ui-card-title>
              <ui-card-description>Liste de tous vos signalements</ui-card-description>
            </div>
            <div class="flex gap-2">
              <ui-select
                placeholder="Filtrer par statut"
                selectId="filterStatut"
                [options]="statutOptions"
                (change)="onStatutFilterChange($event)"
              />
              <ui-select
                placeholder="Filtrer par type"
                selectId="filterType"
                [options]="typeOptions"
                (change)="onTypeFilterChange($event)"
              />
            </div>
          </div>
        </ui-card-header>
        <ui-card-content>
          <ui-table>
            <ui-table-header>
              <ui-table-row>
                <ui-table-head>Date</ui-table-head>
                <ui-table-head>Titre</ui-table-head>
                <ui-table-head>Type</ui-table-head>
                <ui-table-head>Urgence</ui-table-head>
                <ui-table-head>Statut</ui-table-head>
                <ui-table-head>Actions</ui-table-head>
              </ui-table-row>
            </ui-table-header>
            <ui-table-body>
              @for (report of filteredReports; track report.id) {
                <ui-table-row>
                  <ui-table-cell>{{ report.createdAt | date: 'dd/MM/yyyy' }}</ui-table-cell>
                  <ui-table-cell>
                    <span class="font-medium">{{ report.titre }}</span>
                  </ui-table-cell>
                  <ui-table-cell>{{ report.typeCrime }}</ui-table-cell>
                  <ui-table-cell>
                    <ui-badge [variant]="getUrgenceBadgeVariant(report.urgence)">
                      {{ getUrgenceLabel(report.urgence) }}
                    </ui-badge>
                  </ui-table-cell>
                  <ui-table-cell>
                    <ui-badge [variant]="getStatutBadgeVariant(report.statut)">
                      {{ getStatutLabel(report.statut) }}
                    </ui-badge>
                  </ui-table-cell>
                  <ui-table-cell>
                    <ui-button variant="ghost" size="sm" (click)="openDetail(report)">
                      Voir
                    </ui-button>
                    <ui-button variant="ghost" size="sm" (click)="deleteReport(report.id)">
                      <span class="text-destructive">Supprimer</span>
                    </ui-button>
                  </ui-table-cell>
                </ui-table-row>
              }
              @if (filteredReports.length === 0) {
                <ui-table-row>
                  <ui-table-cell>
                    <div class="text-center text-muted-foreground py-8">
                      Aucun signalement trouve
                    </div>
                  </ui-table-cell>
                </ui-table-row>
              }
            </ui-table-body>
          </ui-table>
        </ui-card-content>
      </ui-card>

      <!-- Detail Dialog -->
      <ui-dialog
        [open]="dialogOpen"
        [title]="selectedReport?.titre || ''"
        (openChange)="dialogOpen = $event"
      >
        @if (selectedReport) {
          <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <p class="text-sm text-muted-foreground">Type de crime</p>
                <p class="font-medium">{{ selectedReport.typeCrime }}</p>
              </div>
              <div>
                <p class="text-sm text-muted-foreground">Date de l'incident</p>
                <p class="font-medium">{{ selectedReport.dateIncident | date: 'dd/MM/yyyy' }}</p>
              </div>
              <div>
                <p class="text-sm text-muted-foreground">Lieu</p>
                <p class="font-medium">{{ selectedReport.lieu }}</p>
              </div>
              <div>
                <p class="text-sm text-muted-foreground">Urgence</p>
                <ui-badge [variant]="getUrgenceBadgeVariant(selectedReport.urgence)">
                  {{ getUrgenceLabel(selectedReport.urgence) }}
                </ui-badge>
              </div>
              <div>
                <p class="text-sm text-muted-foreground">Statut</p>
                <ui-badge [variant]="getStatutBadgeVariant(selectedReport.statut)">
                  {{ getStatutLabel(selectedReport.statut) }}
                </ui-badge>
              </div>
              <div>
                <p class="text-sm text-muted-foreground">Date de creation</p>
                <p class="font-medium">{{ selectedReport.createdAt | date: 'dd/MM/yyyy HH:mm' }}</p>
              </div>
            </div>
            <div>
              <p class="text-sm text-muted-foreground">Description</p>
              <p class="mt-1">{{ selectedReport.description }}</p>
            </div>
          </div>
        }
      </ui-dialog>
    </div>
  `,
})
export class MesSignalementsComponent implements OnInit {
  reports: Report[] = [];
  filteredReports: Report[] = [];
  selectedReport: Report | null = null;
  dialogOpen = false;

  filterStatut = '';
  filterType = '';

  statutOptions = [
    { value: '', label: 'Tous les statuts' },
    { value: 'brouillon', label: 'Brouillon' },
    { value: 'soumis', label: 'Soumis' },
    { value: 'en_cours', label: 'En cours' },
    { value: 'resolu', label: 'Resolu' },
    { value: 'classe', label: 'Classe' },
  ];

  typeOptions = [
    { value: '', label: 'Tous les types' },
    { value: 'Vol', label: 'Vol' },
    { value: 'Agression', label: 'Agression' },
    { value: 'Cambriolage', label: 'Cambriolage' },
    { value: 'Vandalisme', label: 'Vandalisme' },
    { value: 'Fraude', label: 'Fraude' },
    { value: 'Violence', label: 'Violence' },
    { value: 'Autre', label: 'Autre' },
  ];

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.loadReports();
  }

  loadReports(): void {
    this.apiService.getReports().subscribe({
      next: (reports) => {
        this.reports = reports;
        this.applyFilters();
      },
      error: () => {
        // Use mock data
        this.reports = [
          {
            id: 1,
            titre: 'Vol de vehicule',
            description: 'Mon vehicule a ete vole dans le parking souterrain de mon immeuble.',
            typeCrime: 'Vol',
            dateIncident: '2026-02-10',
            lieu: '15 Rue de la Paix, Paris',
            urgence: 'eleve',
            statut: 'en_cours',
            userId: 1,
            createdAt: '2026-02-10T10:00:00Z',
            updatedAt: '2026-02-10T10:00:00Z',
          },
          {
            id: 2,
            titre: 'Cambriolage appartement',
            description: 'Appartement cambriolé pendant les vacances.',
            typeCrime: 'Cambriolage',
            dateIncident: '2026-02-08',
            lieu: '42 Avenue des Champs-Elysees, Paris',
            urgence: 'critique',
            statut: 'soumis',
            userId: 1,
            createdAt: '2026-02-08T14:30:00Z',
            updatedAt: '2026-02-08T14:30:00Z',
          },
          {
            id: 3,
            titre: 'Vandalisme parking',
            description: 'Tags et degradations dans le parking public.',
            typeCrime: 'Vandalisme',
            dateIncident: '2026-02-05',
            lieu: 'Parking Centre Commercial, Lyon',
            urgence: 'moyen',
            statut: 'resolu',
            userId: 1,
            createdAt: '2026-02-05T09:15:00Z',
            updatedAt: '2026-02-12T16:00:00Z',
          },
        ];
        this.applyFilters();
      },
    });
  }

  applyFilters(): void {
    this.filteredReports = this.reports.filter((report) => {
      const matchStatut = !this.filterStatut || report.statut === this.filterStatut;
      const matchType = !this.filterType || report.typeCrime === this.filterType;
      return matchStatut && matchType;
    });
  }

  onStatutFilterChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.filterStatut = target.value;
    this.applyFilters();
  }

  onTypeFilterChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.filterType = target.value;
    this.applyFilters();
  }

  openDetail(report: Report): void {
    this.selectedReport = report;
    this.dialogOpen = true;
  }

  deleteReport(id: number): void {
    if (confirm('Etes-vous sur de vouloir supprimer ce signalement ?')) {
      this.apiService.deleteReport(id).subscribe({
        next: () => {
          this.reports = this.reports.filter((r) => r.id !== id);
          this.applyFilters();
        },
        error: () => {
          // Still remove locally for demo
          this.reports = this.reports.filter((r) => r.id !== id);
          this.applyFilters();
        },
      });
    }
  }

  getUrgenceLabel(urgence: string): string {
    const labels: Record<string, string> = {
      faible: 'Faible',
      moyen: 'Moyen',
      eleve: 'Eleve',
      critique: 'Critique',
    };
    return labels[urgence] || urgence;
  }

  getStatutLabel(statut: string): string {
    const labels: Record<string, string> = {
      brouillon: 'Brouillon',
      soumis: 'Soumis',
      en_cours: 'En cours',
      resolu: 'Resolu',
      classe: 'Classe',
    };
    return labels[statut] || statut;
  }

  getUrgenceBadgeVariant(urgence: string): 'default' | 'secondary' | 'destructive' | 'outline' {
    switch (urgence) {
      case 'critique':
        return 'destructive';
      case 'eleve':
        return 'default';
      case 'moyen':
        return 'secondary';
      default:
        return 'outline';
    }
  }

  getStatutBadgeVariant(statut: string): 'default' | 'secondary' | 'destructive' | 'outline' {
    switch (statut) {
      case 'resolu':
        return 'default';
      case 'en_cours':
        return 'secondary';
      case 'soumis':
        return 'outline';
      case 'classe':
        return 'secondary';
      default:
        return 'outline';
    }
  }
}

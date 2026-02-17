import { Component, OnInit, OnDestroy, ElementRef, ViewChild, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import {
  CardComponent,
  CardHeaderComponent,
  CardTitleComponent,
  CardDescriptionComponent,
  CardContentComponent,
} from '../../components/ui/card.component';
import { BadgeComponent } from '../../components/ui/badge.component';
import {
  TableComponent,
  TableHeaderComponent,
  TableBodyComponent,
  TableRowComponent,
  TableHeadComponent,
  TableCellComponent,
} from '../../components/ui/table.component';
import { ApiService } from '../../services/api.service';
import { Stats } from '../../models/stats.model';
import { GlobeComponent } from '../../three/globe.component';
import { StatsChartComponent } from '../../three/stats-chart.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    CardComponent,
    CardHeaderComponent,
    CardTitleComponent,
    CardDescriptionComponent,
    CardContentComponent,
    BadgeComponent,
    TableComponent,
    TableHeaderComponent,
    TableBodyComponent,
    TableRowComponent,
    TableHeadComponent,
    TableCellComponent,
    GlobeComponent,
    StatsChartComponent,
  ],
  template: `
    <div class="space-y-6">
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <ui-card>
          <ui-card-header className="pb-2">
            <ui-card-description>Total signalements</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="text-3xl font-bold">{{ stats?.total || 0 }}</div>
          </ui-card-content>
        </ui-card>

        <ui-card>
          <ui-card-header className="pb-2">
            <ui-card-description>En cours</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="text-3xl font-bold text-blue-600">{{ getStatutCount('en_cours') }}</div>
          </ui-card-content>
        </ui-card>

        <ui-card>
          <ui-card-header className="pb-2">
            <ui-card-description>Resolus</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="text-3xl font-bold text-green-600">{{ getStatutCount('resolu') }}</div>
          </ui-card-content>
        </ui-card>

        <ui-card>
          <ui-card-header className="pb-2">
            <ui-card-description>Critiques</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="text-3xl font-bold text-red-600">{{ getUrgenceCount('critique') }}</div>
          </ui-card-content>
        </ui-card>
      </div>

      <!-- Globe and Chart Row -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ui-card>
          <ui-card-header>
            <ui-card-title>Globe des signalements</ui-card-title>
            <ui-card-description>Visualisation geographique des incidents</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="h-[350px] w-full" #globeContainer>
              <app-globe [markers]="crimeMarkers" />
            </div>
          </ui-card-content>
        </ui-card>

        <ui-card>
          <ui-card-header>
            <ui-card-title>Repartition par type</ui-card-title>
            <ui-card-description>Distribution des crimes par categorie</ui-card-description>
          </ui-card-header>
          <ui-card-content>
            <div class="h-[350px] w-full">
              <app-stats-chart [data]="chartData" />
            </div>
          </ui-card-content>
        </ui-card>
      </div>

      <!-- Recent Reports Table -->
      <ui-card>
        <ui-card-header>
          <ui-card-title>Signalements recents</ui-card-title>
          <ui-card-description>Les derniers signalements soumis</ui-card-description>
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
              </ui-table-row>
            </ui-table-header>
            <ui-table-body>
              @for (report of stats?.recents || []; track report.id) {
                <ui-table-row>
                  <ui-table-cell>{{ report.createdAt | date: 'dd/MM/yyyy' }}</ui-table-cell>
                  <ui-table-cell>{{ report.titre }}</ui-table-cell>
                  <ui-table-cell>{{ report.typeCrime }}</ui-table-cell>
                  <ui-table-cell>
                    <ui-badge [variant]="getUrgenceBadgeVariant(report.urgence)">
                      {{ report.urgence }}
                    </ui-badge>
                  </ui-table-cell>
                  <ui-table-cell>
                    <ui-badge [variant]="getStatutBadgeVariant(report.statut)">
                      {{ report.statut }}
                    </ui-badge>
                  </ui-table-cell>
                </ui-table-row>
              }
              @if (!stats?.recents?.length) {
                <ui-table-row>
                  <ui-table-cell>
                    <div class="text-center text-muted-foreground py-8 col-span-5">
                      Aucun signalement pour le moment
                    </div>
                  </ui-table-cell>
                </ui-table-row>
              }
            </ui-table-body>
          </ui-table>
        </ui-card-content>
      </ui-card>
    </div>
  `,
})
export class DashboardComponent implements OnInit {
  stats: Stats | null = null;
  crimeMarkers: { lat: number; lng: number; label: string }[] = [];
  chartData: { label: string; value: number; color: string }[] = [];

  private chartColors = ['#3b82f6', '#ef4444', '#f59e0b', '#10b981', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.loadStats();
  }

  loadStats(): void {
    this.apiService.getStats().subscribe({
      next: (stats) => {
        this.stats = stats;
        this.buildMarkers(stats);
        this.buildChartData(stats);
      },
      error: () => {
        // Use mock data for demonstration
        this.stats = {
          total: 42,
          parType: [
            { typeCrime: 'Vol', count: 15 },
            { typeCrime: 'Agression', count: 8 },
            { typeCrime: 'Vandalisme', count: 7 },
            { typeCrime: 'Cambriolage', count: 6 },
            { typeCrime: 'Fraude', count: 4 },
            { typeCrime: 'Autre', count: 2 },
          ],
          parUrgence: [
            { urgence: 'faible', count: 10 },
            { urgence: 'moyen', count: 15 },
            { urgence: 'eleve', count: 12 },
            { urgence: 'critique', count: 5 },
          ],
          parStatut: [
            { statut: 'soumis', count: 12 },
            { statut: 'en_cours', count: 18 },
            { statut: 'resolu', count: 8 },
            { statut: 'classe', count: 4 },
          ],
          parMois: [],
          recents: [
            { id: 1, titre: 'Vol de vehicule', typeCrime: 'Vol', urgence: 'eleve', statut: 'en_cours', createdAt: '2026-02-15T10:00:00Z' },
            { id: 2, titre: 'Cambriolage appartement', typeCrime: 'Cambriolage', urgence: 'critique', statut: 'soumis', createdAt: '2026-02-14T14:30:00Z' },
            { id: 3, titre: 'Vandalisme parking', typeCrime: 'Vandalisme', urgence: 'moyen', statut: 'resolu', createdAt: '2026-02-13T09:15:00Z' },
          ],
        };
        this.buildMarkers(this.stats);
        this.buildChartData(this.stats);
      },
    });
  }

  private buildMarkers(stats: Stats): void {
    this.crimeMarkers = (stats.recents || [])
      .filter((r: any) => r.latitude && r.longitude)
      .map((r: any) => ({
        lat: r.latitude,
        lng: r.longitude,
        label: r.titre,
      }));

    if (this.crimeMarkers.length === 0) {
      // Default markers for France
      this.crimeMarkers = [
        { lat: 48.8566, lng: 2.3522, label: 'Paris' },
        { lat: 43.2965, lng: 5.3698, label: 'Marseille' },
        { lat: 45.764, lng: 4.8357, label: 'Lyon' },
        { lat: 43.6047, lng: 1.4442, label: 'Toulouse' },
        { lat: 48.5734, lng: 7.7521, label: 'Strasbourg' },
      ];
    }
  }

  private buildChartData(stats: Stats): void {
    this.chartData = (stats.parType || []).map((item, i) => ({
      label: item.typeCrime,
      value: item.count,
      color: this.chartColors[i % this.chartColors.length],
    }));
  }

  getStatutCount(statut: string): number {
    const item = this.stats?.parStatut?.find((s) => s.statut === statut);
    return item?.count || 0;
  }

  getUrgenceCount(urgence: string): number {
    const item = this.stats?.parUrgence?.find((u) => u.urgence === urgence);
    return item?.count || 0;
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

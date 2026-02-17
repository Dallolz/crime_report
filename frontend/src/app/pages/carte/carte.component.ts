import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GlobeComponent } from '../../three/globe.component';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-carte',
  standalone: true,
  imports: [CommonModule, GlobeComponent],
  template: `
    <div class="h-[calc(100vh-8rem)] w-full rounded-lg border bg-card overflow-hidden">
      <app-globe [markers]="markers" />
    </div>
  `,
})
export class CarteComponent implements OnInit {
  markers: { lat: number; lng: number; label: string }[] = [];

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.apiService.getReports().subscribe({
      next: (reports) => {
        this.markers = reports
          .filter((r) => r.latitude && r.longitude)
          .map((r) => ({
            lat: r.latitude!,
            lng: r.longitude!,
            label: r.titre,
          }));
        if (this.markers.length === 0) {
          this.setDefaultMarkers();
        }
      },
      error: () => {
        this.setDefaultMarkers();
      },
    });
  }

  private setDefaultMarkers(): void {
    this.markers = [
      { lat: 48.8566, lng: 2.3522, label: 'Paris - Vol signale' },
      { lat: 43.2965, lng: 5.3698, label: 'Marseille - Agression signalée' },
      { lat: 45.764, lng: 4.8357, label: 'Lyon - Vandalisme' },
      { lat: 43.6047, lng: 1.4442, label: 'Toulouse - Cambriolage' },
      { lat: 48.5734, lng: 7.7521, label: 'Strasbourg - Fraude' },
      { lat: 47.2184, lng: -1.5536, label: 'Nantes - Vol' },
      { lat: 44.8378, lng: -0.5792, label: 'Bordeaux - Violence' },
      { lat: 43.7102, lng: 7.262, label: 'Nice - Trafic' },
    ];
  }
}

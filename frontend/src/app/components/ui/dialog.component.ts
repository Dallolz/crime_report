import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'ui-dialog',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (open) {
      <div class="fixed inset-0 z-50 flex items-center justify-center">
        <div
          class="fixed inset-0 bg-black/80 animate-fade-in"
          (click)="onClose()"
        ></div>
        <div
          class="relative z-50 w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-lg border bg-background p-6 shadow-lg animate-scale-in"
        >
          @if (title) {
            <div class="mb-4">
              <h2 class="text-lg font-semibold leading-none tracking-tight">{{ title }}</h2>
              @if (description) {
                <p class="text-sm text-muted-foreground mt-1.5">{{ description }}</p>
              }
            </div>
          }
          <ng-content />
          <button
            (click)="onClose()"
            class="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M18 6 6 18"/><path d="m6 6 12 12"/>
            </svg>
          </button>
        </div>
      </div>
    }
  `,
  styles: [
    `
      @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      @keyframes scaleIn {
        from { opacity: 0; transform: scale(0.95); }
        to { opacity: 1; transform: scale(1); }
      }
      .animate-fade-in {
        animation: fadeIn 0.15s ease-out;
      }
      .animate-scale-in {
        animation: scaleIn 0.15s ease-out;
      }
    `,
  ],
})
export class DialogComponent {
  @Input() open = false;
  @Input() title = '';
  @Input() description = '';
  @Output() openChange = new EventEmitter<boolean>();

  onClose(): void {
    this.open = false;
    this.openChange.emit(false);
  }
}

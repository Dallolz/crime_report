import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'ui-card',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="'rounded-lg border bg-card text-card-foreground shadow-sm ' + className">
      <ng-content />
    </div>
  `,
})
export class CardComponent {
  @Input() className = '';
}

@Component({
  selector: 'ui-card-header',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="'flex flex-col space-y-1.5 p-6 ' + className">
      <ng-content />
    </div>
  `,
})
export class CardHeaderComponent {
  @Input() className = '';
}

@Component({
  selector: 'ui-card-title',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h3 [class]="'text-2xl font-semibold leading-none tracking-tight ' + className">
      <ng-content />
    </h3>
  `,
})
export class CardTitleComponent {
  @Input() className = '';
}

@Component({
  selector: 'ui-card-description',
  standalone: true,
  imports: [CommonModule],
  template: `
    <p [class]="'text-sm text-muted-foreground ' + className">
      <ng-content />
    </p>
  `,
})
export class CardDescriptionComponent {
  @Input() className = '';
}

@Component({
  selector: 'ui-card-content',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="'p-6 pt-0 ' + className">
      <ng-content />
    </div>
  `,
})
export class CardContentComponent {
  @Input() className = '';
}

@Component({
  selector: 'ui-card-footer',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="'flex items-center p-6 pt-0 ' + className">
      <ng-content />
    </div>
  `,
})
export class CardFooterComponent {
  @Input() className = '';
}

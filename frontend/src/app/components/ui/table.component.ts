import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'ui-table',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="relative w-full overflow-auto">
      <table class="w-full caption-bottom text-sm">
        <ng-content />
      </table>
    </div>
  `,
})
export class TableComponent {}

@Component({
  selector: 'ui-table-header',
  standalone: true,
  imports: [CommonModule],
  template: `
    <thead class="[&_tr]:border-b">
      <ng-content />
    </thead>
  `,
})
export class TableHeaderComponent {}

@Component({
  selector: 'ui-table-body',
  standalone: true,
  imports: [CommonModule],
  template: `
    <tbody class="[&_tr:last-child]:border-0">
      <ng-content />
    </tbody>
  `,
})
export class TableBodyComponent {}

@Component({
  selector: 'ui-table-row',
  standalone: true,
  imports: [CommonModule],
  template: `
    <tr class="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
      <ng-content />
    </tr>
  `,
})
export class TableRowComponent {}

@Component({
  selector: 'ui-table-head',
  standalone: true,
  imports: [CommonModule],
  template: `
    <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0">
      <ng-content />
    </th>
  `,
})
export class TableHeadComponent {}

@Component({
  selector: 'ui-table-cell',
  standalone: true,
  imports: [CommonModule],
  template: `
    <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
      <ng-content />
    </td>
  `,
})
export class TableCellComponent {}

import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Report, CreateReport } from '../models/report.model';
import { CrimeCategory } from '../models/crime-category.model';
import { Stats } from '../models/stats.model';

@Injectable({
  providedIn: 'root',
})
export class ApiService {
  private readonly baseUrl = 'http://localhost:3000/api';

  constructor(private http: HttpClient) {}

  private getHeaders(): HttpHeaders {
    const token = localStorage.getItem('access_token');
    let headers = new HttpHeaders({ 'Content-Type': 'application/json' });
    if (token) {
      headers = headers.set('Authorization', `Bearer ${token}`);
    }
    return headers;
  }

  getReports(filters?: Record<string, string>): Observable<Report[]> {
    let params = new HttpParams();
    if (filters) {
      Object.keys(filters).forEach((key) => {
        if (filters[key]) {
          params = params.set(key, filters[key]);
        }
      });
    }
    return this.http.get<Report[]>(`${this.baseUrl}/reports`, {
      headers: this.getHeaders(),
      params,
    });
  }

  getReport(id: number): Observable<Report> {
    return this.http.get<Report>(`${this.baseUrl}/reports/${id}`, {
      headers: this.getHeaders(),
    });
  }

  createReport(data: CreateReport): Observable<Report> {
    return this.http.post<Report>(`${this.baseUrl}/reports`, data, {
      headers: this.getHeaders(),
    });
  }

  updateReport(id: number, data: Partial<Report>): Observable<Report> {
    return this.http.patch<Report>(`${this.baseUrl}/reports/${id}`, data, {
      headers: this.getHeaders(),
    });
  }

  deleteReport(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/reports/${id}`, {
      headers: this.getHeaders(),
    });
  }

  getCategories(): Observable<CrimeCategory[]> {
    return this.http.get<CrimeCategory[]>(`${this.baseUrl}/crimes/categories`, {
      headers: this.getHeaders(),
    });
  }

  getStats(): Observable<Stats> {
    return this.http.get<Stats>(`${this.baseUrl}/stats`, {
      headers: this.getHeaders(),
    });
  }
}

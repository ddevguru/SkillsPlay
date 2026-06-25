/// <reference types="vite/client" />
// GCP VM backend — .env se override ho sakta hai (VITE_API_URL)
const API_URL = import.meta.env.VITE_API_URL || 'http://35.200.216.188:3000';

function getToken() {
  return localStorage.getItem('admin_token');
}

export { getToken };

export function setToken(token: string) {
  localStorage.setItem('admin_token', token);
}

export function clearToken() {
  localStorage.removeItem('admin_token');
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_URL}${path}`, { ...options, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error || 'Request failed');
  }
  return res.json();
}

export const api = {
  login: (email: string, password: string) =>
    request<{ accessToken: string; user: { role: string } }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  getAnalytics: () => request<Record<string, unknown>>('/admin/analytics'),
  getUsers: (page = 1) => request<{ users: User[]; total: number }>(`/admin/users?page=${page}&limit=20`),
  banUser: (id: string, banned: boolean) =>
    request(`/admin/user/${id}/ban`, { method: 'PUT', body: JSON.stringify({ banned }) }),
  setCredits: (id: string, trackId: string, remaining: number) =>
    request(`/admin/user/${id}/credits`, { method: 'PUT', body: JSON.stringify({ trackId, remaining }) }),
  getAuditLog: () => request<AuditEntry[]>('/admin/audit-log'),
  getTracks: () => request<Track[]>('/tracks?include=topics'),
  createLesson: (data: Record<string, unknown>) =>
    request('/admin/lessons', { method: 'POST', body: JSON.stringify(data) }),
};

export interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  subscriptionStatus: string;
  xp: number;
  isBanned: boolean;
  createdAt: string;
}

export interface Track {
  id: string;
  slug: string;
  title: string;
  topics?: { id: string; title: string; slug: string }[];
}

export interface AuditEntry {
  id: string;
  action: string;
  target: string;
  timestamp: string;
  admin: { name: string; email: string };
}

// Thin fetch wrapper: attaches the JWT from localStorage to every call,
// and redirects to /login on a 401 so stale sessions don't hang around.
const BASE = '/api';

export function getToken() {
  return localStorage.getItem('ucjims_token');
}

export function setSession(token, user) {
  localStorage.setItem('ucjims_token', token);
  localStorage.setItem('ucjims_user', JSON.stringify(user));
}

export function getUser() {
  const raw = localStorage.getItem('ucjims_user');
  return raw ? JSON.parse(raw) : null;
}

export function clearSession() {
  localStorage.removeItem('ucjims_token');
  localStorage.removeItem('ucjims_user');
}

export async function apiFetch(path, options = {}) {
  const token = getToken();
  const res = await fetch(BASE + path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    clearSession();
    window.location.href = '/login';
    throw new Error('Session expired');
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `Request failed (${res.status})`);
  }
  return data;
}

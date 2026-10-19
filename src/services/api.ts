import type { Appointment, Dashboard, ExercisePlan, PainEntry, User } from "../types";

const apiUrl = import.meta.env.VITE_API_URL ?? "http://localhost:5080";
const tokenKey = "revalinow-token";

export class ApiError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = "ApiError";
  }
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem(tokenKey);
  let response: Response;
  try {
    response = await fetch(`${apiUrl}${path}`, {
      ...init,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...init.headers,
      },
    });
  } catch {
    throw new ApiError("De RevaliNow-server is niet bereikbaar. Controleer of de API actief is.");
  }

  if (!response.ok) {
    const problem = await response.json().catch(() => null) as { title?: string; detail?: string } | null;
    throw new ApiError(problem?.detail ?? problem?.title ?? "De aanvraag is mislukt.", response.status);
  }

  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export async function login(username: string, password: string): Promise<User> {
  const result = await request<{ token: string; user: User }>("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ username, password }),
  });
  localStorage.setItem(tokenKey, result.token);
  return result.user;
}

export function getCurrentUser(): Promise<User> {
  return request("/api/auth/me");
}

export function logout(): void {
  localStorage.removeItem(tokenKey);
}

export function getDashboard(): Promise<Dashboard> {
  return request("/api/patient/dashboard");
}

export function getPlans(): Promise<ExercisePlan[]> {
  return request("/api/patient/plans");
}

export function getAppointments(): Promise<Appointment[]> {
  return request("/api/patient/appointments");
}

export function getPainEntries(): Promise<PainEntry[]> {
  return request("/api/patient/pain-entries");
}

export function createPainEntry(painScore: number, notes: string): Promise<PainEntry> {
  return request("/api/patient/pain-entries", {
    method: "POST",
    body: JSON.stringify({ painScore, notes }),
  });
}

export function completeExercise(exercisePlanId: number): Promise<void> {
  return request(`/api/patient/plans/${exercisePlanId}/complete`, { method: "POST" });
}

export const session = {
  tokenKey,
  isAuthenticated: () => Boolean(localStorage.getItem(tokenKey)),
};

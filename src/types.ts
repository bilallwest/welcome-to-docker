export interface User {
  userId: number;
  patientId: number;
  username: string;
  firstName: string;
  lastName: string;
  role: string;
}

export interface ExercisePlan {
  exercisePlanId: number;
  name: string;
  description: string;
  startDate: string;
  endDate: string;
  repetitions: number;
  sets: number;
  frequencyPerDay: number;
  completedToday: boolean;
  remarks?: string;
}

export interface Appointment {
  appointmentId: number;
  appointmentAt: string;
  durationMinutes: number;
  type: string;
  status: string;
  physicianName: string;
}

export interface PainEntry {
  painEntryId: number;
  recordedAt: string;
  painScore: number;
  notes: string;
}

export interface Dashboard {
  user: User;
  plans: ExercisePlan[];
  nextAppointment: Appointment | null;
  recentPainEntries: PainEntry[];
}

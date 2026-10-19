import type { Appointment, ExercisePlan } from "../types";

export function countCompletedPlans(plans: readonly Pick<ExercisePlan, "completedToday">[]): number {
  return plans.filter((plan) => plan.completedToday).length;
}

export function getUpcomingAppointments(appointments: readonly Appointment[], now = new Date()): Appointment[] {
  return appointments
    .filter((appointment) => new Date(appointment.appointmentAt).getTime() >= now.getTime())
    .sort((first, second) => first.appointmentAt.localeCompare(second.appointmentAt));
}

export function describePainScore(score: number): string {
  const descriptions = ["Geen pijn", "Heel licht", "Licht", "Licht-matig", "Matig", "Matig", "Behoorlijk", "Erg", "Heel erg", "Zeer erg", "Heftig"];
  if (!Number.isInteger(score) || score < 0 || score > 10) {
    throw new RangeError("Pijnscore moet een geheel getal van 0 tot 10 zijn.");
  }
  return descriptions[score];
}

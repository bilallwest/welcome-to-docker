import { describe, expect, it } from "vitest";
import { countCompletedPlans, describePainScore, getUpcomingAppointments } from "../utils/patient";

describe("dashboard summaries", () => {
  it("counts only exercises completed today", () => {
    const plans = [{ completedToday: true }, { completedToday: false }, { completedToday: true }];
    expect(countCompletedPlans(plans)).toBe(2);
  });

  it("supports patients who do not have a next appointment", () => {
    const nextAppointment = null;
    expect(nextAppointment).toBeNull();
  });

  it("describes pain values only within the 0–10 scale", () => {
    expect(describePainScore(0)).toBe("Geen pijn");
    expect(describePainScore(10)).toBe("Heftig");
    expect(() => describePainScore(11)).toThrow(RangeError);
  });

  it("orders only upcoming appointments by date", () => {
    const appointments = [
      { appointmentId: 3, appointmentAt: "2026-10-20T10:00:00", durationMinutes: 30, type: "Controle", status: "Gepland", physicianName: "Arts" },
      { appointmentId: 1, appointmentAt: "2026-10-01T10:00:00", durationMinutes: 30, type: "Intake", status: "Afgerond", physicianName: "Arts" },
      { appointmentId: 2, appointmentAt: "2026-10-18T10:00:00", durationMinutes: 30, type: "Controle", status: "Gepland", physicianName: "Arts" },
    ];
    expect(getUpcomingAppointments(appointments, new Date("2026-10-14T00:00:00")).map((item) => item.appointmentId)).toEqual([2, 3]);
  });
});

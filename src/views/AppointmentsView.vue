<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { getAppointments } from "../services/api";
import type { Appointment } from "../types";
import { getUpcomingAppointments } from "../utils/patient";

const appointments = ref<Appointment[]>([]);
const loading = ref(true);
const error = ref("");
const upcoming = computed(() => getUpcomingAppointments(appointments.value));
const past = computed(() => appointments.value.filter((item) => new Date(item.appointmentAt) < new Date()).sort((a, b) => b.appointmentAt.localeCompare(a.appointmentAt)));
function dateParts(value: string) {
  const date = new Date(value);
  return { day: date.toLocaleDateString("nl-NL", { day: "2-digit" }), month: date.toLocaleDateString("nl-NL", { month: "short" }).toUpperCase(), weekday: date.toLocaleDateString("nl-NL", { weekday: "long" }) };
}
onMounted(async () => {
  try { appointments.value = await getAppointments(); }
  catch (cause) { error.value = cause instanceof Error ? cause.message : "Afspraken laden is niet gelukt."; }
  finally { loading.value = false; }
});
</script>

<template>
  <div class="page-content">
    <div class="page-intro"><div><span class="eyebrow">SAMEN WERKEN AAN HERSTEL</span><h2>Momenten voor jou.</h2><p>Een overzicht van je afspraken en contactmomenten.</p></div><span class="intro-icon"><i class="bi bi-calendar2-heart"></i></span></div>
    <div v-if="error" class="alert alert-warning" role="alert">{{ error }}</div>
    <div v-if="loading" class="loading-panel">Je afspraken worden opgehaald...</div>
    <template v-else>
      <section class="appointment-section"><span class="eyebrow">WAT ER AANKOMT</span><h2 class="list-title">Aankomende afspraken</h2>
        <article v-for="appointment in upcoming" :key="appointment.appointmentId" class="surface-card appointment-list-card">
          <div class="appointment-date-block"><span>{{ dateParts(appointment.appointmentAt).month }}</span><strong>{{ dateParts(appointment.appointmentAt).day }}</strong></div>
          <div class="appointment-list-copy"><span class="eyebrow">{{ dateParts(appointment.appointmentAt).weekday }}</span><h3>{{ appointment.type }}</h3><p><i class="bi bi-clock"></i>{{ new Date(appointment.appointmentAt).toLocaleTimeString("nl-NL", { hour: "2-digit", minute: "2-digit" }) }} · {{ appointment.durationMinutes }} minuten <span>·</span> <i class="bi bi-person"></i>{{ appointment.physicianName }}</p></div>
          <span class="appointment-tag">{{ appointment.status }}</span>
        </article>
        <div v-if="!upcoming.length" class="surface-card empty-large"><i class="bi bi-calendar2"></i><h3>Er staat nog niets in je agenda</h3><p>Er zijn geen toekomstige afspraken bekend. Neem contact op met je zorgverlener als je een afspraak wilt maken.</p></div>
      </section>
      <section v-if="past.length" class="appointment-section past-section"><span class="eyebrow">AL GEWEEST</span><h2 class="list-title">Eerdere afspraken</h2>
        <article v-for="appointment in past.slice(0, 6)" :key="appointment.appointmentId" class="surface-card appointment-list-card past-appointment">
          <div class="appointment-date-block"><span>{{ dateParts(appointment.appointmentAt).month }}</span><strong>{{ dateParts(appointment.appointmentAt).day }}</strong></div>
          <div class="appointment-list-copy"><span class="eyebrow">{{ dateParts(appointment.appointmentAt).weekday }}</span><h3>{{ appointment.type }}</h3><p><i class="bi bi-clock"></i>{{ new Date(appointment.appointmentAt).toLocaleTimeString("nl-NL", { hour: "2-digit", minute: "2-digit" }) }} · {{ appointment.durationMinutes }} minuten <span>·</span> <i class="bi bi-person"></i>{{ appointment.physicianName }}</p></div>
          <span class="appointment-tag past-tag">{{ appointment.status }}</span>
        </article>
      </section>
    </template>
  </div>
</template>

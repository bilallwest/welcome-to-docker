<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import { Line } from "vue-chartjs";
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler, type ChartOptions } from "chart.js";
import { getDashboard, ApiError } from "../services/api";
import type { Dashboard } from "../types";
import { countCompletedPlans } from "../utils/patient";
import StatCard from "../components/StatCard.vue";
import SectionHeading from "../components/SectionHeading.vue";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler);
const dashboard = ref<Dashboard | null>(null);
const error = ref("");
const loading = ref(true);
const asOf = new Date();
const greeting = computed(() => {
  const hour = new Date().getHours();
  return hour < 12 ? "Goedemorgen" : hour < 18 ? "Goedemiddag" : "Goedenavond";
});
const completed = computed(() => countCompletedPlans(dashboard.value?.plans ?? []));
const total = computed(() => dashboard.value?.plans.length ?? 0);
const chartData = computed(() => {
  const rows = [...(dashboard.value?.recentPainEntries ?? [])].reverse().slice(-7);
  return {
    labels: rows.map((entry) => new Date(entry.recordedAt).toLocaleDateString("nl-NL", { day: "numeric", month: "short" })),
    datasets: [{
      data: rows.map((entry) => entry.painScore),
      borderColor: "#32735f",
      backgroundColor: (context: { chart: { ctx: CanvasRenderingContext2D; chartArea?: { top: number; bottom: number } } }) => {
        const { ctx, chartArea } = context.chart;
        if (!chartArea) return "rgba(50,115,95,.08)";
        const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
        gradient.addColorStop(0, "rgba(50,115,95,.2)");
        gradient.addColorStop(1, "rgba(50,115,95,0)");
        return gradient;
      },
      fill: true,
      tension: 0.4,
      pointRadius: 4,
      pointHoverRadius: 6,
      pointBackgroundColor: "#fff",
      pointBorderColor: "#32735f",
      pointBorderWidth: 2,
    }],
  };
});
const chartOptions: ChartOptions<"line"> = {
  responsive: true, maintainAspectRatio: false,
  plugins: { legend: { display: false }, tooltip: { displayColors: false, callbacks: { label: (context) => ` Pijnscore: ${context.parsed.y ?? 0}/10` } } },
  scales: {
    y: { min: 0, max: 10, ticks: { stepSize: 2, color: "#919b94" }, grid: { color: "#edf0ed" }, border: { display: false } },
    x: { ticks: { color: "#919b94" }, grid: { display: false }, border: { display: false } },
  },
};
const appointmentDate = computed(() => {
  const value = dashboard.value?.nextAppointment?.appointmentAt;
  return value ? new Date(value).toLocaleDateString("nl-NL", { weekday: "long", day: "numeric", month: "long" }) : "";
});
onMounted(async () => {
  try {
    dashboard.value = await getDashboard();
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : "Het overzicht kon niet worden geladen.";
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="page-content">
    <div class="welcome-row">
      <div><h2>{{ greeting }}, {{ dashboard?.user.firstName ?? "welkom" }} <span class="wave">✳</span></h2><p>Goed voor jezelf zorgen begint met één stap tegelijk.</p></div>
      <div class="date-pill"><i class="bi bi-calendar3"></i> {{ asOf.toLocaleDateString("nl-NL", { weekday: "long", day: "numeric", month: "long" }) }}</div>
    </div>
    <div v-if="loading" class="loading-panel"><span class="spinner-border spinner-border-sm"></span> Je overzicht wordt opgehaald...</div>
    <div v-else-if="error" class="alert alert-warning connection-alert" role="alert"><i class="bi bi-cloud-slash"></i><div><strong>Even geen verbinding</strong><span>{{ error }}</span></div></div>
    <template v-else-if="dashboard">
      <section class="stat-grid" aria-label="Jouw herstel in cijfers">
        <StatCard label="Oefeningen vandaag" :value="`${completed}/${total}`" detail="Elke herhaling telt" icon="bi-activity" tone="icon-green" />
        <StatCard label="Volgende afspraak" :value="dashboard.nextAppointment ? new Date(dashboard.nextAppointment.appointmentAt).toLocaleTimeString('nl-NL', { hour: '2-digit', minute: '2-digit' }) : '—'" :detail="appointmentDate || 'Nog geen afspraak gepland'" icon="bi-calendar-check" tone="icon-peach" />
        <StatCard label="Laatste pijnscore" :value="dashboard.recentPainEntries[0] ? `${dashboard.recentPainEntries[0].painScore}/10` : '—'" detail="Hoe voel je je vandaag?" icon="bi-heart-pulse" tone="icon-lilac" />
        <StatCard label="Actief oefenplan" :value="total" detail="Op jouw herstel afgestemd" icon="bi-journal-check" tone="icon-blue" />
      </section>
      <section class="dashboard-grid">
        <article class="surface-card exercises-card">
          <SectionHeading eyebrow="KLEINE STAPPEN, GROOT VERSCHIL" title="Jouw oefeningen" action="Bekijk alles" @action="$router.push('/oefeningen')" />
          <div v-if="dashboard.plans.length" class="exercise-list">
            <div v-for="(plan, index) in dashboard.plans.slice(0, 3)" :key="plan.exercisePlanId" class="exercise-row">
              <span class="exercise-index">0{{ index + 1 }}</span>
              <span class="exercise-copy"><strong>{{ plan.name }}</strong><small>{{ plan.sets }} sets · {{ plan.repetitions }} herhalingen</small></span>
              <span class="exercise-state" :class="{ done: plan.completedToday }"><i :class="plan.completedToday ? 'bi bi-check2' : 'bi bi-circle'"></i>{{ plan.completedToday ? "Gedaan" : "Te doen" }}</span>
            </div>
          </div>
          <div v-else class="empty-state"><i class="bi bi-activity"></i><span>Er staan nog geen actieve oefeningen voor je klaar.</span></div>
          <RouterLink to="/oefeningen" class="card-bottom-link">Bekijk jouw oefenplan <i class="bi bi-arrow-right"></i></RouterLink>
        </article>
        <article class="surface-card appointment-card">
          <SectionHeading eyebrow="IN JE AGENDA" title="Volgende afspraak" />
          <template v-if="dashboard.nextAppointment">
            <div class="appointment-date-block"><span>{{ new Date(dashboard.nextAppointment.appointmentAt).toLocaleDateString('nl-NL', { month: 'short' }).toUpperCase() }}</span><strong>{{ new Date(dashboard.nextAppointment.appointmentAt).getDate() }}</strong></div>
            <div class="appointment-info"><strong>{{ dashboard.nextAppointment.type }}</strong><span><i class="bi bi-clock"></i>{{ new Date(dashboard.nextAppointment.appointmentAt).toLocaleTimeString('nl-NL', { hour: '2-digit', minute: '2-digit' }) }} · {{ dashboard.nextAppointment.durationMinutes }} min</span><span><i class="bi bi-person"></i>{{ dashboard.nextAppointment.physicianName }}</span></div>
            <div class="appointment-note"><i class="bi bi-info-circle"></i> Je afspraak is gepland. Je zorgverlener kijkt ernaar uit je te zien.</div>
          </template>
          <div v-else class="empty-state"><i class="bi bi-calendar2"></i><span>Je hebt nog geen afspraak gepland.</span></div>
          <RouterLink to="/afspraken" class="card-bottom-link">Alle afspraken <i class="bi bi-arrow-right"></i></RouterLink>
        </article>
      </section>
      <section class="dashboard-grid lower-grid">
        <article class="surface-card chart-card">
          <div class="chart-heading"><SectionHeading eyebrow="LUISTER NAAR JE LICHAAM" title="Hoe voel je je?" /><RouterLink to="/pijn" class="chart-add"><i class="bi bi-plus-lg"></i> Pijnscore noteren</RouterLink></div>
          <div v-if="dashboard.recentPainEntries.length" class="chart-wrap" role="img" aria-label="Grafiek van jouw pijnscores op een schaal van nul tot tien"><Line :data="chartData" :options="chartOptions" /></div>
          <div v-else class="empty-state chart-empty"><i class="bi bi-heart-pulse"></i><span>Je hebt nog geen pijnscores genoteerd.</span><RouterLink to="/pijn">Voeg je eerste meting toe</RouterLink></div>
          <div class="chart-legend"><span><i></i> Jouw pijnscore <small>van 0 (geen pijn) tot 10 (veel pijn)</small></span><RouterLink to="/pijn">Bekijk overzicht <i class="bi bi-arrow-right"></i></RouterLink></div>
        </article>
        <article class="encouragement-card"><span class="encouragement-icon"><i class="bi bi-brightness-high"></i></span><span class="eyebrow">EEN MOMENT VOOR JEZELF</span><h3>Herstel heeft<br />geen haast.</h3><p>Het gaat niet om hoe snel je gaat, maar dat je blijft bewegen in de richting die goed voelt.</p><span class="encouragement-mark">“</span><small>Vandaag is ook een mooie dag om opnieuw te beginnen.</small></article>
      </section>
    </template>
  </div>
</template>

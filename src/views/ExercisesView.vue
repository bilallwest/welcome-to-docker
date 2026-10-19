<script setup lang="ts">
import { onMounted, ref } from "vue";
import { completeExercise, getPlans } from "../services/api";
import type { ExercisePlan } from "../types";

const plans = ref<ExercisePlan[]>([]);
const loading = ref(true);
const error = ref("");
const busy = ref<number | null>(null);
async function load() {
  try { plans.value = await getPlans(); }
  catch (cause) { error.value = cause instanceof Error ? cause.message : "Oefeningen laden is niet gelukt."; }
  finally { loading.value = false; }
}
async function markDone(plan: ExercisePlan) {
  busy.value = plan.exercisePlanId;
  error.value = "";
  try {
    await completeExercise(plan.exercisePlanId);
    plan.completedToday = true;
  } catch (cause) { error.value = cause instanceof Error ? cause.message : "Oefening afvinken is niet gelukt."; }
  finally { busy.value = null; }
}
onMounted(load);
</script>

<template>
  <div class="page-content">
    <div class="page-intro"><div><span class="eyebrow">OP JOUW TEMPO</span><h2>Bewegen op jouw manier.</h2><p>Dit zijn de oefeningen die jouw zorgverlener voor je heeft klaargezet.</p></div><span class="intro-icon"><i class="bi bi-activity"></i></span></div>
    <div v-if="error" class="alert alert-warning" role="alert">{{ error }}</div>
    <div v-if="loading" class="loading-panel"><span class="spinner-border spinner-border-sm"></span> Je oefenplan wordt opgehaald...</div>
    <div v-else-if="plans.length" class="plan-list">
      <article v-for="(plan, index) in plans" :key="plan.exercisePlanId" class="surface-card plan-card">
        <span class="plan-number">0{{ index + 1 }}</span>
        <div class="plan-content"><div class="plan-title"><h3>{{ plan.name }}</h3><span class="plan-status" :class="{ done: plan.completedToday }">{{ plan.completedToday ? "Afgerond vandaag" : "Klaar wanneer jij dat bent" }}</span></div>
          <p>{{ plan.description || plan.remarks || "Een oefening die je helpt stap voor stap sterker te worden." }}</p>
          <div class="plan-facts"><span><i class="bi bi-arrow-repeat"></i>{{ plan.sets }} sets van {{ plan.repetitions }}</span><span><i class="bi bi-calendar2-check"></i>{{ plan.frequencyPerDay }}× per dag</span><span><i class="bi bi-calendar-range"></i>Tot {{ new Date(plan.endDate).toLocaleDateString("nl-NL") }}</span></div>
        </div>
        <button class="btn-primary plan-complete" :disabled="plan.completedToday || busy === plan.exercisePlanId" @click="markDone(plan)">{{ busy === plan.exercisePlanId ? "Opslaan..." : plan.completedToday ? "Gedaan" : "Afvinken" }} <i :class="plan.completedToday ? 'bi bi-check2' : 'bi bi-arrow-right'"></i></button>
      </article>
    </div>
    <div v-else-if="!loading" class="surface-card empty-large"><i class="bi bi-flower1"></i><h3>Er staat nog geen oefening klaar</h3><p>Wanneer je zorgverlener een oefenplan met je deelt, vind je het hier terug.</p></div>
  </div>
</template>

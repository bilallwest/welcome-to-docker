<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { createPainEntry, getPainEntries } from "../services/api";
import type { PainEntry } from "../types";
import { describePainScore } from "../utils/patient";

const entries = ref<PainEntry[]>([]);
const score = ref<number | null>(null);
const notes = ref("");
const saving = ref(false);
const loading = ref(true);
const error = ref("");
const success = ref("");
const sortedEntries = computed(() => [...entries.value].sort((a, b) => b.recordedAt.localeCompare(a.recordedAt)));
async function load() {
  try { entries.value = await getPainEntries(); }
  catch (cause) { error.value = cause instanceof Error ? cause.message : "Pijnmetingen laden is niet gelukt."; }
  finally { loading.value = false; }
}
async function save() {
  if (score.value === null) { error.value = "Kies eerst een pijnscore."; return; }
  saving.value = true; error.value = ""; success.value = "";
  try {
    const created = await createPainEntry(score.value, notes.value.trim());
    entries.value.unshift(created);
    notes.value = ""; score.value = null;
    success.value = "Je meting is opgeslagen. Dank je dat je even bij jezelf hebt ingecheckt.";
  } catch (cause) { error.value = cause instanceof Error ? cause.message : "Je meting opslaan is niet gelukt."; }
  finally { saving.value = false; }
}
onMounted(load);
</script>

<template>
  <div class="page-content pain-page">
    <div class="page-intro"><div><span class="eyebrow">EVEN BIJ JEZELF INCHECKEN</span><h2>Hoe voelt je lichaam?</h2><p>Er is geen goed of fout antwoord. Jouw ervaring telt.</p></div><span class="intro-icon pain-intro-icon"><i class="bi bi-heart-pulse"></i></span></div>
    <div v-if="error" class="alert alert-warning" role="alert">{{ error }}</div><div v-if="success" class="alert alert-success" role="status">{{ success }}</div>
    <div class="pain-layout">
      <section class="surface-card pain-form-card">
        <span class="eyebrow">NIEUWE METING</span><h3>Hoeveel pijn voel je nu?</h3><p class="form-hint">Kies een cijfer van 0 tot 10.</p>
        <div class="pain-scale" role="group" aria-label="Pijnscore van nul tot tien">
          <button v-for="value in 11" :key="value - 1" class="pain-score" :class="{ selected: score === value - 1, 'score-high': value > 7 }" :aria-pressed="score === value - 1" @click="score = value - 1">{{ value - 1 }}</button>
        </div>
        <div class="scale-labels"><span>0 · Geen pijn</span><span>10 · Ergst denkbare pijn</span></div>
        <div v-if="score !== null" class="selected-score"><span>{{ score }}</span><div><strong>{{ describePainScore(score) }}</strong><small>Dit is hoe jij je nu voelt.</small></div></div>
        <label for="pain-notes">Wil je er iets bij vertellen? <span>OPTIONEEL</span></label>
        <textarea id="pain-notes" v-model="notes" maxlength="500" rows="3" placeholder="Bijvoorbeeld: waar je pijn voelt of wat je hebt gedaan..."></textarea>
        <button class="btn-primary save-pain" :disabled="saving" @click="save">{{ saving ? "Opslaan..." : "Meting opslaan" }} <i class="bi bi-arrow-right"></i></button>
        <div class="privacy-hint"><i class="bi bi-lock"></i> Alleen jij en je behandelteam kunnen dit zien.</div>
      </section>
      <section class="surface-card pain-history-card">
        <div class="section-heading"><div><span class="eyebrow">JOUW VERHAAL</span><h2>Recente metingen</h2></div></div>
        <div v-if="loading" class="loading-panel">Metingen laden...</div>
        <div v-else-if="sortedEntries.length" class="pain-history">
          <article v-for="entry in sortedEntries.slice(0, 8)" :key="entry.painEntryId" class="pain-history-row"><span class="history-score" :class="{ 'history-score-high': entry.painScore >= 7 }">{{ entry.painScore }}</span><div><strong>{{ describePainScore(entry.painScore) }}</strong><small>{{ new Date(entry.recordedAt).toLocaleString("nl-NL", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) }}</small><p v-if="entry.notes">{{ entry.notes }}</p></div></article>
        </div>
        <div v-else class="empty-state"><i class="bi bi-journal-heart"></i><span>Je hebt nog geen metingen. Je eerste meting kan helpen patronen te herkennen.</span></div>
        <div class="history-note"><i class="bi bi-chat-heart"></i><span>Een dag met meer pijn betekent niet dat je achteruitgaat. Herstel kent pieken en dalen.</span></div>
      </section>
    </div>
  </div>
</template>

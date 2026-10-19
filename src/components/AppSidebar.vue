<script setup lang="ts">
import { RouterLink } from "vue-router";
import { useAuthStore } from "../stores/auth";

const auth = useAuthStore();
const links = [
  { to: "/", label: "Overzicht", icon: "bi-grid-1x2" },
  { to: "/oefeningen", label: "Mijn oefeningen", icon: "bi-activity" },
  { to: "/pijn", label: "Pijn bijhouden", icon: "bi-heart-pulse" },
  { to: "/afspraken", label: "Afspraken", icon: "bi-calendar2-week" },
];
</script>

<template>
  <aside class="sidebar">
    <RouterLink to="/" class="brand-lockup" aria-label="RevaliNow startpagina">
      <span class="brand-mark"><i class="bi bi-plus-lg"></i></span>
      <span class="brand-word">revali<span>now</span><small>REVALIDATIE MET AANDACHT</small></span>
    </RouterLink>
    <div class="sidebar-section-label">MENU</div>
    <nav class="sidebar-nav" aria-label="Hoofdnavigatie">
      <RouterLink v-for="link in links" :key="link.to" :to="link.to" class="nav-item" :aria-label="link.label" exact-active-class="active">
        <i :class="`bi ${link.icon}`"></i><span>{{ link.label }}</span><i v-if="link.to === '/pijn'" class="bi bi-chevron-right nav-chevron"></i>
      </RouterLink>
    </nav>
    <div class="sidebar-spacer"></div>
    <section class="recovery-card">
      <span class="recovery-icon"><i class="bi bi-sun"></i></span>
      <strong>Elke stap telt</strong>
      <p>Herstellen gaat niet in een rechte lijn. Wees trots op wat je al bereikt hebt.</p>
      <div class="recovery-sparkle" aria-hidden="true">✳</div>
    </section>
    <button class="sidebar-link" aria-label="Uitloggen" @click="auth.signOut()">
      <i class="bi bi-box-arrow-left"></i><span>Uitloggen</span>
    </button>
    <div class="sidebar-profile">
      <span class="avatar avatar-small">{{ auth.user?.firstName?.slice(0, 1) ?? "B" }}</span>
      <span><strong>{{ auth.user?.firstName }} {{ auth.user?.lastName }}</strong><small>Patiënt</small></span>
      <i class="bi bi-three-dots"></i>
    </div>
  </aside>
</template>

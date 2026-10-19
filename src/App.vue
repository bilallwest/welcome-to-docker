<script setup lang="ts">
import { computed, onMounted } from "vue";
import { RouterLink, RouterView, useRoute } from "vue-router";
import { useAuthStore } from "./stores/auth";
import LoginView from "./views/LoginView.vue";
import AppSidebar from "./components/AppSidebar.vue";

const auth = useAuthStore();
const route = useRoute();
const showLogin = computed(() => !auth.user);
const pageTitle = computed(() => String(route.meta.title ?? "Overzicht"));
const today = new Date();

onMounted(() => auth.restore());
</script>

<template>
  <div v-if="auth.restoring" class="loading-panel app-loading"><span class="spinner-border spinner-border-sm"></span> Je sessie wordt gecontroleerd...</div>
  <LoginView v-else-if="showLogin" />
  <div v-else class="app-shell">
    <AppSidebar />
    <main class="main-content">
      <header class="topbar">
        <div class="topbar-title">
          <span class="eyebrow">{{ today.toLocaleDateString("nl-NL", { weekday: "long", day: "numeric", month: "long", year: "numeric" }).toUpperCase() }}</span>
          <h1>{{ pageTitle }}</h1>
        </div>
        <div class="topbar-actions">
          <button class="icon-button notification-button" aria-label="Meldingen">
            <i class="bi bi-bell"></i><span class="notification-dot"></span>
          </button>
          <RouterLink to="/afspraken" class="user-chip">
            <span class="avatar">{{ auth.user?.firstName?.slice(0, 1) ?? "B" }}</span>
            <span class="user-chip-copy"><strong>{{ auth.user?.firstName }} {{ auth.user?.lastName }}</strong><small>Mijn account</small></span>
            <i class="bi bi-chevron-down"></i>
          </RouterLink>
        </div>
      </header>
      <RouterView />
      <footer class="app-footer">
        <span>© 2026 RevaliNow</span>
        <span>Jouw herstel, stap voor stap <i class="bi bi-heart-fill"></i></span>
        <RouterLink to="/afspraken">Hulp nodig?</RouterLink>
      </footer>
    </main>
  </div>
</template>

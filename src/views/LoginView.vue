<script setup lang="ts">
import { ref } from "vue";
import { useAuthStore } from "../stores/auth";

const auth = useAuthStore();
const username = ref("");
const password = ref("");
async function submit() {
  await auth.signIn(username.value, password.value);
}
</script>

<template>
  <main class="login-page">
    <section class="login-story">
      <div class="login-brand"><span class="brand-mark"><i class="bi bi-plus-lg"></i></span><span class="brand-word">revali<span>now</span></span></div>
      <div class="story-copy">
        <span class="eyebrow light-eyebrow">JOUW HERSTEL, JOUW TEMPO</span>
        <h1>Elke kleine stap<br />brengt je <em>verder.</em></h1>
        <p>Alles voor jouw revalidatie op één plek. We helpen je grip te krijgen op je herstel, met aandacht voor hoe jij je voelt.</p>
      </div>
      <div class="story-bottom"><span class="story-sun"><i class="bi bi-sun"></i></span><span>Een beetje vooruitgang<br />is óók vooruitgang.</span><span class="story-line"></span></div>
      <span class="story-decoration story-decoration-one"></span><span class="story-decoration story-decoration-two"></span>
    </section>
    <section class="login-panel">
      <div class="login-card">
        <span class="eyebrow">WELKOM TERUG</span>
        <h2>Fijn dat je er bent.</h2>
        <p class="login-description">Log in om verder te gaan met jouw herstel.</p>
        <form @submit.prevent="submit">
          <label for="username">Gebruikersnaam</label>
          <div class="input-wrap"><i class="bi bi-person"></i><input id="username" v-model="username" autocomplete="username" required placeholder="Bijvoorbeeld: patient3" /></div>
          <label for="password">Wachtwoord</label>
          <div class="input-wrap"><i class="bi bi-lock"></i><input id="password" v-model="password" autocomplete="current-password" required type="password" placeholder="Je wachtwoord" /></div>
          <button class="btn-primary w-100 login-submit" type="submit" :disabled="auth.loading">{{ auth.loading ? "Even geduld..." : "Inloggen" }} <i class="bi bi-arrow-right"></i></button>
          <div v-if="auth.error" class="alert alert-danger mt-3" role="alert">{{ auth.error }}</div>
        </form>
        <div class="login-help"><i class="bi bi-shield-check"></i><span>Jouw gegevens zijn veilig en alleen voor jou zichtbaar.</span></div>
        <p class="login-demo">Demo-account na het laden van de dataset: <strong>patient3</strong> · <strong>Welkom123!</strong></p>
      </div>
      <div class="login-footer">© 2026 RevaliNow <span>•</span> Met zorg gemaakt voor jouw herstel</div>
    </section>
  </main>
</template>

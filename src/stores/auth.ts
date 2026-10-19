import { defineStore } from "pinia";
import { getCurrentUser, login, logout, session } from "../services/api";
import type { User } from "../types";

export const useAuthStore = defineStore("auth", {
  state: () => ({ user: null as User | null, loading: false, restoring: true, error: "" }),
  actions: {
    async signIn(username: string, password: string) {
      this.loading = true;
      this.error = "";
      try {
        this.user = await login(username, password);
        this.restoring = false;
      } catch (error) {
        this.error = error instanceof Error ? error.message : "Inloggen is niet gelukt.";
      } finally {
        this.loading = false;
      }
    },
    signOut() {
      logout();
      this.user = null;
      this.restoring = false;
    },
    async restore() {
      if (!session.isAuthenticated()) {
        this.restoring = false;
        return;
      }
      try {
        this.user = await getCurrentUser();
      } catch (error) {
        logout();
        this.error = error instanceof Error ? error.message : "Je sessie kon niet worden hersteld.";
      } finally {
        this.restoring = false;
      }
    },
  },
});

import { createRouter, createWebHistory } from "vue-router";
import { session } from "./services/api";
import DashboardView from "./views/DashboardView.vue";
import ExercisesView from "./views/ExercisesView.vue";
import PainView from "./views/PainView.vue";
import AppointmentsView from "./views/AppointmentsView.vue";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", component: DashboardView, meta: { title: "Overzicht" } },
    { path: "/oefeningen", component: ExercisesView, meta: { title: "Mijn oefeningen" } },
    { path: "/pijn", component: PainView, meta: { title: "Pijn bijhouden" } },
    { path: "/afspraken", component: AppointmentsView, meta: { title: "Afspraken" } },
  ],
});

router.beforeEach((to) => {
  if (to.path !== "/" && !session.isAuthenticated()) return { path: "/" };
});

export default router;

<script setup lang="ts">
defineProps<{ label: string; value: string | number; detail: string; icon: string; tone: string }>();
</script>

<template>
  <article class="stat-card">
    <div class="stat-top"><span>{{ label }}</span><span class="stat-icon" :class="tone"><i :class="`bi ${icon}`"></i></span></div>
    <strong class="stat-value">{{ value }}</strong>
    <span class="stat-detail">{{ detail }}</span>
  </article>
</template>

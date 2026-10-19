<script setup lang="ts">
defineProps<{ eyebrow?: string; title: string; action?: string }>();
defineEmits<{ action: [] }>();
</script>

<template>
  <div class="section-heading">
    <div><span v-if="eyebrow" class="eyebrow">{{ eyebrow }}</span><h2>{{ title }}</h2></div>
    <button v-if="action" class="text-action" @click="$emit('action')">{{ action }} <i class="bi bi-arrow-right"></i></button>
  </div>
</template>

<!-- An Aby icon for Vue (Lucide, ISC licence). Colour follows the text colour.
     <AbyIcon name="banknote" />   <AbyIcon name="search" :size="20" label="Search" /> -->
<script setup lang="ts">
import { computed } from 'vue'
import data from './aby-icons.json'

const props = withDefaults(defineProps<{ name: string; size?: number | string; label?: string }>(), { size: 24 })
const body = computed(() => (data.icons as Record<string, string>)[props.name] ?? '')
</script>

<template>
  <svg
    :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor"
    stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
    :role="label ? 'img' : undefined" :aria-label="label" :aria-hidden="label ? undefined : 'true'"
    v-html="body"
  />
</template>

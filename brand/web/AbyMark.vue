<!-- The Aby mark for Vue. tone: "brand" (follows the theme), "reversed" (on midnight), "mono" (currentColor). -->
<script setup lang="ts">
withDefaults(defineProps<{ size?: number | string; tone?: 'brand' | 'reversed' | 'mono'; label?: string }>(), {
  size: 32,
  tone: 'brand',
  label: 'Aby',
})
</script>

<template>
  <svg :width="size" :height="size" viewBox="5.25 18 100 100" role="img" :aria-label="label">
    <path :fill="tone === 'mono' ? 'currentColor' : tone === 'reversed' ? 'var(--on-midnight, #f6f7f2)' : 'var(--ink, #101322)'" d="M44.78 30.86 A37.5 37.5 0 1 1 13.32 75.80 A10.5 10.5 0 0 1 33.86 71.43 A16.5 16.5 0 1 0 47.70 51.66 A10.5 10.5 0 0 1 44.78 30.86 Z M77 48.5 A10.5 10.5 0 0 1 98 48.5 L98 95.5 A10.5 10.5 0 0 1 77 95.5 Z" />
    <path :fill="tone === 'mono' ? 'currentColor' : 'var(--lime, #c8f560)'" d="M18.38 52.51 a9.5 9.5 0 1 0 19.0 0 a9.5 9.5 0 1 0 -19.0 0 Z" />
  </svg>
</template>

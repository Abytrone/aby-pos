// Tailwind CSS v3 preset. In tailwind.config.js:  presets: [require('./aby-tailwind-preset.js')]
// Also load ../tokens/aby-tokens.css once in your app (it defines the CSS variables used here).
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['variant', ['&:where([data-theme=dark], [data-theme=dark] *)', '&:where(.dark, .dark *)']],
  theme: {
    extend: {
      colors: {
        'surface': 'var(--surface)',
        'surface-raised': 'var(--surface-raised)',
        'surface-sunken': 'var(--surface-sunken)',
        'line': 'var(--line)',
        'line-strong': 'var(--line-strong)',
        'ink': 'var(--ink)',
        'ink-muted': 'var(--ink-muted)',
        'midnight': 'var(--midnight)',
        'on-midnight': 'var(--on-midnight)',
        'lime': 'var(--lime)',
        'on-lime': 'var(--on-lime)',
        'lime-soft': 'var(--lime-soft)',
        'lime-ink': 'var(--lime-ink)',
        'primary': 'var(--primary)',
        'on-primary': 'var(--on-primary)',
        'blue': 'var(--blue)',
        'blue-soft': 'var(--blue-soft)',
        'success': 'var(--success)',
        'success-soft': 'var(--success-soft)',
        'warning': 'var(--warning)',
        'warning-soft': 'var(--warning-soft)',
        'coral': 'var(--coral)',
        'danger': 'var(--danger)',
        'danger-soft': 'var(--danger-soft)',
        'link': 'var(--link)',
        'receipt-paper': 'var(--receipt-paper)',
        'receipt-ink': 'var(--receipt-ink)',
      },
      fontFamily: { sans: ['Figtree', 'system-ui', 'sans-serif'], display: ['Figtree', 'system-ui', 'sans-serif'], mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'] },
      borderRadius: { sm: '8px', md: '14px', lg: '24px' },
      fontSize: {
        display: ['56px', { lineHeight: '56px', fontWeight: '900', letterSpacing: '-0.035em' }],
        title: ['32px', { lineHeight: '36px', fontWeight: '800', letterSpacing: '-0.02em' }],
        total: ['44px', { lineHeight: '48px', fontWeight: '900', letterSpacing: '-0.03em' }],
      },
      boxShadow: { sm: 'var(--shadow-sm)', lg: 'var(--shadow-lg)', focus: 'var(--focus-ring)' },
      spacing: { tap: '48px', pos: '56px', tile: '112px' },
    },
  },
};

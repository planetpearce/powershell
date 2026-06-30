# Vue.js Project — Copilot Instructions
# TEMPLATE — copy to .github/copilot-instructions.md in any Vue/TypeScript project
# Replace all [PLACEHOLDER] values before committing.

## Project Overview
[Brief description of what this app does and who uses it.]

- **Framework**: Vue 3 with TypeScript
- **Build tool**: Vite
- **Package manager**: npm
- **CI/CD**: GitHub Actions

## Code Style

### Vue Components
- Use Composition API with `<script setup lang="ts">` — do not use Options API
- One component per file; filename matches the component name in PascalCase
- Keep components small and focused — extract sub-components early
- Props must be typed explicitly with `defineProps<{ ... }>()`
- Emits must be typed explicitly with `defineEmits<{ ... }>()`
- Use `ref()` for primitives, `reactive()` for objects only when the whole object is passed around
- Prefer `computed()` over watchers where possible

### TypeScript
- Strict mode is enabled — no `any` unless genuinely unavoidable
- Define interfaces/types in a `types/` or co-located `*.types.ts` file
- Avoid `!` non-null assertions; use optional chaining and nullish coalescing instead
- Use `readonly` on props and data that should not be mutated

### Naming
- Components: PascalCase (`UserCard.vue`)
- Composables: camelCase prefixed with `use` (`useOrderData.ts`)
- Event names: kebab-case (`@item-selected`)
- CSS classes: kebab-case

### State Management
[Describe approach — Pinia / Vuex / composables / props-down-emits-up — or delete this section.]

## Project Structure
```
src/
├── components/     # Reusable UI components
├── composables/    # Shared composition functions (use*.ts)
├── views/          # Route-level page components
├── types/          # Shared TypeScript interfaces and types
├── assets/         # Static assets (images, global CSS)
└── main.ts         # App entry point
```

## GitHub Actions
- CI workflow runs on every push to `main` and on all pull requests
- Pipeline steps: `npm ci` → `npm run type-check` → `npm run build`
- Do not skip type-check — fix type errors rather than suppressing them
- Deployment target: [Azure Static Web Apps / GitHub Pages / other — fill in]

## Common Commands
```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run type-check   # Run tsc without emitting
npm run lint         # ESLint
```

## Things to Avoid
- Do not use the Options API
- Do not use `var`
- Do not mutate props directly — emit an event instead
- Do not import from `src/` using relative `../../` paths — use path aliases (`@/`)

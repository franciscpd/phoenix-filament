# Phase 2: Component Library and Theming - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-01
**Phase:** 02-component-library-and-theming
**Areas discussed:** Component anatomy, Theming strategy, Modal & Portal, Component API style

---

## Component Anatomy

### Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| One per type | Each input type is its own component: text_input/1, textarea/1, etc. | ✓ |
| Unified input component | Single `<.input>` dispatches on `type` attr | |
| Hybrid approach | Both unified and individual components | |

**User's choice:** One per type
**Notes:** Maps 1:1 to %Field{} types from Phase 1. Clean, predictable API.

### Error States

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in error display | Each input auto-renders errors below field | ✓ |
| Separate error component | Developer adds `<.field_error>` explicitly | |
| Wrapper component | `<.form_field>` handles label + input + error | |

**User's choice:** Built-in error display
**Notes:** Developer doesn't need to add error markup.

### Non-input Components

| Option | Description | Selected |
|--------|-------------|----------|
| One per type | button/1, badge/1, card/1, modal/1 — each its own function component | ✓ |
| Grouped by domain | Separate components per variant: primary_button/1, danger_button/1 | |

**User's choice:** One per type

### Slots for Compound Components

| Option | Description | Selected |
|--------|-------------|----------|
| Named slots | Phoenix named slots (:header, :footer, :actions) | |
| Attrs + inner_block only | Flat API with title attr and inner_block | |
| Hybrid | Attrs for simple, named slots for complex | ✓ |

**User's choice:** Hybrid

### Interactive States

| Option | Description | Selected |
|--------|-------------|----------|
| Boolean attrs | `disabled` and `loading` boolean attrs | ✓ |
| State attr | Single `state` attr with :default, :disabled, :loading, :error | |

**User's choice:** Boolean attrs

### Accessibility

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in a11y | Auto-generate aria-label, aria-describedby, role | ✓ |
| Opt-in a11y | Provide attrs but don't auto-generate | |

**User's choice:** Built-in a11y

---

## Theming Strategy

### Default Themes

| Option | Description | Selected |
|--------|-------------|----------|
| Light + Dark only | One theme with light/dark mode | |
| Light + Dark + 2 presets | Plus "corporate" and "modern" variants | |
| daisyUI full palette | All 30+ daisyUI themes | ✓ |

**User's choice:** daisyUI full palette
**Notes:** Maximum choice for developers.

### Per-panel Customization

| Option | Description | Selected |
|--------|-------------|----------|
| CSS variable override | Panel declares theme name or CSS variable overrides | ✓ |
| Separate CSS file | Each panel points to its own CSS file | |
| Runtime theme switching | Theme switched at runtime via session | |

**User's choice:** CSS variable override

### Dark Mode Toggle

| Option | Description | Selected |
|--------|-------------|----------|
| Auto + manual toggle | OS preference default + optional toggle button | ✓ |
| OS preference only | Strictly follows prefers-color-scheme | |
| Manual only | Developer configures which theme | |

**User's choice:** Auto + manual toggle

### CSS Abstraction

| Option | Description | Selected |
|--------|-------------|----------|
| daisyUI direct | Components use daisyUI classes directly (btn, badge, etc.) | ✓ |
| Custom CSS layer | PhoenixFilament-prefixed classes mapping to daisyUI | |
| Tailwind utilities only | Raw Tailwind utilities, skip daisyUI | |

**User's choice:** daisyUI direct

### Class Construction

| Option | Description | Selected |
|--------|-------------|----------|
| Inline class lists | Phoenix built-in class list syntax with conditionals | ✓ |
| Class builder module | PhoenixFilament.CSS helper functions | |

**User's choice:** Inline class lists

---

## Modal & Portal

### Rendering Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView 1.1 Portals | Native portal feature, renders at DOM root | ✓ |
| JS.show/hide + fixed | LiveView JS commands with fixed positioning | |
| Teleport via hook | JS hook moves DOM to body | |

**User's choice:** LiveView 1.1 Portals
**Notes:** Zero JS, framework-native, no Alpine.js dependency.

### Stacking

| Option | Description | Selected |
|--------|-------------|----------|
| No stacking | One modal at a time | ✓ |
| Simple stacking | 2 levels (modal + confirmation) | |
| Full stacking | Unlimited with z-index management | |

**User's choice:** No stacking (v0.1)

### Open/Close Control

| Option | Description | Selected |
|--------|-------------|----------|
| show/on_cancel attrs | Boolean assign + event attr | ✓ |
| JS commands only | Pure JS.show/JS.hide | |
| ID-based API | Modal.show(id) / Modal.hide(id) | |

**User's choice:** show/on_cancel attrs

---

## Component API Style

### Import Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| use PhoenixFilament.Components | Single use imports all; selective import also available | ✓ |
| Module prefix required | Always use full module prefix | |
| Aliased short names | pf_ prefixed components | |

**User's choice:** use PhoenixFilament.Components

### Name Prefix

| Option | Description | Selected |
|--------|-------------|----------|
| No prefix | Short names: text_input, button, modal | ✓ |
| pf_ prefix | All prefixed: pf_text_input, pf_button | |
| Developer chooses | Optional prefix at import time | |

**User's choice:** No prefix

### Custom CSS

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, always | Every component accepts class attr | ✓ |
| No custom classes | Opinionated, no override | |
| rest attrs pass-through | @rest for any HTML attr | |

**User's choice:** Yes, always

---

## Claude's Discretion

- Internal HEEx template structure
- Exact daisyUI class mappings per variant
- Component module file organization
- Test strategy (snapshot vs unit)
- Date/datetime picker approach

## Deferred Ideas

- Modal stacking (v0.2+)
- File upload, rich text, color picker, tags, key-value components (v0.2+)

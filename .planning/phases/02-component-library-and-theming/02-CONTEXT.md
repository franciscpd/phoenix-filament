# Phase 2: Component Library and Theming - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

All LiveView UI primitives required by Form Builder (Phase 3), Table Builder (Phase 4), and Panel (Phase 6) — inputs, buttons, badges, modals, cards — implemented as stateless Phoenix.Component function components, styled with daisyUI 5 semantic classes and Tailwind v4 CSS variable theming. Includes a theming system with light/dark mode, full daisyUI theme palette, and per-panel CSS variable overrides.

</domain>

<decisions>
## Implementation Decisions

### Component Anatomy
- **D-01:** One function component per input type — `text_input/1`, `textarea/1`, `select/1`, `toggle/1`, `checkbox/1`, `date/1`, `datetime/1`, `hidden/1`. Maps 1:1 to `%Field{}` types from Phase 1.
- **D-02:** Built-in error display — each input component auto-renders field-level error messages below the field when the changeset has errors. No separate `<.field_error>` component needed.
- **D-03:** One function component per non-input type — `button/1`, `badge/1`, `card/1`, `modal/1`. Consistent pattern across all components.
- **D-04:** Hybrid slot strategy — simple attrs for common cases (`title="X"`), named slots (`:header`, `:body`, `:footer`, `:actions`) for complex layouts. Both work on the same component.
- **D-05:** Boolean attrs for states — `disabled` and `loading` as boolean attrs. Loading on a button shows spinner and auto-disables.
- **D-06:** Built-in accessibility — components auto-generate `aria-label`, `aria-describedby` (linking to error elements), `role` attributes. Developers get a11y for free.

### Theming Strategy
- **D-07:** Full daisyUI theme palette — ship all 30+ daisyUI themes out of the box. Developers choose via `data-theme` attribute.
- **D-08:** Per-panel theme via CSS variable override — Panel module declares `theme: "dark"` and/or `colors: [primary: "oklch(...)"]`. Applied as `data-theme` + inline CSS variables on panel root element.
- **D-09:** Auto + manual dark mode toggle — defaults to OS preference via `prefers-color-scheme`. Panel can opt-in to a theme switcher toggle in the top bar (`theme_switcher: true`).
- **D-10:** daisyUI semantic classes used directly — components use `btn`, `badge`, `modal-box`, etc. No custom CSS abstraction layer. Leverages daisyUI documentation directly.
- **D-11:** Inline class lists for conditional CSS — use Phoenix's built-in class list syntax with boolean conditionals. No class builder module.

### Modal & Portal
- **D-12:** LiveView 1.1 Portals for modal rendering — modals render at DOM root via `<.portal>`, escaping overflow:hidden containers. Zero JS, framework-native.
- **D-13:** No modal stacking in v0.1 — one modal at a time. Opening a new modal closes the current one. Stacking deferred to v0.2+.
- **D-14:** show/on_cancel control pattern — modal takes `show` boolean assign and `on_cancel` event attr. Controlled by parent LiveView assigns. Follows Phoenix generator convention.

### Component API Style
- **D-15:** `use PhoenixFilament.Components` for bulk import — single `use` imports all components. Selective `import PhoenixFilament.Components.Input` also available.
- **D-16:** No component name prefix — short names: `<.text_input>`, `<.button>`, `<.modal>`. Developer resolves collisions via alias if needed.
- **D-17:** Every component accepts `class` attr — custom Tailwind classes merged with component defaults. Standard extensibility pattern.

### Claude's Discretion
- Internal HEEx template structure for each component
- Exact daisyUI class mappings for each variant
- Component module file organization within `lib/phoenix_filament/components/`
- Test strategy for components (snapshot testing, unit testing, or both)
- Date/datetime picker implementation approach (native HTML5 vs custom)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints, key decisions, tech stack choices
- `.planning/REQUIREMENTS.md` — COMP-01 through COMP-12, THEME-01 through THEME-04
- `.planning/ROADMAP.md` §Phase 2 — Goal, success criteria, dependency info

### Phase 1 Foundation (dependency)
- `.planning/phases/01-foundation/01-CONTEXT.md` — DSL decisions, module organization, established patterns
- `lib/phoenix_filament/field.ex` — `%Field{}` struct types that components must render
- `lib/phoenix_filament/column.ex` — `%Column{}` struct that table components consume
- `lib/phoenix_filament/naming.ex` — Shared humanize utility for labels

### Technology Stack
- `CLAUDE.md` §Technology Stack — daisyUI 5, Tailwind v4, LiveView 1.1 portals, Phoenix.Component
- daisyUI 5 docs (https://daisyui.com/docs/v5/) — Semantic class names, theme system, `@plugin` configuration

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Naming.humanize/1` — auto-humanize atom names to labels (used by Field and Column, reusable for component labels)
- `%PhoenixFilament.Field{}` — struct with `:name`, `:type`, `:label`, `:opts` — components dispatch on `:type`
- `%PhoenixFilament.Column{}` — struct with `:name`, `:label`, `:opts` — table column components use this

### Established Patterns
- One module per concept (`field.ex`, `column.ex`, `schema.ex`) — components should follow same pattern
- Plain data structs, no macro magic — components receive structs as attrs
- `@spec` and `@doc` on all public functions — components should have typed attrs with docs

### Integration Points
- Phase 3 (Form Builder) will render `%Field{}` structs using these input components
- Phase 4 (Table Builder) will use button, badge, and layout components
- Phase 6 (Panel) will use modal, card, and navigation components
- Components must work standalone (no Panel dependency) per success criteria #1

</code_context>

<specifics>
## Specific Ideas

- API should feel like Phoenix's own component generators — `<.input>` from `core_components.ex` is the reference point
- daisyUI classes directly (no abstraction layer) — keeps the learning curve flat
- LiveView 1.1 portals for modals — this is a differentiator vs Backpex which requires Alpine.js
- `class` attr on every component — devs can always extend without fighting the framework

</specifics>

<deferred>
## Deferred Ideas

- Modal stacking (v0.2+) — allow modal-over-modal for confirmation dialogs
- File upload component (v0.2+ per AFIELD-01)
- Rich text editor component (v0.2+ per AFIELD-02)
- Color picker, tags input, key-value components (v0.2+)

</deferred>

---

*Phase: 02-component-library-and-theming*
*Context gathered: 2026-04-01*

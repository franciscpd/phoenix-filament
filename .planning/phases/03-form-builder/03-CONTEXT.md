# Phase 3: Form Builder - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Standalone declarative form DSL that renders `%Field{}` structs into a working form with Ecto changeset integration, real-time validation, conditional field visibility, and layout sections — all without Panel or Resource dependency. The `form_builder/1` function component receives a Phoenix form and a list of fields, rendering them with auto-wrapped `<.form>`, submit button, sections, columns, and `visible_when` client-side toggling.

</domain>

<decisions>
## Implementation Decisions

### Form LiveView Integration
- **D-01:** Form Builder is a stateless function component `form_builder/1` — parent LiveView owns all state (changeset, assigns). No LiveComponent. Most composable and testable approach.
- **D-02:** Component named `form_builder` (not `pf_form` or `resource_form`) — descriptive, avoids collision with Phoenix `<.form>`, no false coupling to Resource.
- **D-03:** Auto-wraps fields in Phoenix `<.form>` tag — developer passes `form`, `fields`, `phx-change`, `phx-submit`. Component renders `<form>` + fields + submit button internally. Less boilerplate.
- **D-04:** Auto-renders submit button with configurable label — `submit_label="Save Post"` customizes text. `submit={false}` hides it. Default label: "Save".

### Layout System
- **D-05:** `section/2` macro in DSL — groups fields under a heading. Renders as `<fieldset>` with `<legend>`. Fields outside sections render at top level. Sections can also have `visible_when` conditions.
- **D-06:** `columns/2` macro for multi-column layout — `columns 2 do...end` renders fields inside a CSS grid (`grid grid-cols-N gap-4`). Works inside or outside sections. Fields after the columns block return to full width.

### Conditional Visibility (visible_when)
- **D-07:** Client-side evaluation via LiveView JS commands — `visible_when` conditions trigger `JS.show`/`JS.hide` on the controlling field's `phx-change`. Zero server round-trip. Meets success criterion #5.
- **D-08:** Tuple syntax for conditions — `{field_name, operator, value}`. Operators: `:eq`, `:neq`, `:in`, `:not_in`. Covers 90% of use cases. Composable and serializable to JS.

### Changeset Integration
- **D-09:** Form Builder does NOT own changeset functions — it receives `@form` (already built from changeset by parent LiveView or Resource module). Create vs update changeset selection is Phase 5 (Resource) responsibility. Form Builder is changeset-agnostic.
- **D-10:** Live validation via standard `phx-change` on `<form>` — form renders `phx-change` attr. Parent LiveView handles the "validate" event, rebuilds changeset with `:validate` action, and passes updated `@form`. Standard Phoenix pattern, no custom validation logic in Form Builder.

### Claude's Discretion
- Internal data structure for sections and columns (how DSL accumulates layout info alongside fields)
- How `visible_when` tuple conditions are compiled to JS commands at render time
- Test strategy for client-side visibility (may need LiveView integration test or JS assertion)
- Exact `<fieldset>`/`<legend>` daisyUI classes for section styling

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — FORM-01 through FORM-07
- `.planning/ROADMAP.md` §Phase 3 — Goal, success criteria, dependency info

### Phase 1 Foundation (dependency)
- `.planning/phases/01-foundation/01-CONTEXT.md` — DSL syntax decisions (D-01, D-02, D-04)
- `lib/phoenix_filament/field.ex` — `%Field{}` struct (name, type, label, opts)
- `lib/phoenix_filament/resource/dsl.ex` — Existing `form/1` macro with field accumulation

### Phase 2 Components (dependency)
- `.planning/phases/02-component-library-and-theming/02-CONTEXT.md` — Component anatomy decisions
- `lib/phoenix_filament/components/field_renderer.ex` — `render_field/1` dispatching `%Field{}` → input component
- `lib/phoenix_filament/components/input.ex` — All 9 input components with error display and a11y
- `lib/phoenix_filament/components/button.ex` — Button component for submit button

### Technology Stack
- `CLAUDE.md` §Technology Stack — Phoenix LiveView 1.1, LiveView JS commands

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Components.FieldRenderer.render_field/1` — dispatches `%Field{}` to correct input component. Form Builder should use this to render each field.
- `PhoenixFilament.Components.Input` — all 9 input types with built-in error display, label, a11y, class merging
- `PhoenixFilament.Components.Button` — submit button with variants and loading state
- `PhoenixFilament.Resource.DSL` — existing `form/1` macro that accumulates `%Field{}` structs via module attributes
- `PhoenixFilament.Naming.humanize/1` — label humanization for section headings

### Established Patterns
- Module attribute accumulation for DSL → `%Field{}` structs collected in `__before_compile__`
- Function components accept `Phoenix.HTML.FormField` — Form Builder passes form fields to FieldRenderer
- daisyUI semantic classes + inline class lists — follow same pattern for sections/columns layout
- `@rest` global attrs for phx-* events pass-through

### Integration Points
- Phase 5 (Resource) will call `form_builder/1` with `__resource__(:form_fields)` and the changeset-based form
- The existing `form do...end` DSL macro (Phase 1) accumulates fields — Form Builder needs to also accumulate sections and columns layout info
- `FieldRenderer.render_field/1` is the bridge between `%Field{}` structs and input components

</code_context>

<specifics>
## Specific Ideas

- `form_builder/1` should feel like a "batteries included" Phoenix component — pass form + fields and get a working form
- Sections use `<fieldset>` for semantic HTML and accessibility (screen readers announce section labels)
- `visible_when` compiled to LiveView JS at render time — no custom JS hooks needed
- Auto-submit button follows daisyUI `btn btn-primary` styling by default

</specifics>

<deferred>
## Deferred Ideas

- LiveComponent wrapper for self-contained forms (v0.2+)
- Per-field validation trigger config (validate_on: :blur) (v0.2+)
- Form-level changeset declaration (stays in Resource, Phase 5)
- Association-backed select options (Phase 3 receives static options from Resource)
- Nested forms / embeds_many inline editing (v0.2+)

</deferred>

---

*Phase: 03-form-builder*
*Context gathered: 2026-04-01*

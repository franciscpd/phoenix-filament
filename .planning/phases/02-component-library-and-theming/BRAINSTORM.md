# Phase 2: Component Library and Theming — Design Spec

**Date:** 2026-04-01
**Status:** Approved
**Approach:** Bottom-Up — standalone components first, then Field dispatcher

## Overview

Phase 2 delivers all LiveView UI primitives needed by Form Builder (Phase 3), Table Builder (Phase 4), and Panel (Phase 6). Components are stateless `Phoenix.Component` function components, styled with daisyUI 5 semantic classes and Tailwind v4 CSS variables. They work standalone — no Panel or Resource dependency.

## Architecture: Bottom-Up with Field Dispatcher

Components are pure UI primitives that accept standard Phoenix attrs (`Phoenix.HTML.FormField`, strings, booleans). They know nothing about `%Field{}` or `%Column{}` structs. A thin `FieldRenderer` module bridges Phase 1 structs to Phase 2 components.

```
%Field{type: :text_input, name: :title, label: "Title", opts: [...]}
                    │
                    ▼
          FieldRenderer.render_field/1
                    │
                    ▼
    <.text_input field={@form[:title]} label="Title" .../>
                    │
                    ▼
    <input type="text" class="input input-bordered" .../>
```

This separation ensures:
- Components usable in any LiveView without PhoenixFilament (success criteria #1)
- Components testable in isolation (no schema, no repo)
- `%Field{}` struct changes don't break component API
- Phase 3 (Form Builder) consumes both layers

## Module Structure

```
lib/phoenix_filament/components/
├── input.ex            # text_input/1, textarea/1, number_input/1, select/1,
│                       # checkbox/1, toggle/1, date/1, datetime/1, hidden/1
├── button.ex           # button/1 (variants: primary, secondary, danger, ghost)
├── badge.ex            # badge/1 (color variants: success, warning, error, info)
├── card.ex             # card/1 (hybrid: title attr + :header/:body/:footer slots)
├── modal.ex            # modal/1 (LiveView 1.1 portal, show/on_cancel)
├── field_renderer.ex   # render_field/1 — dispatches %Field{} → component
├── theme.ex            # css_vars/1, theme_attr/1, theme_switcher/1
└── components.ex       # use PhoenixFilament.Components (imports all)
```

**Rationale:** Inputs grouped (related, share patterns), complex components isolated (each has unique slot/portal logic). Follows existing Phase 1 pattern of flat-by-domain.

## Component Inventory

### Input Components (input.ex)

All input components share this attr contract:

| Attr | Type | Default | Description |
|------|------|---------|-------------|
| `field` | `Phoenix.HTML.FormField` | required | Form field from `@form[:name]` |
| `label` | `:string` | nil | Label text (omitted if nil) |
| `required` | `:boolean` | false | Shows asterisk on label (UI hint only) |
| `disabled` | `:boolean` | false | Disables the input |
| `class` | `:string` | nil | Custom classes merged with defaults |
| `rest` | `:global` | — | Pass-through HTML attrs |

Plus type-specific attrs:

| Component | Extra Attrs | daisyUI Classes | HTML Element |
|-----------|-------------|-----------------|--------------|
| `text_input/1` | placeholder | `input input-bordered` | `<input type="text">` |
| `textarea/1` | placeholder, rows | `textarea textarea-bordered` | `<textarea>` |
| `number_input/1` | placeholder, min, max, step | `input input-bordered` | `<input type="number">` |
| `select/1` | options (list of `{label, value}` tuples or strings), prompt | `select select-bordered` | `<select>` |
| `checkbox/1` | — | `checkbox` | `<input type="checkbox">` |
| `toggle/1` | — | `toggle` | `<input type="checkbox">` (styled as toggle) |
| `date/1` | min, max | `input input-bordered` | `<input type="date">` (native HTML5) |
| `datetime/1` | min, max | `input input-bordered` | `<input type="datetime-local">` (native) |
| `hidden/1` | — | — | `<input type="hidden">` |

**Date/DateTime strategy:** Native HTML5 inputs for v0.1. API designed so custom calendar picker can replace the implementation in v0.2 without breaking changes.

### Button (button.ex)

| Attr | Type | Default | Values |
|------|------|---------|--------|
| `variant` | `:atom` | `:primary` | `:primary`, `:secondary`, `:danger`, `:ghost` |
| `size` | `:atom` | `:md` | `:sm`, `:md`, `:lg` |
| `loading` | `:boolean` | false | Shows spinner, auto-disables |
| `disabled` | `:boolean` | false | Grays out |
| `type` | `:string` | "button" | HTML type attr |
| `class` | `:string` | nil | Custom classes |
| `rest` | `:global` | — | phx-click, etc. |

daisyUI mapping: `btn btn-{variant} btn-{size}`, loading adds `loading loading-spinner`.

### Badge (badge.ex)

| Attr | Type | Default | Values |
|------|------|---------|--------|
| `color` | `:atom` | `:neutral` | `:neutral`, `:primary`, `:success`, `:warning`, `:error`, `:info` |
| `size` | `:atom` | `:md` | `:sm`, `:md`, `:lg` |
| `class` | `:string` | nil | Custom classes |

daisyUI mapping: `badge badge-{color} badge-{size}`. Inner content via default slot.

### Card (card.ex)

**Hybrid slot strategy** — simple attrs for common cases, named slots for complex:

```heex
<%!-- Simple: title attr --%>
<.card title="Post Details">
  <p>Content here</p>
</.card>

<%!-- Complex: named slots --%>
<.card>
  <:header><h2>Post Details</h2> <.badge color={:success}>Active</.badge></:header>
  <:body><p>Content here</p></:body>
  <:footer><.button>Save</.button></:footer>
</.card>
```

| Attr/Slot | Type | Description |
|-----------|------|-------------|
| `title` | `:string` | Shorthand for simple header |
| `class` | `:string` | Custom classes on card root |
| `:header` slot | named | Complex header content |
| `:body` slot | named | Body content (falls back to inner_block) |
| `:footer` slot | named | Footer/actions area |

daisyUI mapping: `card bg-base-100 shadow-sm`, `card-body`, `card-title`.

### Modal (modal.ex)

```heex
<.modal show={@show_delete} on_cancel={JS.push("close_modal")}>
  <:header>Delete Post?</:header>
  <p>This action cannot be undone.</p>
  <:actions>
    <.button variant={:danger} phx-click="delete">Delete</.button>
    <.button variant={:ghost} phx-click="close_modal">Cancel</.button>
  </:actions>
</.modal>
```

| Attr/Slot | Type | Description |
|-----------|------|-------------|
| `show` | `:boolean` | Controls visibility |
| `on_cancel` | `Phoenix.LiveView.JS` | Event when backdrop clicked or Escape pressed |
| `class` | `:string` | Custom classes on modal-box |
| `:header` slot | named | Modal title |
| `:actions` slot | named | Action buttons |

**Implementation:** LiveView 1.1 `<.portal>` to render at DOM root. No stacking (one modal at a time). `JS.show`/`JS.hide` with transitions for open/close animation.

## Component Internal Pattern

Every component follows the same structure:

1. **Typed attrs** with `attr` declarations — compile-time validation
2. **Built-in error display** — iterates `@field.errors`, renders `<p role="alert">`
3. **Built-in a11y** — `aria-describedby` links input to error element, `<label for={}>` links to input
4. **Class merge** — `class={["default classes", conditional && "extra", @class]}`
5. **Global attrs pass-through** — `@rest` for phx-click, data-*, etc.

## Field Renderer (field_renderer.ex)

Thin dispatcher that bridges `%Field{}` structs to components:

```elixir
def render_field(assigns) do
  # assigns contains :pf_field (%Field{}) and :form (Phoenix.HTML.Form)
  # Dispatches based on pf_field.type
end
```

One function head per field type. Extracts `label`, `opts` from `%Field{}` and forwards as component attrs. Phase 3 (Form Builder) will use this to render form fields from DSL declarations.

## Theming System (theme.ex)

### What Phase 2 delivers:
- `css_vars/1` — converts `[primary: "oklch(...)"]` keyword to CSS variable inline style string
- `theme_attr/1` — returns `data-theme` value from theme name atom
- `theme_switcher/1` — toggle component using daisyUI `theme-controller` class

### What Phase 2 does NOT deliver (Phase 6):
- Panel layout with `data-theme` application
- `colors:` override wiring from Panel module
- User preference persistence

### Theme rules for all components:
- No hardcoded colors anywhere — only daisyUI semantic classes (`btn-primary`, `text-error`, `badge-success`)
- No Tailwind class string interpolation — only list syntax with boolean conditionals
- All 35+ daisyUI themes available via `data-theme` attribute
- Dark mode: automatic via `prefers-color-scheme`, manual via `theme_switcher/1`

## Import API

```elixir
# Bulk import — all components available as <.text_input>, <.button>, etc.
defmodule MyAppWeb.PostLive do
  use PhoenixFilament.Components
end

# Selective import
defmodule MyAppWeb.PostLive do
  import PhoenixFilament.Components.Input
  import PhoenixFilament.Components.Button
end
```

`use PhoenixFilament.Components` expands to imports of all component modules. No name prefix — short names (`text_input`, not `pf_text_input`). Developer resolves collisions via alias if needed.

## Testing Strategy

**Approach:** Unit tests with `Phoenix.LiveViewTest.render_component/2`. Assertive tests on HTML structure, not snapshot comparisons.

```
test/phoenix_filament/components/
├── input_test.exs          # All 9 input components
├── button_test.exs         # Variants, sizes, loading, disabled
├── badge_test.exs          # Color variants
├── card_test.exs           # Hybrid slots (simple + complex)
├── modal_test.exs          # show/hide, portal
├── field_renderer_test.exs # %Field{} → component dispatch
└── theme_test.exs          # css_vars/1, theme_attr/1
```

**Each test verifies:**
- Correct daisyUI classes in rendered HTML
- Label renders when present, omits when nil
- Errors render with `role="alert"` and `aria-describedby`
- `disabled`/`loading` attrs produce correct markup
- `class` attr merges with defaults (not replaces)
- Zero hardcoded colors (no `bg-blue-500`, only `btn-primary`)

## Success Criteria Mapping

| Roadmap Criterion | How This Design Satisfies It |
|-------------------|------------------------------|
| 1. Components work in plain LiveView without Panel | Components accept `Phoenix.HTML.FormField`, not `%Field{}`. No Panel dependency. |
| 2. Default theme produces professional appearance | daisyUI 5 default theme + semantic classes = professional out of the box |
| 3. Dark mode via CSS variables, no JS round-trip | `prefers-color-scheme` + daisyUI `data-theme` — pure CSS |
| 4. Override brand colors via CSS variables | `css_vars/1` helper + per-panel `colors:` option |
| 5. No Tailwind class interpolation | All class construction via list syntax with boolean conditionals |

## Deferred to Future Versions

- Modal stacking (v0.2+)
- Custom date/datetime calendar picker (v0.2+)
- File upload, rich text, color picker, tags, key-value components (v0.2+)
- Navigation components (Phase 6 — Panel)
- Table-specific components like pagination, filters (Phase 4)

## Spec Amendments (Post-Review)

### Modal Portal — Deferred to Phase 6
The modal currently renders as a plain `<div>` with CSS class toggling. LiveView 1.1 `<.portal>` wrapping will be added in Phase 6 (Panel Shell) when the modal is integrated into the panel layout. The component API (`show`/`on_cancel`) is portal-ready — only the wrapping needs to change.

### Modal JS Transitions — Deferred to Phase 6
`JS.show`/`JS.hide` transitions and Escape key handling will be added alongside the portal integration in Phase 6.

### COMP-04 Association-Backed Options — Deferred to Phase 3
The select component accepts static option lists. Association-backed options (loading from belongs_to relationships) require Form Builder context and will be implemented in Phase 3 where the form can resolve associations before passing to the select.

---

*Phase: 02-component-library-and-theming*
*Design approved: 2026-04-01*

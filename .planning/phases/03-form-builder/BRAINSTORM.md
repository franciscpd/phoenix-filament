# Phase 3: Form Builder — Design Spec

**Date:** 2026-04-01
**Status:** Approved
**Approach:** Form Builder as pure rendering module — stateless function component

## Overview

Phase 3 delivers a standalone declarative form system. The `form_builder/1` function component receives a Phoenix form and a form schema (list of `%Field{}`, `%Section{}`, `%Columns{}` structs), renders them as a complete HTML form with daisyUI styling, auto-wrapped `<.form>` tag, submit button, and client-side conditional field visibility. The Form Builder is changeset-agnostic — the parent LiveView owns all state.

## Architecture

```
DSL (compile-time)              →   Data (runtime)                 →   Component (render)
                                                                    
form do                             [                                  <.form_builder
  text_input :title                   %Field{name: :title},              form={@form}
  section "Publishing" do             %Section{                          schema={@schema}
    toggle :published                   label: "Publishing",             phx-change="validate"
    date :published_at,                 items: [                         phx-submit="save"
      visible_when: ...                   %Field{name: :published},    />
  end                                     %Field{name: :published_at,
end                                         opts: [visible_when: ...]}
                                        ]
                                      }
                                    ]
```

The Form Builder sits between Phase 1 (DSL + structs) and Phase 2 (input components). It uses `FieldRenderer.render_field/1` to dispatch each `%Field{}` to the correct input component.

## Data Structures

### New Structs

```elixir
# lib/phoenix_filament/form/section.ex
defmodule PhoenixFilament.Form.Section do
  @moduledoc "Groups form fields under a labeled heading."
  defstruct [:label, :visible_when, items: []]
  @type t :: %__MODULE__{
    label: String.t(),
    visible_when: {atom(), atom(), any()} | nil,
    items: [PhoenixFilament.Field.t() | PhoenixFilament.Form.Columns.t()]
  }
end

# lib/phoenix_filament/form/columns.ex
defmodule PhoenixFilament.Form.Columns do
  @moduledoc "Arranges fields in a CSS grid with N columns."
  defstruct [:count, items: []]
  @type t :: %__MODULE__{
    count: pos_integer(),
    items: [PhoenixFilament.Field.t()]
  }
end
```

### Existing Struct Extension

`%Field{}` already has `opts: keyword()`. `visible_when` is stored in opts:

```elixir
%Field{name: :published_at, type: :date, label: "Published at",
       opts: [visible_when: {:published, :eq, true}]}
```

### Form Schema Type

The DSL produces a form schema — an ordered list of items:

```elixir
@type form_schema_item :: Field.t() | Section.t() | Columns.t()
@type form_schema :: [form_schema_item()]
```

## DSL Extension

### New Macros

The existing `resource/dsl.ex` FormFields module gets two new macros: `section/2` and `columns/2`.

**Implementation pattern:** Section and columns macros use a "push/pop context" approach with module attributes. When entering a section block, a new accumulator is pushed. Field macros inside accumulate to the current (innermost) context. On exit, the accumulated items are wrapped in a `%Section{}` or `%Columns{}` struct and appended to the parent accumulator.

```elixir
# Developer writes:
form do
  text_input :title, required: true

  section "Publishing" do
    toggle :published
    date :published_at, visible_when: {:published, :eq, true}
  end

  section "Author" do
    columns 2 do
      text_input :first_name
      text_input :last_name
    end
    textarea :bio
  end
end
```

**Backward compatibility:** Forms without `section` or `columns` produce a flat `[%Field{}, ...]` list. `form_builder/1` handles both flat and structured schemas.

### visible_when in DSL

`visible_when` is a standard Field opt — no special DSL syntax needed:

```elixir
date :published_at, visible_when: {:published, :eq, true}
```

Operators: `:eq`, `:neq`, `:in`, `:not_in`.

Sections can also have `visible_when`:

```elixir
section "Advanced", visible_when: {:type, :in, ["pro", "enterprise"]} do
  ...
end
```

## form_builder/1 Component

### Public API

```elixir
attr :form, :any, required: true           # Phoenix.HTML.Form (from to_form)
attr :schema, :list, required: true         # [%Field{} | %Section{} | %Columns{}]
attr :submit_label, :string, default: "Save"
attr :submit, :boolean, default: true       # false to hide submit button
attr :class, :string, default: nil
attr :rest, :global, include: ~w(phx-change phx-submit)
```

### Rendering Logic

1. Wraps everything in `<.form for={@form} {@rest}>`
2. Iterates `@schema` list, dispatching by struct type:
   - `%Field{}` → `FieldRenderer.render_field/1` (with visibility wrapper if `visible_when` set)
   - `%Section{}` → `<fieldset class="fieldset">` with `<legend>` + recursive render of items
   - `%Columns{}` → `<div class="grid grid-cols-{N} gap-4">` + recursive render of items
3. Renders submit button at the end (if `submit: true`)

### Column Grid Classes

Static map to avoid Tailwind class interpolation:

```elixir
@grid_classes %{
  1 => "grid-cols-1",
  2 => "grid-cols-2",
  3 => "grid-cols-3",
  4 => "grid-cols-4"
}
```

## Conditional Visibility (visible_when)

### Rendering

Fields (or sections) with `visible_when` are wrapped in a container div:

```html
<div id="field-published_at" style="display:none"
     phx-hook="PFVisibility"
     data-controlling-id="post_published"
     data-operator="eq"
     data-expected="true">
  <!-- field content rendered by FieldRenderer -->
</div>
```

### Colocated JS Hook

A minimal JS hook (`PFVisibility`) handles client-side show/hide:

```javascript
// ~15 lines — listens to input events on the controlling field
// Evaluates condition (eq, neq, in, not_in) and toggles display
Hooks.PFVisibility = {
  mounted() {
    const controlling = document.getElementById(this.el.dataset.controllingId)
    if (!controlling) return

    const evaluate = () => {
      const op = this.el.dataset.operator
      const expected = this.el.dataset.expected
      const actual = controlling.type === "checkbox" ? String(controlling.checked) : controlling.value

      const match = op === "eq" ? actual === expected
                  : op === "neq" ? actual !== expected
                  : op === "in" ? expected.split(",").includes(actual)
                  : op === "not_in" ? !expected.split(",").includes(actual)
                  : false

      this.el.style.display = match ? "" : "none"
    }

    controlling.addEventListener("input", evaluate)
    controlling.addEventListener("change", evaluate)
    evaluate() // Initial state
  }
}
```

**Why a hook instead of pure LiveView JS:** LiveView JS commands (`JS.show`/`JS.hide`) don't support conditional evaluation. A hook is cleaner, explicit, and testable. LiveView 1.1 supports colocated hooks natively.

### Initial State

The hook calls `evaluate()` on mount to set correct initial visibility based on current form values (important for edit forms where values are pre-filled).

## Module Structure

```
lib/phoenix_filament/form/
├── section.ex          # %Section{} struct
├── columns.ex          # %Columns{} struct
├── form_builder.ex     # form_builder/1 function component
└── visibility.ex       # visible_when rendering helpers + hook registration
```

Plus modifications to:
- `lib/phoenix_filament/resource/dsl.ex` — add section/2 and columns/2 macros to FormFields

## Testing Strategy

```
test/phoenix_filament/form/
├── form_builder_test.exs    # Component rendering (flat + structured schemas)
├── section_test.exs         # Section struct
├── columns_test.exs         # Columns struct
├── dsl_test.exs             # Extended DSL macros
└── visibility_test.exs      # visible_when wrapper rendering + data attrs
```

### What We Test
- **Structs:** Section and Columns constructors and types
- **DSL:** `section/2` and `columns/2` macros produce correct nested data structures
- **form_builder rendering:**
  - Flat field list → renders inputs
  - Section → renders `<fieldset>` with `<legend>`
  - Columns → renders grid div with correct class
  - Submit button shows/hides based on `submit` attr
  - `phx-change`/`phx-submit` pass through to `<form>`
  - `submit_label` customizes button text
- **Visibility rendering:**
  - Field with `visible_when` → wrapper div with `style="display:none"`, `phx-hook="PFVisibility"`, data attrs
  - Field without `visible_when` → no wrapper
  - Section with `visible_when` → fieldset wrapper with hook

### What We Don't Test (Phase 3)
- Ecto changeset integration (Form Builder is changeset-agnostic)
- JS hook behavior (requires browser — manual testing or Phase 6 integration tests)
- Integration with Resource module (Phase 5)

## Success Criteria Mapping

| Roadmap Criterion | How This Design Satisfies It |
|-------------------|------------------------------|
| 1. Form works in plain LiveView, no panel | form_builder is a function component receiving @form + @schema. No Panel dependency. |
| 2. Submit calls changeset, renders errors inline | Parent LiveView handles phx-submit, passes changeset errors via @form. Input components already render errors (Phase 2). |
| 3. Separate create/update changesets | Form Builder is changeset-agnostic. Resource (Phase 5) selects the right changeset. |
| 4. Live validation on type/blur | form_builder renders phx-change on form tag. Parent handles validation event. |
| 5. visible_when shows/hides without server round-trip | PFVisibility JS hook evaluates conditions client-side. Zero phx-change for visibility. |

## Deferred to Future Versions

- LiveComponent wrapper for self-contained forms (v0.2+)
- Per-field validation trigger (validate_on: :blur) (v0.2+)
- Nested forms / embeds_many inline editing (v0.2+)
- Association-backed select options (Phase 5 resolves, passes static list)
- Form wizard / multi-step forms (v0.2+)

---

*Phase: 03-form-builder*
*Design approved: 2026-04-01*

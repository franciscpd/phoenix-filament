# Phase 1: Foundation — Design Spec

**Date:** 2026-03-31
**Status:** Approved
**Context:** `.planning/phases/01-foundation/01-CONTEXT.md`

## Overview

Phase 1 establishes the core primitives for PhoenixFilament: a Hex package scaffold, Ecto schema introspection, runtime DSL infrastructure with module attribute accumulation, and compile-time safety via `Macro.expand_literals/2`. Every subsequent phase builds directly on these foundations.

## Architecture: Monolito Foundation

Simple flat-by-domain structure with no premature abstractions. Each file has one clear responsibility.

```
lib/phoenix_filament.ex                    # Application module (minimal supervision tree)
lib/phoenix_filament/
├── field.ex                               # %Field{} struct + constructor functions
├── column.ex                              # %Column{} struct + constructor functions
├── schema.ex                              # Ecto introspection API
├── resource.ex                            # __using__ macro + NimbleOptions validation
└── resource/
    ├── dsl.ex                             # form/table block macros (accumulation)
    └── defaults.ex                        # Auto-discovery: schema → default fields/columns
```

**Dependencies (Phase 1):**
- `phoenix_live_view ~> 1.1` (peer dep)
- `phoenix_html ~> 4.1` (peer dep)
- `ecto ~> 3.11` (for schema introspection)
- `nimble_options ~> 1.0` (for option validation)

**Application module:** Minimal `Application.start/2` with empty supervisor. No GenServers needed.

## Component 1: `%PhoenixFilament.Field{}`

Plain data struct representing a form field declaration. Consumed by Form Builder (Phase 3) and Component Library (Phase 2).

```elixir
defmodule PhoenixFilament.Field do
  @type t :: %__MODULE__{
    name: atom(),
    type: field_type(),
    label: String.t() | nil,
    opts: keyword()
  }

  @type field_type ::
    :text_input | :textarea | :number_input | :select |
    :checkbox | :toggle | :date | :datetime | :hidden

  defstruct [:name, :type, :label, opts: []]
end
```

**Design choices:**
- `opts` is a flat keyword list — extensible without struct changes. Each field type documents its supported opts.
- `label` auto-humanizes from atom name via `Phoenix.Naming.humanize/1`. Override with `label: "Custom"`.
- Constructor functions (`text_input/2`, `textarea/2`, etc.) return plain structs — no side effects, fully testable. A shared `new/3` function is public to support auto-discovery in `Resource.Defaults`.
- Validation hints (e.g., `required: true`) are stored in `opts` for UI presentation only. Real validation lives in Ecto changesets (D-04).

## Component 2: `%PhoenixFilament.Column{}`

Plain data struct representing a table column declaration. Consumed by Table Builder (Phase 4).

```elixir
defmodule PhoenixFilament.Column do
  @type t :: %__MODULE__{
    name: atom(),
    label: String.t() | nil,
    opts: keyword()
  }

  defstruct [:name, :label, opts: []]
end
```

**Supported opts (documented, not enforced at struct level):**
- `sortable: true` — enable column sorting
- `searchable: true` — include in global search
- `format: fn value, row -> ... end` — custom cell formatting
- `badge: true` — render as badge component
- `visible: false` — hide by default
- `preload: :association_name` — preload association for this column

## Component 3: `PhoenixFilament.Schema` — Ecto Introspection

Wraps Ecto's `__schema__/1` runtime API for structured metadata extraction.

```elixir
defmodule PhoenixFilament.Schema do
  @spec fields(module()) :: [%{name: atom(), type: atom()}]
  def fields(schema)

  @spec associations(module()) :: [%{name: atom(), type: atom(), related: module()}]
  def associations(schema)

  @spec embeds(module()) :: [%{name: atom(), cardinality: :one | :many, related: module()}]
  def embeds(schema)

  @spec virtual_fields(module()) :: [%{name: atom(), type: atom()}]
  def virtual_fields(schema)

  @spec visible_fields(module()) :: [%{name: atom(), type: atom()}]
  def visible_fields(schema)

  @spec type_to_field_type(atom()) :: PhoenixFilament.Field.field_type()
  def type_to_field_type(ecto_type)
end
```

**Key behaviors:**
- All functions call `Code.ensure_loaded!/1` first, then use `__schema__/1` at **runtime only** — no compile-time dependency on schema modules.
- `visible_fields/1` implements smart exclusion (D-08): excludes `id`, `__meta__`, `inserted_at`, `updated_at`, and fields ending in `_hash`, `_digest`, `_token`.
- `type_to_field_type/1` maps Ecto types to form input types: `:string` → `:text_input`, `:boolean` → `:toggle`, `:integer` → `:number_input`, etc. Fallback is `:text_input`.

## Component 4: DSL Macro Infrastructure

### `PhoenixFilament.Resource` — The `__using__` macro

```elixir
defmodule PhoenixFilament.Resource do
  @options_schema NimbleOptions.new!([
    schema: [type: :atom, required: true, doc: "The Ecto schema module"],
    repo: [type: :atom, required: true, doc: "The Ecto repo module"],
    label: [type: :string, doc: "Human-readable resource name"],
    plural_label: [type: :string, doc: "Plural form of label"],
    icon: [type: :string, doc: "Icon name for navigation"]
  ])
end
```

**`__using__/1` responsibilities:**
1. Validate options via NimbleOptions
2. Initialize module attribute accumulators (`@_phx_filament_form_fields`, `@_phx_filament_table_columns`)
3. Import DSL macros (`form/1`, `table/1`) from `PhoenixFilament.Resource.DSL`
4. Register `@before_compile` callback
5. Store schema/repo as runtime refs via `Macro.expand_literals/2`

**`__before_compile__/1` responsibilities:**
1. Define `__resource__/1` function for runtime config queries
2. Finalize form fields: use accumulated fields if any, otherwise auto-discover from schema
3. Finalize table columns: use accumulated columns if any, otherwise auto-discover from schema

### `PhoenixFilament.Resource.DSL` — Block macros

```elixir
defmacro form(do: block) do
  # Imports field functions (text_input, textarea, etc.) that accumulate
  # into @_phx_filament_form_fields via Module.put_attribute
end

defmacro table(do: block) do
  # Imports column function that accumulates into @_phx_filament_table_columns
end
```

**Field functions** (in `DSL.FormFields`): Each is a macro that expands to `@_phx_filament_form_fields PhoenixFilament.Field.text_input(name, opts)`. This accumulates DATA (structs), not CODE.

**Column function** (in `DSL.TableColumns`): `column/2` macro expands to `@_phx_filament_table_columns PhoenixFilament.Column.column(name, opts)`.

### `PhoenixFilament.Resource.Defaults` — Auto-discovery

When no `form` or `table` block is declared, auto-discovery kicks in at runtime:
1. Call `PhoenixFilament.Schema.visible_fields(schema)` to get field metadata
2. Map each field to a `%Field{}` using `type_to_field_type/1`
3. Map each field to a `%Column{}` with `sortable: true` default

This enables the zero-config resource:
```elixir
defmodule MyApp.Admin.PostResource do
  use PhoenixFilament.Resource, schema: MyApp.Blog.Post, repo: MyApp.Repo
  # No form/table blocks → full CRUD auto-generated from schema
end
```

### Compile-Time Safety: `Macro.expand_literals/2`

The critical pattern preventing dependency cascades:

```elixir
# In __using__:
@_phx_filament_schema Macro.expand_literals(unquote(opts[:schema]), __ENV__)
```

This stores the schema module as a **runtime reference**. Touching `MyApp.Blog.Post` does NOT trigger recompilation of any resource module that references it.

**Validation:** Automated test that touches a schema file, runs `mix compile`, and asserts the resource module does not appear in compile output.

## Component 5: Test Strategy

### Test Schemas (in `test/support/schemas/`)

| Schema | Purpose |
|--------|---------|
| `Post` | Simple schema: string, text, boolean, integer, belongs_to :author |
| `User` | Associations (has_many :posts) + sensitive fields (password_hash, confirmation_token) |
| `Comment` | Multiple belongs_to (post, user) |
| `Profile` | embeds_one, virtual fields |

### Test Resources (in `test/support/resources/`)

| Resource | Purpose |
|----------|---------|
| `PostResource` | Full DSL with form + table blocks |
| `UserResource` | DSL with exclusion testing (password_hash hidden) |
| `BareResource` | Zero-config (no form/table blocks) — tests auto-discovery |

### Key Test Scenarios

1. **Field/Column structs**: constructors return correct structs, label auto-humanizes, opts preserved
2. **Schema introspection**: `fields/1` correct types, `associations/1` finds belongs_to/has_many, `visible_fields/1` excludes sensitive, `embeds/1` works
3. **DSL accumulation**: `form do...end` produces ordered `%Field{}` list, `table do...end` produces ordered `%Column{}` list
4. **Auto-discovery**: bare resource generates fields from schema, types map correctly
5. **NimbleOptions validation**: missing `:schema` raises, missing `:repo` raises, unknown opts raise
6. **Compile-time cascade**: touch schema → `mix compile` → resource module NOT in recompile output

### Error Handling

- **Bad schema module:** `Code.ensure_loaded!/1` raises clear `ArgumentError` if module doesn't exist
- **Bad options:** NimbleOptions provides descriptive error messages with available options
- **Empty auto-discovery:** If schema has no visible fields, returns empty list (no crash)

## Data Flow Summary

```
Developer writes Resource module
  → use PhoenixFilament.Resource (compile-time)
    → NimbleOptions validates opts
    → Module attribute accumulators initialized
    → form/table block macros imported
  → form do...end block (compile-time)
    → Each field function accumulates %Field{} into @_phx_filament_form_fields
  → table do...end block (compile-time)
    → Each column function accumulates %Column{} into @_phx_filament_table_columns
  → __before_compile__ (compile-time)
    → Defines __resource__/1 with finalized field/column lists
    → If no fields declared: auto-discovery deferred to runtime

Runtime (Phase 5+):
  → __resource__(:form_fields) called
    → Returns accumulated fields OR auto-discovers from schema
  → __resource__(:table_columns) called
    → Returns accumulated columns OR auto-discovers from schema
```

## Success Criteria Mapping

| Criterion | How This Design Satisfies It |
|-----------|------------------------------|
| Package compiles as dependency with no warnings | Minimal deps, proper mix.exs, no warnings |
| `Schema.fields/1` returns typed metadata at runtime without recompilation | Uses `__schema__/1` runtime API only |
| `use PhoenixFilament.Resource` doesn't cause cascades on schema change | `Macro.expand_literals/2` for all module refs |
| Field and column definitions are plain structs inspectable in IEx | `%Field{}` and `%Column{}` are defstructs |

---

*Phase: 01-foundation*
*Design approved: 2026-03-31*

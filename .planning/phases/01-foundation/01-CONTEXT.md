# Phase 1: Foundation - Context

**Gathered:** 2026-03-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Hex package scaffold with correct supervision tree, Ecto schema introspection helpers, runtime DSL infrastructure (macro blocks, module attribute accumulation, plain data structs), and compile-time safety patterns (thin delegation via `Macro.expand_literals/2`). This phase delivers the stable primitives that every upper layer (Components, Form, Table, Resource, Panel, Plugin) builds on.

</domain>

<decisions>
## Implementation Decisions

### DSL Syntax Design
- **D-01:** Nested block syntax — `form do...end` and `table do...end` blocks inside resource modules with function calls like `text_input :title, required: true` for field declarations. Follows Ecto Schema / Phoenix Router conventions.
- **D-02:** Module attribute accumulator pattern — each field function call inside a DSL block accumulates a `%Field{}` struct via `Module.put_attribute/3` into `@_phx_filament_fields`. Collected in `__before_compile__` into a `__fields__/0` function. Same pattern as Ecto Schema and Phoenix Router.
- **D-03:** Auto-generate CRUD pages by default — `use PhoenixFilament.Resource` with no `form` or `table` blocks auto-discovers schema fields and generates index, create, edit, show pages with sensible defaults. Developer only customizes what they need. Partial override supported (e.g., custom `form` block with auto-generated `table`).
- **D-04:** Hybrid validation — DSL accepts `required: true` and similar hints for UI presentation (asterisk on label, visual cues) but all real validation logic lives in Ecto changesets. No duplication of validation rules. Source of truth is always the changeset.

### Module Organization
- **D-05:** Flat-by-domain namespace structure under `lib/phoenix_filament/`. Top-level modules for core concepts: `Schema`, `Field`, `Column`, `Resource`. Subdirectories for multi-file domains: `form/`, `table/`, `panel/`, `plugin/`, `components/`.
- **D-06:** Components in dedicated `PhoenixFilament.Components` namespace with sub-modules by category (`Input`, `Button`, `Badge`, `Modal`, `Card`). Developers can `use PhoenixFilament.Components` to import all, or `import PhoenixFilament.Components.Input` selectively.

### Ecto Introspection Depth
- **D-07:** Full introspection — extract fields, types, associations (belongs_to, has_many, has_one), embeds (embeds_one, embeds_many), and virtual fields. This powers maximum auto-discovery capability from day one.
- **D-08:** Smart exclusion list — auto-exclude `id`, `__meta__`, `inserted_at`, `updated_at`, and fields ending in `_hash`, `_digest`, `_token` from auto-generated forms/tables. Override with `include: [:inserted_at]` or `exclude: [:body]` in DSL blocks. Explicit field declarations bypass auto-discovery entirely.

### Test Strategy
- **D-09:** Compile-time cascade prevention validated via automated test helper using `Mix.Utils.stale?` / `mix compile` output parsing. Test touches a schema file and asserts the resource module does NOT appear in recompilation output. Runs in CI.
- **D-10:** Test support modules in `test/support/` — schemas, resources, and helpers compiled only for tests. No full Phoenix app needed for Phase 1. Pattern follows Ecto's own test setup.

### Claude's Discretion
- Internal struct field names for `%Field{}` and `%Column{}` — Claude to design based on what the Form Builder and Table Builder will need
- NimbleOptions schema structure for `use PhoenixFilament.Resource` options
- Supervision tree shape (if needed at all for Phase 1 — may be a no-op Application.start)
- Exact `Macro.expand_literals/2` usage pattern for thin delegation

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints, key decisions, tech stack choices
- `.planning/REQUIREMENTS.md` — FOUND-01 through FOUND-04 requirements for this phase
- `.planning/ROADMAP.md` §Phase 1 — Goal, success criteria, dependency info

### Architecture Research
- `.planning/research/ARCHITECTURE.md` — DSL implementation patterns, compile-time safety, Ecto introspection API details
- `.planning/research/PITFALLS.md` — Known pitfalls from admin framework implementations
- `.planning/research/FEATURES.md` — Feature analysis and ecosystem gap validation

### Technology Stack
- `CLAUDE.md` §Technology Stack — Version-pinned dependency table, alternatives considered, what NOT to use

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None yet — Phase 1 establishes the patterns all subsequent phases follow

### Integration Points
- The DSL macros (`use PhoenixFilament.Resource`) will be consumed by Phase 5 (Resource Abstraction)
- `PhoenixFilament.Schema` introspection will be consumed by Phase 3 (Form Builder), Phase 4 (Table Builder), and Phase 5
- `%Field{}` and `%Column{}` structs will be consumed by Phase 2 (Component Library) for rendering
- Module namespace structure established here constrains all subsequent phases

</code_context>

<specifics>
## Specific Ideas

- DSL syntax should feel like writing an Ecto schema — familiar to any Elixir developer
- Zero-config resource (just `use PhoenixFilament.Resource, schema: X, repo: Y`) is the headline feature
- Smart exclusion of sensitive fields (password hashes, tokens) prevents security mistakes by default

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-31*

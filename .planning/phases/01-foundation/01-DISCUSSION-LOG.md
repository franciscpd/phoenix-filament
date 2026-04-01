# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-31
**Phase:** 01-foundation
**Areas discussed:** DSL Syntax, Module Organization, Ecto Introspection Depth, Test Strategy

---

## DSL Syntax Design

### Q1: DSL Style for Resource Declaration

| Option | Description | Selected |
|--------|-------------|----------|
| Blocos aninhados | FilamentPHP/Ecto style — `form do...end` and `table do...end` blocks with function calls inside | ✓ |
| Callbacks com keyword lists | Backpex/GenServer style — callbacks return keyword lists | |
| Hibrido | DSL blocks for common case, callbacks for dynamic logic | |

**User's choice:** Blocos aninhados (nested blocks)
**Notes:** Most idiomatic for Elixir developers, matches Ecto Schema and Phoenix Router conventions.

### Q2: Internal DSL Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Module attribute accumulator | Each function call accumulates a struct via `Module.put_attribute/3`, collected in `__before_compile__` | ✓ |
| Runtime function builder | Block executes as function returning list of structs, no module attributes | |

**User's choice:** Module attribute accumulator
**Notes:** Same pattern as Ecto Schema — battle-tested, enables compile-time introspection.

### Q3: Auto-Generation Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-generate by default | Zero-config: `use PhoenixFilament.Resource` auto-discovers and generates CRUD | ✓ |
| Require explicit declaration | Must declare `form` and `table` blocks or get compile error | |

**User's choice:** Auto-generate by default
**Notes:** Zero-config is the headline feature. Partial override supported (custom form + auto table).

### Q4: Validation Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Inline opts on field | Validations as keyword opts directly on field declaration | |
| Delegate 100% to Ecto changeset | No validation in DSL, all in changeset | |
| Hybrid: visual hints + changeset | DSL accepts `required: true` for UI hints, real validation in changeset | ✓ |

**User's choice:** Hybrid — visual hints + changeset
**Notes:** Source of truth stays in the changeset. DSL only provides presentation hints (asterisks, etc).

---

## Module Organization

### Q1: Namespace Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Flat by domain | Modules grouped by functional domain directly under PhoenixFilament | ✓ |
| Nested by layer | Grouped by architectural layer (Core, Builders, UI, Shell) | |

**User's choice:** Flat by domain
**Notes:** Simpler imports, easier navigation, follows Phoenix/Ecto conventions.

### Q2: Component Location

| Option | Description | Selected |
|--------|-------------|----------|
| PhoenixFilament.Components | Dedicated namespace with sub-modules by category | ✓ |
| Inline in builders | Components live inside Form/ and Table/ directories | |

**User's choice:** PhoenixFilament.Components
**Notes:** Enables reuse outside builders, supports `use PhoenixFilament.Components` for bulk import.

---

## Ecto Introspection Depth

### Q1: Introspection Level

| Option | Description | Selected |
|--------|-------------|----------|
| Campos + Associations | Fields, types, and associations | |
| Só campos simples | Only `__schema__(:fields)` and types | |
| Tudo (campos + assoc + embeds + virtual) | Maximum introspection: fields, associations, embeds, virtual fields | ✓ |

**User's choice:** Full introspection (everything)
**Notes:** Powers maximum auto-discovery capability from day one. Ambitious but aligned with the "zero-config" vision.

### Q2: Auto-Discovery Exclusions

| Option | Description | Selected |
|--------|-------------|----------|
| Smart exclusion list | Auto-exclude id, __meta__, timestamps, fields ending in _hash/_digest/_token | ✓ |
| Minimal exclusion | Only exclude __meta__ and id | |
| Configurable via NimbleOptions | No smart defaults, dev controls 100% | |

**User's choice:** Smart exclusion list
**Notes:** Prevents security mistakes by default. Override with `include:` / `exclude:` in DSL.

---

## Test Strategy

### Q1: Compile-Time Cascade Testing

| Option | Description | Selected |
|--------|-------------|----------|
| Mix.Utils.stale? test helper | Automated helper: touch schema → compile → assert no cascade | ✓ |
| Manual documented procedure | Document steps for manual verification | |
| Property-based with StreamData | Generate random schemas and verify containment | |

**User's choice:** Automated test helper with Mix.Utils.stale?
**Notes:** Runs in CI, validates the core success criteria automatically.

### Q2: Test App Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Test support modules | Schemas and resources in test/support/, compiled only for tests | ✓ |
| Phoenix umbrella test app | Full Phoenix app in test/test_app/ with router, LiveView, database | |

**User's choice:** Test support modules
**Notes:** Lightweight, fast, follows Ecto's own test setup pattern. Full Phoenix app deferred to Phase 2+ when UI testing is needed.

---

## Claude's Discretion

- Internal struct field names for `%Field{}` and `%Column{}`
- NimbleOptions schema structure for `use PhoenixFilament.Resource` options
- Supervision tree shape for Phase 1
- Exact `Macro.expand_literals/2` usage pattern

## Deferred Ideas

None — discussion stayed within phase scope

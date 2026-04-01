# Project Research Summary

**Project:** PhoenixFilament
**Domain:** Admin panel framework for Phoenix/LiveView (FilamentPHP equivalent for Elixir)
**Researched:** 2026-03-31
**Confidence:** HIGH

## Executive Summary

PhoenixFilament is a runtime admin panel framework for Phoenix 1.8 / LiveView 1.1 applications, targeting the same gap in the Elixir ecosystem that FilamentPHP filled in the Laravel ecosystem. The recommended approach is a layered architecture built bottom-up: Foundation → Component Library → Form Builder → Table Builder → Resource abstraction → Panel + Plugin system → Installer. The framework uses a module-based macro DSL (`use PhoenixFilament.Resource`) where macros register intent at compile time but all field/column declarations are plain data structs evaluated at runtime — giving developers a clean, autocomplete-friendly API while preserving the runtime flexibility needed for authorization, localization, and plugin extensibility.

The key technical bets are: Phoenix 1.8.5 + LiveView 1.1.28 as the target platform (both verified stable as of March 2026), Tailwind v4 + daisyUI 5 for styling (bundled by default in `phx.new` output, requiring no extra setup), Igniter for the installer (AST-based, idempotent, the validated ecosystem pattern), and NimbleOptions for DSL configuration validation. The plugin architecture is the central competitive commitment: the same API available to community plugin authors must be what the framework itself uses for resources, tables, and forms. This is what made FilamentPHP dominant over ActiveAdmin and RailsAdmin.

The primary risks are architectural: macro-induced compile-time dependency cascades that destroy developer feedback loops; excessive code generation that inflates BEAM artifacts; and authorizing only at LiveView mount rather than in every `handle_event` callback (a security vulnerability). All three must be addressed in Phase 1 before any feature work begins. Secondary risks include N+1 queries in table rendering, memory explosion from storing full Ecto structs in socket assigns (use LiveView streams), and Tailwind class purging from dynamic string interpolation. The good news is all risks have known, well-documented mitigations available from day one.

---

## Key Findings

### Recommended Stack

The stack is almost entirely settled by the Phoenix 1.8 defaults and is HIGH confidence across the board. Phoenix 1.8.5 + LiveView 1.1.28 are the correct targets: LiveView 1.1 ships portals (critical for modals escaping overflow containers), colocated JS hooks (eliminates separate hook files), and TypeScript declarations — all directly relevant to an admin component library. Tailwind v4 + daisyUI 5 are bundled in `phx.new` output, meaning host apps already have both configured; the framework simply layers on top. Igniter 0.7.7 is the validated installer pattern (Backpex uses it) and must be declared `optional: true` to stay out of host app production builds.

The one architectural choice that was not settled by ecosystem defaults is the DSL approach: custom `__using__` + `@behaviour` callbacks rather than Spark (the Ash project's DSL builder). Spark is battle-tested but heavy; PhoenixFilament's DSL needs are narrow (two `use` macros). Custom `__using__` is the idiomatic Elixir pattern used by Phoenix Router, Ecto Schema, and Plug. Revisit Spark only if the DSL grows beyond 10 entity types.

**Core technologies:**
- Elixir 1.19.5 / OTP 28: Language runtime — develop and test against these; declare `>= 1.15` as minimum to match Phoenix 1.8 requirements
- Phoenix 1.8.5 + LiveView 1.1.28: Core framework — target these versions; 1.7.x is explicitly wrong target
- Tailwind CSS v4.2.2 + daisyUI 5: Styling — bundled by Phoenix 1.8, OKLCH CSS variable theming built in
- Ecto 3.13.5 / ecto_sql 3.13.5: Data layer — peer dependency; use `__schema__/1` runtime introspection for field type inference
- Igniter 0.7.7: Installer tooling — AST-based, idempotent, optional dependency
- NimbleOptions 1.1.1: DSL option validation — free documentation generation from schemas, used by Backpex

**What not to use:**
- Spark: unnecessary dependency weight for two `use` macros
- Alpine.js: hard dependency; LiveView 1.1 JS commands handle show/hide natively
- Surface UI: non-standard template syntax, superseded by LiveView native `attr`/`slot`
- Ash Framework: core must work with plain Ecto schemas; Ash plugin is a future add-on

### Expected Features

The admin panel feature landscape is well-understood from cross-referencing FilamentPHP v3, Backpex, Kaffy, ActiveAdmin, and Django Admin. The existing Elixir options (Kaffy, Backpex) have documented gaps that define PhoenixFilament's opportunity: Kaffy hits a DX ceiling with config-file-based API; Backpex is module-based but PostgreSQL-only, lacks a plugin architecture, and has limited feature breadth.

**Must have (table stakes — v0.1.0):**
- CRUD resource abstraction — module-based DSL, auto-generated CRUD routes
- Declarative table builder — configurable columns, sort, server-side pagination, text search
- Declarative form builder — 7-8 core field types (text, textarea, number, select, checkbox, date, hidden), changeset integration, inline errors
- Navigation shell — sidebar with resource links, breadcrumbs, top bar with user context
- Auth integration hook — `on_mount` callback that delegates to host app; documented phx.gen.auth pattern
- Basic authorization — per-resource `can_access?/1` callback for resource-level access control
- Delete with confirmation — modal confirm dialog before destructive action
- Flash notifications — success/error after CRUD operations via Phoenix flash system
- Install generator — `mix phx_filament.install` via Igniter
- Core component library — buttons, inputs, badges, modals, cards

**Should have (competitive differentiators — ship in v0.1.0):**
- Plugin architecture — API must exist even if no external plugins ship yet
- Table filters — select + boolean filters (text search alone is insufficient for real operations use)
- Tailwind v4 theming — CSS variable override system for white-label/brand customization

**Defer to v0.2.0+:**
- Custom row actions beyond edit/delete
- Bulk actions with checkbox selection
- Relation managers (HasMany sub-tables on edit page)
- BelongsTo association fields backed by live query
- Global search across resources
- Dashboard widgets
- Notifications inbox (persistent, real-time)
- Infolist / read-only detail view
- Soft delete support (restore, force delete, show-deleted filter)
- File upload and rich text editor field types
- Multi-tenancy

**Anti-features — deliberately excluded:**
- Built-in authentication system (conflicts with host app auth; document 3 integration patterns instead)
- Configuration-file-only API (Kaffy's model hits a DX ceiling; module-based DSL is the right choice)
- Code generation / Torch-style scaffolding (runtime framework pattern is what gives FilamentPHP its power)
- Dead view (non-LiveView) support (doubles surface area, eliminates differentiators)

### Architecture Approach

PhoenixFilament follows a strict bottom-up layered architecture: Foundation (Ecto introspection, config, helpers) → Component Library (stateless HEEx function components) → Form Builder and Table Builder (standalone subsystems, no Panel coupling) → Resource (binds Form + Table to an Ecto schema) → Panel (routing, nav, auth hook, plugin registry) → Generator. The critical boundary rule is that Form Builder and Table Builder must not know about Panel — they are independently composable. The Panel is the only layer that knows about routing and navigation.

The DSL pattern uses `__using__` + `@behaviour` callbacks where field and column declarations are plain structs returned from `form/1` and `table/1` callbacks — not macro calls. This separates declaration (Resource) from rendering (Form Builder + Component Library) and preserves runtime flexibility for authorization and localization. Plugin registration happens at LiveView mount (runtime), not compile time, to avoid cascade recompilation and to enable per-user panel customization.

**Major components:**
1. Foundation — Ecto schema introspection (`__schema__/1`), config reading, shared type helpers; no dependencies
2. Component Library — stateless `Phoenix.Component` function components for all UI primitives; uses daisyUI 5 semantic classes
3. Form Builder — field struct declarations, changeset resolution, form HTML rendering; standalone, no Panel knowledge
4. Table Builder — column/filter declarations, Ecto query building with pagination and sort; standalone, no Panel knowledge
5. Resource — binds Form Builder + Table Builder to an Ecto schema; generates CRUD LiveView modules via thin delegation
6. Panel — Phoenix router scope, sidebar nav, auth hook, plugin registry; orchestrates Resources into a complete admin UI
7. Plugin Registry — behaviour contract (`register/1`, `boot/1`); the built-in Resource system is itself a plugin
8. Mix Generator — Igniter-based `mix phx_filament.install`; patches router, imports CSS/JS, injects config

**State ownership model:** The Panel-level LiveView holds all socket state. Table and Form are function components (stateless). LiveComponents are used only when truly isolated state benefits UX (e.g., inline editing). Plugin state is per-socket (computed in `on_mount`), not global, aligning with LiveView's process isolation model.

### Critical Pitfalls

1. **Macro-induced compile-time dependency cascades** — Use `Macro.expand_literals/2` for module references in macro arguments; delay schema inspection to runtime via `Code.ensure_loaded!/1`. Benchmark compile times with 50+ resources before shipping. This must be solved in Phase 1 — retrofitting is painful.

2. **Excessive code generation in macros** — Move all logic out of `quote/1` blocks into real framework functions. Generated code should be thin delegation: `def handle_event(e, p, s), do: PhoenixFilament.Resource.handle_event(__resource__(), e, p, s)`. Only generate the `__resource__/1` function that returns the DSL config struct.

3. **Authorization only at LiveView mount** — Every generated `handle_event` must call `authorize!(socket, :action, record)` before performing writes. LiveView's persistent connection means mount-only auth is a security vulnerability. Implement `live_socket_id` + broadcast-based session revocation so admin access can be revoked in real time.

4. **Storing full Ecto structs in socket assigns** — Use LiveView streams (`stream/3`) for all list views by default. Paginate at the database level. Never load more than one page of data into assigns. Design this into the Table Builder from day one.

5. **Tailwind CSS dynamic class purging** — Never use string interpolation for Tailwind class names in framework or plugin code (`"bg-#{color}-500"` will be purged). Always use complete class strings and switch between them. Add all used variants to the Tailwind safelist in installer-generated config.

**Additional important pitfalls:**
- N+1 queries: aggregate `preload:` declarations from column definitions into the data-loading query
- Blocking LiveView process with slow queries: use `Task.async` + `handle_info` for data loading
- Plugin API instability: mark as `@experimental` in v0.1.0; use `@optional_callbacks` for extensibility
- HTML empty association lists: use Ecto `drop_param`/`sort_param` (Ecto 3.10+) or hidden sentinel inputs
- Complex installer requiring manual steps: Igniter handles code injection automatically; verify with blank-app integration test

---

## Implications for Roadmap

The architecture imposes a strict bottom-up build order with no flexibility for reordering. The feature dependency graph from FEATURES.md confirms this order: auth hook → navigation shell → resource abstraction → table builder → form builder → plugin architecture → generator.

### Phase 1: Foundation and Component Library

**Rationale:** Everything depends on this. Foundation provides Ecto introspection and config primitives used by all upper layers. Component Library provides the HEEx function components that Form Builder and Table Builder render into. Neither has dependencies — they must come first.

**Delivers:** All UI primitives (buttons, inputs, badges, modals, cards, layout shell), Ecto schema introspection helpers, config reading infrastructure.

**Addresses:** Core component library (table stakes #10 from FEATURES.md); theming system via Tailwind v4 CSS variables (differentiator #5).

**Avoids:**
- Tailwind class purging: establish no-interpolation rule from the first component written
- Component render inefficiency: explicit `attr` declarations from day one; never spread assigns map
- Alpine.js DOM state loss: use LiveView JS commands for show/hide instead of Alpine
- Overly broad `use` macro imports: document exactly what each `use` injects; minimize injection scope

**Research flag:** Standard patterns. Phoenix.Component `attr`/`slot`, daisyUI 5 class names, and Tailwind v4 CSS variable theming are all well-documented. No phase research needed.

---

### Phase 2: Form Builder (Standalone)

**Rationale:** Form Builder depends only on Component Library and Foundation. Building it standalone (no Panel coupling) enforces the correct boundary and produces a testable, independently useful subsystem. Form is the #1 DX differentiator among admin frameworks.

**Delivers:** Field struct definitions for all 7-8 v0.1.0 field types (text, textarea, number, select, checkbox, date, hidden), Ecto changeset integration, inline field-level error rendering, `form/1` callback pattern.

**Addresses:** Declarative form builder (table stakes #3), Ecto changeset integration (table stakes #4).

**Avoids:**
- Macro-heavy field declarations: fields are plain `%Field{}` structs returned from a callback, not macro calls
- Blocking LiveView process: design the form validation path with async patterns from the start
- Empty association encoding: use Ecto `drop_param`/`sort_param` in the association field implementation

**Research flag:** Standard patterns. Ecto changeset integration with Phoenix forms is well-documented. No phase research needed.

---

### Phase 3: Table Builder (Standalone)

**Rationale:** Table Builder depends only on Component Library and Foundation. Like Form Builder, it must be built standalone before being integrated into Resource. The table/index view is the most-used page in any admin — its quality determines first impressions.

**Delivers:** Column struct definitions, server-side pagination, user-controlled sort, text search, filter infrastructure (select + boolean filters), Ecto query builder that aggregates preloads from column declarations.

**Addresses:** Declarative table builder (table stakes #2), table filters (differentiator #7).

**Avoids:**
- N+1 queries: aggregate `preload:` declarations at the column definition level; apply in the data-loading query
- Memory explosion from assigns: use LiveView streams (`stream/3`) as the default for all list views; not optional
- Blocking LiveView process: async data loading with `Task.async` + `handle_info` as the standard pattern

**Research flag:** Standard patterns. LiveView streams are well-documented. Ecto query composition is well-understood. No phase research needed.

---

### Phase 4: Resource Abstraction

**Rationale:** Resource is the central user-facing API. It can only be built after Form Builder and Table Builder exist because it binds them together. This is the `use PhoenixFilament.Resource` macro that users interact with daily — its ergonomics determine whether the framework feels good or bad.

**Delivers:** `use PhoenixFilament.Resource` macro with `__using__` + `@behaviour` implementation, `__resource__/1` runtime config function, thin delegation pattern for CRUD LiveView event handlers, authorization callbacks (`can_access?/1`, `authorize!/3`).

**Addresses:** CRUD resource abstraction (table stakes #1), basic authorization (table stakes #7), delete with confirmation (table stakes #9).

**Avoids:**
- Macro-induced compile-time dependency cascades: use `Macro.expand_literals/2`; schema inspection at runtime only
- Excessive code generation: thin delegation to real framework functions; benchmark generated code size
- Authorization only at mount: every `handle_event` calls `authorize!/3` before performing writes

**Research flag:** Needs research during planning. The exact macro design (how `__using__` injects behaviour, how `__resource__/1` is structured, how thin delegation interacts with LiveView lifecycle) benefits from deeper investigation of Backpex's LiveResource implementation and Elixir meta-programming anti-patterns documentation.

---

### Phase 5: Panel Shell, Routing, and Auth Hook

**Rationale:** Panel is the outermost layer — the navigation shell, router scope, and auth hook that makes Resources accessible as a coherent admin UI. Cannot be built until Resources exist. This is the "panel" in admin panel.

**Delivers:** `use PhoenixFilament.Panel` macro, `phoenix_filament_panel/1` router macro (wraps `live_session`), `PhoenixFilament.AuthHook` for `on_mount` auth delegation, sidebar navigation with resource links and active state, breadcrumbs, top bar with user context, responsive mobile layout, flash notifications.

**Addresses:** Navigation shell (table stakes #5), authentication integration (table stakes #6), flash notifications (table stakes #10).

**Avoids:**
- Global process state for panel config: compute panel state per-socket in `on_mount`, not in GenServer/ETS
- Compile-time plugin resolution: plugin list resolved at runtime mount, not at compile time
- Session revocation: implement `live_socket_id` + broadcast disconnect so revoking admin access takes effect immediately

**Research flag:** Standard patterns for routing and auth. LiveView `live_session` + `on_mount` patterns are well-documented. No phase research needed.

---

### Phase 6: Plugin Architecture

**Rationale:** Plugin system requires Panel to have a registration surface. Must be built after Panel. The key constraint from PROJECT.md is that the plugin API must be what the framework itself uses — so the built-in Resource system is retroactively registered as a plugin. This validates the API before any external plugin is written.

**Delivers:** `PhoenixFilament.Plugin` behaviour with `id/0`, `register/1`, `boot/1` callbacks and optional `resources/0`, `pages/0`, `nav_items/0`; `PhoenixFilament.ResourcePlugin` (built-in resource system as a plugin); plugin registration in Panel `on_mount`; public/private module boundary (`PhoenixFilament.*` vs `PhoenixFilament.Internal.*`).

**Addresses:** Plugin architecture (differentiator #1 — the central competitive commitment).

**Avoids:**
- Plugin API instability: mark as `@experimental` in v0.1.0 documentation; use `@optional_callbacks` for all extensibility hooks
- Plugin dependency on internals: establish `PhoenixFilament.Internal.*` namespace and `@moduledoc false` from day one
- Compile-time plugin resolution: plugins are per-socket runtime state, not compile-time modules

**Research flag:** Needs research during planning. Plugin behaviour contract design — particularly how plugins interact with the Form Builder and Table Builder subsystems without coupling to internals — benefits from deeper investigation of the FilamentPHP plugin panel API and Elixir plugin pattern implementations.

---

### Phase 7: Install Generator and Distribution

**Rationale:** Generator can only be built after all above components exist (it scaffolds a working setup). This is the last phase because it validates the entire integration story: a blank `mix phx.new` app + `mix phx_filament.install` must produce a working admin panel.

**Delivers:** `mix phx_filament.install` Igniter task (patches `router.ex`, imports CSS/JS, injects config), `mix phx_filament.gen.resource` scaffold generator (optional), ExDoc documentation, Hex package publication workflow, integration test suite against blank Phoenix app.

**Addresses:** Install generator (table stakes #8).

**Avoids:**
- Installer requiring invasive manual changes: Igniter handles all code injection; the goal is zero manual steps
- Missing smoke test: integration test that runs `mix phx_filament.install` on a blank `mix phx.new` app and verifies the result compiles and renders

**Research flag:** Standard patterns. Igniter API is well-documented. ExDoc is standard. No phase research needed.

---

### Phase Ordering Rationale

- The bottom-up order (Foundation → Component Library → Form → Table → Resource → Panel → Plugin → Generator) is mandated by the architecture's dependency graph. Skipping ahead forces placeholder APIs that create rework.
- Form Builder and Table Builder are built in parallel (both depend only on Foundation + Component Library), providing the fastest path to Resource abstraction.
- Plugin architecture comes after Panel because Panel provides the registration surface. The "internals as plugins" design must be retroactively applied when building Phase 6 — this is a known constraint, not a surprise.
- Generator comes last because it validates the complete integration story. Building it early would mean scaffolding an incomplete system.
- The pitfall pattern is consistent: Phase 1 decisions (macro design, component boundaries, no Tailwind interpolation) have the highest leverage. Every Phase 1 shortcut creates rework across all later phases.

### Research Flags

Phases needing deeper research during planning:

- **Phase 4 (Resource Abstraction):** The macro DSL design is the highest-risk architectural decision. The `__using__` implementation, `Macro.expand_literals/2` usage, thin delegation pattern, and authorization lifecycle need detailed design before implementation. Reference: Backpex `Backpex.LiveResource` source, Elixir meta-programming anti-patterns docs.
- **Phase 6 (Plugin Architecture):** The plugin behaviour contract design — especially how plugins extend Form Builder and Table Builder without coupling to internals — needs investigation. Reference: FilamentPHP panel plugin docs, Elixir plugin pattern implementations.

Phases with standard, well-documented patterns (skip research-phase):

- **Phase 1 (Foundation + Component Library):** Phoenix.Component, daisyUI 5, Tailwind v4 CSS variables are all thoroughly documented.
- **Phase 2 (Form Builder):** Ecto changeset + Phoenix form integration is a well-trodden path.
- **Phase 3 (Table Builder):** LiveView streams, Ecto query composition, and server-side pagination are standard patterns.
- **Phase 5 (Panel + Auth Hook):** LiveView `live_session` + `on_mount` patterns are well-documented.
- **Phase 7 (Generator):** Igniter API and ExDoc are straightforward.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified via hex.pm and official sources as of March 2026. Single medium-confidence finding: the decision not to use Spark is a sound inference but not a direct official recommendation. |
| Features | HIGH | Cross-referenced FilamentPHP v3 docs, Backpex, Kaffy, ActiveAdmin, Django Admin. Feature gaps in existing Elixir options are directly observable. MVP scope recommendation is opinionated and matches ecosystem evidence. |
| Architecture | MEDIUM-HIGH | FilamentPHP architecture confirmed via DeepWiki (source-based). Elixir translation patterns (macro DSL, plugin behaviour, routing macros) inferred from ecosystem analogues with HIGH confidence. Exact macro implementation details need validation during Phase 4 planning. |
| Pitfalls | MEDIUM-HIGH | Critical pitfalls (compile cascades, excessive generation, auth-only-at-mount) are documented in official Elixir sources. Moderate pitfalls (streams, N+1, Tailwind purging) are verified against official docs. Minor pitfalls from community sources but consistent with official guidance. |

**Overall confidence:** HIGH

### Gaps to Address

- **Exact `Macro.expand_literals/2` usage pattern for module references in DSL macros:** Theory is well-documented; exact application to the `schema:` option in `use PhoenixFilament.Resource` needs a proof-of-concept implementation and compile-time benchmark before Phase 4 begins. Validate by creating a test app with 50 resource modules and measuring recompile times after touching a schema.

- **Plugin behaviour contract scope:** The initial plugin API must be narrow enough to remain stable but broad enough to enable the built-in Resource system to be implemented as a plugin. This is a design constraint that needs detailed upfront specification before Phase 6 begins. The risk is building the API before understanding what the built-in plugins actually need.

- **Igniter API compatibility with host app router patterns:** Igniter patches ASTs, and Phoenix router files have varied structures. The `mix phx_filament.install` task needs to handle both standard `phx.new` output and common customizations (multiple pipelines, authentication plugs already present). Validate with the Igniter test harness before Phase 7 scope is finalized.

- **DB-agnostic query building:** The framework must work with both Postgrex (PostgreSQL) and MyXQL (MySQL). Ecto SQL abstracts most of this, but there may be edge cases in the filter system (e.g., ILIKE vs LIKE for case-insensitive search). Needs explicit validation during Phase 3 (Table Builder).

---

## Sources

### Primary (HIGH confidence)

- hex.pm/packages/phoenix — Phoenix 1.8.5, March 5, 2026
- hex.pm/packages/phoenix_live_view — LiveView 1.1.28, March 27, 2026
- phoenixframework.org/blog/phoenix-1-8-released — daisyUI + Tailwind v4 bundled by default
- phoenixframework.org/blog/phoenix-liveview-1-1-released — portals, colocated hooks, keyed comprehensions
- github.com/tailwindlabs/tailwindcss/releases — Tailwind v4.2.2, March 18, 2026
- hex.pm/packages/igniter — Igniter 0.7.7, March 24, 2026
- hex.pm/packages/backpex — Backpex 0.18.0, March 26, 2026 (ecosystem pattern reference)
- hexdocs.pm/elixir/macro-anti-patterns.html — compile cascade and excessive generation pitfalls
- hexdocs.pm/phoenix_live_view/security-model.html — LiveView auth model, mount-only auth vulnerability
- hexdocs.pm/elixir/library-guidelines.html — library authoring conventions
- filamentphp.com/docs/3.x — resource, form, table, relation manager, plugin architecture docs
- deepwiki.com/filamentphp/filament/1.2-architecture — FilamentPHP component dependency graph
- daisyui.com/docs/v5 — CSS variable theming, `@plugin` configuration
- hexdocs.pm/ecto/Ecto.Schema.html — `__schema__/1` runtime introspection API

### Secondary (MEDIUM confidence)

- elixir-toolbox.dev/projects/phoenix/phx_admin_interfaces — admin framework ecosystem comparison
- elixirmerge.com/p/evaluation-of-phoenix-admin-frameworks-for-elixir — Kaffy/Backpex DX evaluation
- github.com/aesmail/kaffy — config-file API pattern analysis
- dockyard.com/blog/2022/08/18/liveview-rendering-pitfalls-and-how-to-avoid-them — component boundary pitfalls
- blog.appsignal.com/2022/06/28/liveview-assigns-three-common-pitfalls-and-their-solutions — assign pitfalls
- medium.com/multiverse-tech — Elixir compile time analysis (consistent with official docs)
- blogs.perficient.com — Tailwind CSS safelist behavior (consistent with Tailwind docs)
- james-carr.org/posts/2024-08-27-phoenix-admin-with-backpex — Backpex practitioner review
- joekoski.com/blog/2025/12/01/ash_dsl_1 — Ash DSL lessons applicable to macro design

### Tertiary (LOW-MEDIUM confidence)

- dev.to/tonegabes — FilamentPHP honest review (individual practitioner, cross-ecosystem comparison)
- hexshift.medium.com — LiveView common mistakes (community compilation, patterns verified against official docs)
- rocket-science.ru/hacking/2022/02/12/plugins-in-elixir-apps — Elixir plugin patterns

---

*Research completed: 2026-03-31*
*Ready for roadmap: yes*

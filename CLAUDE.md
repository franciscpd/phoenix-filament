# CLAUDE.md

## .planning/ — Single Source of Truth

All planning artifacts MUST go in `.planning/`. Never outside it.

```
.planning/
└── phases/
    └── {N}-{slug}/          ← one folder per GSD phase (e.g. 01-auth)
        ├── DISCUSS.md        ← gsd:discuss output
        ├── BRAINSTORM.md     ← superpowers:brainstorm output
        ├── PLAN.md           ← superpowers:write-plan output
        ├── PROGRESS.md       ← superpowers:execute-plan tracking
        └── VERIFY.md         ← superpowers:requesting-code-review output
```

Before writing any artifact, MUST identify the active GSD phase and resolve its folder: `.planning/phases/{N}-{slug}/`. Create the folder if it does not exist. All Superpowers outputs for that phase go inside it.

---

## Workflow — Follow This Order Exactly

```
gsd:discuss → brainstorm → write-plan → execute-plan → gsd:verify
```

> `$PHASE` = active GSD phase folder, e.g. `.planning/phases/01-auth`

### Phase 1 — discuss
- Trigger: any new feature, task or bug with unclear scope
- MUST capture: requirements, scope, what's out of scope, priority
- MUST save output to `$PHASE/DISCUSS.md`
- MUST NOT proceed without explicit user approval

### Phase 2 — brainstorm
- Trigger: automatically after discuss approval
- MUST invoke `/superpowers:brainstorm` using `$PHASE/DISCUSS.md` or `$PHASE/{N}-CONTEXT.md` as context
- Focus: technical approach, architecture, trade-offs, Laravel patterns
- MUST save output to `$PHASE/BRAINSTORM.md`
- MUST NOT proceed without explicit user approval

### Phase 3 — write-plan
- Trigger: automatically after brainstorm approval
- MUST invoke `/superpowers:write-plan` using `$PHASE/DISCUSS.md` or `$PHASE/{N}-CONTEXT.md` + `$PHASE/BRAINSTORM.md` as input
- Output MUST include: affected files, atomic tasks, verify commands, commit messages
- MUST save output to `$PHASE/PLAN.md`
- MUST NOT proceed without explicit user approval

### Phase 4 — execute-plan
- Trigger: automatically after plan approval
- MUST invoke `/superpowers:execute-plan` using `$PHASE/PLAN.md`
- MUST follow TDD: write failing test → implement → pass (RED → GREEN → REFACTOR)
- MUST track progress in `$PHASE/PROGRESS.md`
- MUST commit atomically per logical task immediately after verify passes

### Phase 5 — verify
- Trigger: automatically after execute-plan completes
- MUST invoke `/superpowers:requesting-code-review`
- MUST run `php artisan test && php artisan pint` — nothing is done without passing evidence
- MUST save output to `$PHASE/VERIFY.md`


## Skip Rules

| Situation | Skip |
|---|---|
| Scope is already clear | Skip discuss, start at brainstorm |
| Approach is already clear | Skip brainstorm, start at write-plan |
| Small well-defined task | Skip discuss + brainstorm, start at write-plan |
| Known bug with clear fix | Use `/superpowers:systematic-debugging` directly |

---

## Commits

```
type(scope): description
```
Types: `feat | fix | refactor | test | docs | style | chore`
One commit per logical task. Never commit broken code.

---

## Rules

- Bugs before features. Max 2–3 WIP tasks.
- Never deploy without explicit approval.
- Never skip phases without a skip rule justifying it.
- Always ask when scope or approach is unclear.

<!-- GSD:project-start source:PROJECT.md -->
## Project

**PhoenixFilament**

PhoenixFilament is a rapid application development framework for the Elixir/Phoenix ecosystem, inspired by FilamentPHP. It provides declarative DSL-based builders for forms, tables, and CRUD resources — all powered by LiveView and styled with Tailwind CSS. It enables developers to build admin panels and general-purpose interfaces while staying focused on business logic.

**Core Value:** Developers can go from an Ecto schema to a fully functional, beautiful admin interface in minutes — with a declarative, idiomatic Elixir API that feels native to the Phoenix ecosystem.

### Constraints

- **Tech stack**: Elixir, Phoenix, LiveView, Tailwind CSS v4, Ecto — no external JS frameworks
- **Distribution**: Hex package with mix task installer (`mix phx_filament.install`)
- **Compatibility**: Must work with standard phx.gen.auth output and common auth libraries
- **API design**: Declarative macro-based DSL — must feel idiomatic to Elixir developers
- **Plugin-first**: Core features should be built using the same plugin API available to the community
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Runtime
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.19.5 | Language runtime | Latest stable; required by Phoenix 1.8 ecosystem; ships with improved type checking and up to 4x faster compilation. Minimum is 1.15 per Phoenix 1.8 docs, but 1.19 is the recommended floor for new projects. |
| Erlang/OTP | 28 | BEAM runtime | Latest stable paired with Elixir 1.19; Phoenix 1.8 requires OTP 25+ minimum. OTP 28 delivers async signal handling improvements relevant to high-concurrency LiveView workloads. |
### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix | 1.8.5 | Web framework | Latest stable (March 5, 2026). Phoenix 1.8 ships Tailwind v4 + daisyUI 5 out of the box, introduces first-class Scopes (secure data access patterns), simplified single-root layout, and magic-link auth generator. This is the right target version — do not target 1.7.x. |
| Phoenix LiveView | 1.1.28 | Real-time UI | Latest stable (March 27, 2026). LiveView 1.1 introduces portals (critical for modals/dropdowns that must escape overflow containers), colocated JS hooks (eliminates separate hook files), keyed comprehensions (efficient list rendering without manual streams), and TypeScript declarations. All of these directly benefit an admin framework component library. |
| Phoenix HTML | 4.1+ | HTML helpers | Bundled with Phoenix; provides `form_for`, `inputs_for`, and html-safe primitives used by form builder. |
### Styling
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Tailwind CSS | 4.2.2 | Utility CSS framework | Latest stable (March 18, 2026). Phoenix 1.8 bundles it by default. v4 rewrote to CSS-native approach: zero-config, single `@import` line, CSS `@property` registration, and CSS variables for theming. The PROJECT.md explicitly calls for Tailwind v4 + CSS variables for the theming system — this is the right choice. |
| daisyUI | 5.x | Component/theme plugin | Bundled by Phoenix 1.8 phx.new. Provides semantic class names (btn, badge, modal, table, etc.) with a OKLCH-based theming system built on CSS variables — directly supports the PROJECT.md requirement for CSS variable theming. daisyUI 5 has zero JS dependencies and is configured purely in CSS via `@plugin`. Use it for the Component Library layer's base styling. |
| phoenixframework/tailwind | latest | Tailwind CLI wrapper | The official Elixir hex wrapper for the Tailwind standalone CLI binary. Manages the Tailwind build step as a Mix task. Required by Phoenix 1.8 generator output — include in dev/test deps. |
### Data Layer
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto | 3.13.5 | Data mapping and query DSL | Latest stable (November 2025). PhoenixFilament uses Ecto schema introspection (`__schema__/1`) to auto-infer field types and associations. This is a runtime API, not compile-time — no coupling risk. Ecto is a required peer dependency, not bundled. |
| Ecto SQL | 3.13.5 | SQL adapter foundation | Latest stable (March 3, 2026). Users bring their own adapter (Postgrex for Postgres, MyXQL for MySQL). The framework declares `ecto_sql ~> 3.6` as a dependency; users supply the adapter. |
### Generator / Installer Tooling
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Igniter | 0.7.7 | Smart code-patching installer | Latest stable (March 24, 2026). The standard approach for `mix phx_filament.install` in the 2025/2026 ecosystem. Igniter manipulates ASTs (not text), making it idempotent and composable. Declare it as an optional dependency (`optional: true`) so it is not included in host app production builds. Backpex uses Igniter for its installer — this is the validated pattern for Phoenix library installers. |
| ExDoc | 0.40.1 | Documentation generation | Latest stable (January 2026). The standard for Hex package docs. Publish to HexDocs automatically on hex release. Use `@moduledoc`, `@doc`, and `@spec` throughout — library consumers depend on this. |
### Supporting Libraries (Framework Internals)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NimbleOptions | 1.1.1 | Schema validation for options | Use to validate keyword list arguments passed to `use PhoenixFilament.Resource`, `use PhoenixFilament.Panel`, etc. Provides free documentation generation from schemas. Do NOT use for field definition structs — those are plain Elixir structs. |
| Jason | 1.2+ | JSON encoding/decoding | Required for LiveView JS interop and any API-mode features. Phoenix already depends on it; include as a transitive dep. |
| Gettext | 0.26+ | Internationalization | Use for all user-facing strings inside the framework (labels, error messages, flash text). Host apps can override translations via their own Gettext backend. |
| Phoenix Ecto | 4.4+ | Ecto + Phoenix integration | Provides `Ecto.Changeset` → HTML error rendering helpers. Used by Form Builder to display changeset errors. |
## Existing Ecosystem — What to Learn From (Not Use)
### Backpex v0.18.0 (actively maintained, March 2026)
- Uses NimbleOptions extensively for option validation — adopt this pattern
- Declares `phoenix ~> 1.0 and < 1.9.0` — good version pinning example
- Requires Postgrex (PostgreSQL-only) — PhoenixFilament should be DB-agnostic
- Does NOT support a declarative DSL / macro approach — uses callback-heavy configuration maps
- Has no plugin architecture — PhoenixFilament differentiates here
### live_admin v0.12.1 (actively maintained, March 28, 2026)
- Low weekly download count vs Torch/Kaffy — less community adoption
- API is more raw/low-level, not declarative
- Multi-tenant design (scoped queries) is a useful pattern to study
### Kaffy v0.11.0 (last updated October 2025)
### Torch v6.0.0 (actively maintained, 1 day ago as of March 2026)
### ex_admin, alkemist, adminable
## Alternatives Considered
### DSL Implementation: Spark vs Custom Macros vs NimbleOptions
| Approach | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| DSL for Resource/Panel | Custom `__using__` + behaviour callbacks | Spark (ash-project/spark v2.6.1) | Spark is battle-tested (powers Ash Framework) but introduces a heavy dependency with its own compilation model. PhoenixFilament's DSL needs are narrow: one `use PhoenixFilament.Resource` macro and one `use PhoenixFilament.Panel` macro. Custom `__using__` with `@behaviour` is the idiomatic Elixir approach here and matches how Phoenix Router, Ecto Schema, and Plug work. Spark would be appropriate if building a framework of frameworks (like Ash). |
| Options validation | NimbleOptions 1.1.1 | Ecto changesets | NimbleOptions is the right tool for keyword-list config validation with doc generation. Ecto changesets are for user input (form data), not library config schemas. |
### Styling: Tailwind v4 + daisyUI vs Custom CSS vs Tailwind v4 alone
| Approach | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Base styling | Tailwind v4 + daisyUI 5 | Tailwind v4 alone (manual utility classes) | daisyUI 5 provides semantic class names (`.btn`, `.badge`, `.table`, `.modal-box`) that reduce the number of Tailwind utility classes the framework hardcodes. This means fewer hard-coded class strings in HEEx templates, and the theming system is built-in. Phoenix 1.8 ships daisyUI by default — this is the direction the ecosystem is moving. |
| Theming | CSS variables via daisyUI `@plugin` | Tailwind theme config file | Tailwind v4 moved configuration from `tailwind.config.js` to CSS files (`@plugin`, `@theme`). daisyUI 5 follows this convention. CSS variables are the right approach for runtime theming (theme switching without rebuild). |
### Component Strategy: Function Components vs LiveComponents vs Surface
| Approach | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Component type | Phoenix.Component function components | Phoenix.LiveComponent (stateful) | Function components are stateless, render-only, and have zero process overhead. LiveView 1.1's attribute/slot compile-time validation makes them type-safe. Use LiveComponents ONLY for the top-level Panel/Resource LiveViews that hold socket state. Deeply nested LiveComponents create message-passing overhead with no benefit for purely visual components. |
| Component DSL | HEEx + attr/slot declarations | Surface UI (surface-ui/surface) | Surface adds a compile step and different template syntax. HEEx with attr/slot (native to LiveView 1.0+) provides the same type-safety with zero extra dependencies. Surface's innovation was largely merged into core LiveView. |
### Installer: Igniter vs Custom Mix Task
| Approach | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Install mechanism | Igniter (optional dep) | Custom Mix.Task reading/writing files | Igniter is AST-based (idempotent, composable, safe to re-run). Custom file-manipulation Mix tasks are fragile (regex-based patching breaks on edge cases). Backpex already uses Igniter — this is the validated pattern. Mark as `optional: true` to keep it out of production builds. |
## Installation
### mix.exs — Framework Package Dependencies
### Host App Prerequisites
- Tailwind CSS v4 (via `phoenixframework/tailwind` hex wrapper)
- daisyUI 5 (configured in `assets/css/app.css`)
- esbuild (for JS bundling)
- Ecto + Postgrex (or MySQL adapter)
- Phoenix LiveView 1.1
## Version Compatibility Matrix
| PhoenixFilament | Phoenix | LiveView | Elixir | OTP |
|-----------------|---------|----------|--------|-----|
| 0.1.x (target) | 1.8.x | 1.1.x | >= 1.15 | >= 25 |
## What NOT to Use and Why
| Library | Decision | Reason |
|---------|----------|--------|
| Spark (ash-project) | Do not use | Too heavy a dependency for the narrow DSL needs of PhoenixFilament. Would force consumers to also bring in Spark. Custom `__using__` + `@behaviour` is sufficient and idiomatic. Revisit only if the DSL grows to 10+ entity types. |
| Alpine.js | Do not use as hard dependency | Backpex requires Alpine.js. PhoenixFilament should not. LiveView 1.1 JS commands (`Phoenix.LiveView.JS`) handle show/hide, class toggling, and transitions natively. Colocated hooks handle any remaining JS needs. Alpine.js can be optionally supported but must not be required. |
| Bootstrap / Bulma | Do not use | Tailwind v4 + daisyUI 5 is the default Phoenix 1.8 stack. Using a different CSS framework would conflict with host apps. |
| Surface UI | Do not use | Separate compile step, non-standard template syntax, no longer necessary since LiveView native attr/slot covers the same use cases. |
| Ash Framework | Do not use | PhoenixFilament must work with plain Ecto schemas. Requiring Ash would exclude the majority of the ecosystem. A future optional plugin for Ash integration is appropriate, but the core must be Ash-free. |
| ex_admin / ExAdmin | Do not reference | Dead project (6 years unmaintained). No usable patterns. |
## Key Ecosystem Signals (Confidence Assessment)
| Area | Confidence | Evidence |
|------|------------|---------|
| Phoenix 1.8.5 as target | HIGH | Verified hex.pm March 5, 2026 |
| LiveView 1.1.28 as target | HIGH | Verified hex.pm March 27, 2026 |
| Tailwind v4.2.2 | HIGH | Verified GitHub releases March 18, 2026; bundled in Phoenix 1.8 |
| daisyUI 5 as base styling | HIGH | Phoenix 1.8 ships it by default per official blog post |
| Igniter for installer | HIGH | Backpex v0.18.0 uses it; standard approach per Elixir Forum discussions |
| NimbleOptions for config validation | HIGH | Used by Backpex, documented by Elixir Merge, official Elixir patterns |
| Elixir 1.19.5 / OTP 28 | HIGH | Verified elixir-lang.org install page March 2026 |
| Ecto 3.13.5 / ecto_sql 3.13.5 | HIGH | Verified hex.pm |
| No Spark dependency needed | MEDIUM | Evidence: Spark is appropriate for complex multi-entity DSLs (Ash Framework); PhoenixFilament needs 2 `use` macros — insufficient complexity to justify. Inference from Elixir official DSL docs and Spark documentation. |
| daisyUI theming via CSS variables | HIGH | Verified daisyUI 5 docs: configured via `@plugin` in CSS, zero JS dependencies |
## Sources
- [hex.pm/packages/phoenix](https://hex.pm/packages/phoenix) — Phoenix 1.8.5, March 5, 2026
- [hex.pm/packages/phoenix_live_view](https://hex.pm/packages/phoenix_live_view) — LiveView 1.1.28, March 27, 2026
- [Phoenix 1.8 released — phoenixframework.org](https://phoenixframework.org/blog/phoenix-1-8-released) — daisyUI + Tailwind v4 bundled
- [Phoenix LiveView 1.1 released — phoenixframework.org](https://www.phoenixframework.org/blog/phoenix-liveview-1-1-released) — portals, colocated hooks, keyed comprehensions
- [github.com/tailwindlabs/tailwindcss/releases](https://github.com/tailwindlabs/tailwindcss/releases) — Tailwind v4.2.2, March 18, 2026
- [hex.pm/packages/backpex](https://hex.pm/packages/backpex) — Backpex 0.18.0, March 26, 2026; 13 deps verified
- [hex.pm/packages/live_admin](https://hex.pm/packages/live_admin) — live_admin 0.12.1
- [hex.pm/packages/kaffy](https://hex.pm/packages/kaffy) — Kaffy 0.11.0, October 2025
- [hex.pm/packages/torch](https://hex.pm/packages/torch) — Torch 6.0.0
- [hex.pm/packages/ecto](https://hex.pm/packages/ecto) — Ecto 3.13.5, November 2025
- [hex.pm/packages/ecto_sql](https://hex.pm/packages/ecto_sql) — ecto_sql 3.13.5, March 3, 2026
- [hex.pm/packages/igniter](https://hex.pm/packages/igniter) — Igniter 0.7.7, March 24, 2026
- [hex.pm/packages/spark](https://hex.pm/packages/spark) — Spark 2.6.1, March 25, 2026 (consulted, not adopted)
- [hex.pm/packages/nimble_options](https://hex.pm/packages/nimble_options) — NimbleOptions 1.1.1
- [hex.pm/packages/petal_components](https://hex.pm/packages/petal_components) — Petal Components 3.0.2, March 21, 2026 (reference only)
- [elixir-lang.org/install.html](https://elixir-lang.org/install.html) — Elixir 1.19.5 / OTP 28 recommended, March 2026
- [hexdocs.pm/phoenix/installation.html](https://hexdocs.pm/phoenix/installation.html) — Phoenix 1.8 requires Elixir 1.15+, OTP 24+
- [elixir-toolbox.dev/projects/phoenix/phx_admin_interfaces](https://elixir-toolbox.dev/projects/phoenix/phx_admin_interfaces) — Admin framework ecosystem comparison
- [daisyui.com/docs/v5](https://daisyui.com/docs/v5/) — daisyUI 5 CSS variable theming, `@plugin` configuration
- [github.com/ash-project/igniter](https://github.com/ash-project/igniter) — Igniter AST-based project patching
- [hexdocs.pm/elixir/library-guidelines.html](https://hexdocs.pm/elixir/library-guidelines.html) — Official Elixir library authoring guidelines
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

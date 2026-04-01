# Technology Stack

**Project:** PhoenixFilament
**Researched:** 2026-03-31
**Overall Confidence:** HIGH (all versions verified via hex.pm and official docs as of March 2026)

---

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

---

## Existing Ecosystem — What to Learn From (Not Use)

These are the existing Phoenix admin frameworks. We are building a new framework, not wrapping these. Understand their patterns and pitfalls.

### Backpex v0.18.0 (actively maintained, March 2026)

**Confidence:** HIGH (verified via hex.pm)

The most mature LiveView admin panel in the ecosystem. Uses a `LiveResource` behaviour pattern where you define a module that implements callbacks for columns, fields, and actions. Requires Alpine.js + daisyUI + Tailwind. Key learnings:

- Uses NimbleOptions extensively for option validation — adopt this pattern
- Declares `phoenix ~> 1.0 and < 1.9.0` — good version pinning example
- Requires Postgrex (PostgreSQL-only) — PhoenixFilament should be DB-agnostic
- Does NOT support a declarative DSL / macro approach — uses callback-heavy configuration maps
- Has no plugin architecture — PhoenixFilament differentiates here

**Verdict:** Study its Ecto query builder and filter system. Do not copy its configuration API style (too imperative).

### live_admin v0.12.1 (actively maintained, March 28, 2026)

**Confidence:** HIGH (verified via hex.pm)

LiveView-native admin UI. Notable for multi-tenant support. Much less opinionated than Backpex. Key learnings:

- Low weekly download count vs Torch/Kaffy — less community adoption
- API is more raw/low-level, not declarative
- Multi-tenant design (scoped queries) is a useful pattern to study

**Verdict:** Reference for multi-tenant patterns only. Not a design model.

### Kaffy v0.11.0 (last updated October 2025)

**Confidence:** HIGH (verified via hex.pm)

Most downloaded admin package (13.4K weekly). But it uses dead views (not LiveView), which conflicts with the LiveView-only requirement. Does not support Phoenix 1.8. Configuration is map-based, not DSL-based.

**Verdict:** Do not target Kaffy users who want dead views. Target them when they want to migrate to LiveView.

### Torch v6.0.0 (actively maintained, 1 day ago as of March 2026)

**Confidence:** HIGH (verified via hex.pm)

Code generator that scaffolds admin pages from Ecto schemas. 13.3K weekly downloads. Generates static files, not a runtime library. Requires Phoenix 1.7+.

**Verdict:** Torch generates code you maintain — PhoenixFilament provides a runtime library. Different philosophy. Users wanting Torch-style code generation can use PhoenixFilament's `mix phx_filament.gen.resource` (a future milestone) as a complement, not replacement.

### ex_admin, alkemist, adminable

**Verdict:** Dead or near-dead. ex_admin last updated 6 years ago. Do not reference.

---

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

---

## Installation

### mix.exs — Framework Package Dependencies

```elixir
def deps do
  [
    # Core framework deps
    {:phoenix, ">= 1.7.6 and < 1.9.0"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html, "~> 4.1"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.6"},

    # Options validation + doc generation
    {:nimble_options, "~> 1.1"},

    # JSON (transitive from Phoenix, pin explicitly)
    {:jason, "~> 1.2"},

    # I18n
    {:gettext, ">= 0.26.0"},

    # Optional: installer tooling (not in prod builds)
    {:igniter, "~> 0.6", optional: true},

    # Dev/test
    {:ex_doc, "~> 0.40", only: :dev, runtime: false},
    {:postgrex, ">= 0.0.0", only: [:dev, :test]}
  ]
end
```

### Host App Prerequisites

The framework targets Phoenix 1.8 apps generated with `mix phx.new`. These apps already have:
- Tailwind CSS v4 (via `phoenixframework/tailwind` hex wrapper)
- daisyUI 5 (configured in `assets/css/app.css`)
- esbuild (for JS bundling)
- Ecto + Postgrex (or MySQL adapter)
- Phoenix LiveView 1.1

The `mix phx_filament.install` Igniter task should:
1. Add `:phoenix_filament` to `mix.exs` deps
2. Import `PhoenixFilament.Router` in `router.ex`
3. Add `@import "phoenix_filament"` to `assets/css/app.css`
4. Copy/patch `assets/js/app.js` to register PhoenixFilament JS hooks

---

## Version Compatibility Matrix

| PhoenixFilament | Phoenix | LiveView | Elixir | OTP |
|-----------------|---------|----------|--------|-----|
| 0.1.x (target) | 1.8.x | 1.1.x | >= 1.15 | >= 25 |

Recommend stating `>= 1.15` as the Elixir minimum (matches Phoenix 1.8 docs) but developing and testing against Elixir 1.19 / OTP 28. This maximizes compatibility while using modern tooling.

---

## What NOT to Use and Why

| Library | Decision | Reason |
|---------|----------|--------|
| Spark (ash-project) | Do not use | Too heavy a dependency for the narrow DSL needs of PhoenixFilament. Would force consumers to also bring in Spark. Custom `__using__` + `@behaviour` is sufficient and idiomatic. Revisit only if the DSL grows to 10+ entity types. |
| Alpine.js | Do not use as hard dependency | Backpex requires Alpine.js. PhoenixFilament should not. LiveView 1.1 JS commands (`Phoenix.LiveView.JS`) handle show/hide, class toggling, and transitions natively. Colocated hooks handle any remaining JS needs. Alpine.js can be optionally supported but must not be required. |
| Bootstrap / Bulma | Do not use | Tailwind v4 + daisyUI 5 is the default Phoenix 1.8 stack. Using a different CSS framework would conflict with host apps. |
| Surface UI | Do not use | Separate compile step, non-standard template syntax, no longer necessary since LiveView native attr/slot covers the same use cases. |
| Ash Framework | Do not use | PhoenixFilament must work with plain Ecto schemas. Requiring Ash would exclude the majority of the ecosystem. A future optional plugin for Ash integration is appropriate, but the core must be Ash-free. |
| ex_admin / ExAdmin | Do not reference | Dead project (6 years unmaintained). No usable patterns. |

---

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

---

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

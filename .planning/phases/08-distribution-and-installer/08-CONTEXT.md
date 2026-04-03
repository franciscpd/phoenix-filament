# Phase 8: Distribution and Installer - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

PhoenixFilament is published on Hex as `phoenix_filament`. Two Mix tasks using Igniter: `mix phx_filament.install` (one-time setup — patches router, creates Panel module, configures CSS/JS assets) and `mix phx_filament.gen.resource` (per-schema — generates Resource module and registers in Panel). Getting-started documentation as ExDoc guide pages covering the full flow from installation through customization. Idempotent — running any installer twice creates no duplicates.

</domain>

<decisions>
## Implementation Decisions

### Installer (mix phx_filament.install)
- **D-01:** Igniter-based installer — AST-based, idempotent, composable. Declared as `{:igniter, "~> 0.7", optional: true}`. Follows Backpex pattern.
- **D-02:** Installer actions:
  1. Creates `lib/{app_web}/admin.ex` — Panel module with `path: "/admin"`, brand_name from app name, commented-out resources/widgets/plugins blocks
  2. Patches `router.ex` — adds `import PhoenixFilament.Panel.Router` and `phoenix_filament_panel "/admin", {AppWeb}.Admin` inside a browser scope
  3. Patches `assets/css/app.css` — adds `@import` for PhoenixFilament CSS
  4. Copies `chart.min.js` to `assets/vendor/`
  5. Patches `assets/js/app.js` — adds Chart.js import and PhxFilamentChart hook registration, merges with existing liveSocket hooks
- **D-03:** Panel module generated empty with instruction comments — no example resource. Developer adds their own resources via gen.resource or manually.
- **D-04:** Idempotent — running twice doesn't duplicate imports, routes, or modules. Igniter handles this via AST-level deduplication.

### Resource Generator (mix phx_filament.gen.resource)
- **D-05:** `mix phx_filament.gen.resource MyApp.Blog.Post` generates Resource module and registers it in the Panel.
- **D-06:** Auto-detects Repo — finds `MyApp.Repo` (Phoenix convention). Override with `--repo MyApp.Repo.ReadOnly`.
- **D-07:** Generated Resource module:
  ```elixir
  defmodule MyAppWeb.Admin.PostResource do
    use PhoenixFilament.Resource,
      schema: MyApp.Blog.Post,
      repo: MyApp.Repo
  end
  ```
- **D-08:** Auto-registers in Panel — patches the Panel module to add the resource inside `resources do...end` block. If no resources block exists, creates one.

### Hex Package Configuration
- **D-09:** Phoenix/LiveView as optional deps — `{:phoenix, "~> 1.7", optional: true}`. Documented as required peer dependencies. Avoids version conflicts with host app.
- **D-10:** Igniter as optional dep — `{:igniter, "~> 0.7", optional: true}`. Only needed for install/gen tasks, not in production builds.
- **D-11:** Package metadata — name: `phoenix_filament`, description, licenses: ["MIT"], links to GitHub.

### CSS/JS Asset Setup
- **D-12:** CSS import — Installer adds `@import "../../deps/phoenix_filament/priv/static/css/phoenix_filament.css"` to host app's `app.css`. PhoenixFilament CSS file contains any framework-specific styles beyond daisyUI.
- **D-13:** Chart.js vendor — Copies `priv/static/vendor/chart.min.js` to `assets/vendor/chart.min.js`. Imported in `app.js`.
- **D-14:** JS hook registration — Installer adds `PhxFilamentChart` hook to `app.js` and merges with existing liveSocket hooks. The hook handles `mounted()` (creates Chart.js instance) and `updated()` (updates chart data).

### Getting-Started Documentation
- **D-15:** ExDoc guide pages in `guides/` directory — published to HexDocs automatically.
- **D-16:** Guide structure:
  - `getting-started.md` — Complete tutorial: install, gen.resource, form/table DSL customization, widgets, theming, plugins
  - `resources.md` — Deep dive on Resource customization (form DSL, table DSL, changesets, authorization)
  - `plugins.md` — Creating community plugins (register/2, boot/1, nav items, routes, hooks)
  - `theming.md` — Theme customization (daisyUI themes, CSS variables, per-panel themes)
- **D-17:** Getting-started is a comprehensive tutorial (10+ min read) — covers the full flow from `mix phx.new` to a working admin panel with customized resources, widgets, and plugins.
- **D-18:** mix.exs docs config — extras list with `groups_for_extras: [Guides: ~r/guides\/.*/]`.

### Claude's Discretion
- Exact Igniter API calls for AST patching (ensure_module_exists, patch_module, etc.)
- How to detect the host app's web module name (MyAppWeb) and Repo (MyApp.Repo)
- PhoenixFilament CSS file contents (if any framework-specific styles needed)
- Chart.js hook implementation details
- How to merge hooks with existing liveSocket configuration in app.js
- Test strategy for installer tasks (Igniter has its own test helpers)
- ExDoc configuration details in mix.exs

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints
- `.planning/REQUIREMENTS.md` — DIST-01 through DIST-04
- `.planning/ROADMAP.md` §Phase 8 — Goal, success criteria

### Technology
- `CLAUDE.md` §Technology Stack — Igniter 0.7.7 for installer, ExDoc for documentation
- `mix.exs` — Current deps and package config

### Phase 6 Panel (installer target)
- `lib/phoenix_filament/panel.ex` — Panel `use` macro API the installer must scaffold
- `lib/phoenix_filament/panel/router.ex` — Router macro the installer patches into router.ex

### Phase 7 Plugin (docs target)
- `lib/phoenix_filament/plugin.ex` — Plugin behaviour docs for plugins.md guide

### Assets
- `priv/static/vendor/chart.min.js` — Chart.js vendor file to copy
- Chart widget JS hook — needs to be created as a JS file in priv/

### Igniter Reference
- https://hexdocs.pm/igniter — Igniter API for AST-based code patching

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` — Already has package/0 with metadata. Needs docs config addition.
- `priv/static/vendor/chart.min.js` — Already bundled. Installer copies to host app.
- All lib/ modules have @moduledoc — ExDoc will generate API docs automatically.

### Established Patterns
- NimbleOptions for option validation — consistent across all modules
- `__using__/1` + `@before_compile` pattern — Panel and Resource follow this
- `@moduledoc` with examples — consistent documentation style

### Integration Points
- Installer creates files in host app's `lib/` directory
- Installer patches host app's `router.ex` and `assets/`
- ExDoc reads `guides/` directory for guide pages
- Hex.pm reads package/0 from mix.exs

</code_context>

<specifics>
## Specific Ideas

- The installer should feel like `mix phx.gen.auth` — run one command, everything works
- gen.resource should feel like `mix phx.gen.live` — generate per-schema resource
- Getting-started guide should be the "aha moment" — install → gen.resource → /admin works in under 5 minutes
- Tutorial covers full lifecycle so developers don't need to explore API docs to get started

</specifics>

<deferred>
## Deferred Ideas

- `mix phx_filament.gen.plugin` — scaffold community plugin — v0.2
- `mix phx_filament.gen.widget` — scaffold custom widget — v0.2
- Cheatsheet / quick reference card — v0.2
- Video tutorial — v0.2
- Livebook integration for interactive docs — v0.2

</deferred>

---

*Phase: 08-distribution-and-installer*
*Context gathered: 2026-04-03*

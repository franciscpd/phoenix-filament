# Phase 8: Distribution and Installer — Design Spec

**Date:** 2026-04-03
**Status:** Approved
**Approach:** Igniter-based Mix tasks + ExDoc guide pages

## Overview

Phase 8 publishes PhoenixFilament on Hex and provides two Igniter-based Mix tasks: `mix phx_filament.install` (one-time panel setup) and `mix phx_filament.gen.resource` (per-schema resource generator). Four ExDoc guide pages provide comprehensive documentation from getting-started through advanced customization. No custom CSS — the framework uses exclusively daisyUI + Tailwind classes that Phoenix 1.8 apps already have.

## 1. File Structure

### New Files

```
lib/mix/tasks/
├── phx_filament.install.ex         # mix phx_filament.install (Igniter task)
└── phx_filament.gen.resource.ex    # mix phx_filament.gen.resource (Igniter task)

priv/templates/
├── admin.ex.eex                    # Panel module template
└── resource.ex.eex                 # Resource module template

guides/
├── getting-started.md              # Full tutorial (install → customize → plugins)
├── resources.md                    # Resource DSL deep dive
├── plugins.md                      # Plugin development guide
└── theming.md                      # Theme customization guide
```

### Modified Files

- `mix.exs` — Add Igniter dep, ExDoc docs config, finalize package metadata

## 2. mix phx_filament.install

### What It Does

1. **Creates Panel module** — `lib/{app_web}/admin.ex` with `use PhoenixFilament.Panel`, `path: "/admin"`, `brand_name` derived from app name. Resources/widgets/plugins blocks present as commented-out examples.

2. **Patches router.ex** — Adds `import PhoenixFilament.Panel.Router` at the top of the router module. Adds `phoenix_filament_panel "/admin", {AppWeb}.Admin` inside the existing browser `scope "/"` block.

3. **Copies Chart.js** — Copies `priv/static/vendor/chart.min.js` from the dep to `assets/vendor/chart.min.js` in the host app.

4. **Patches app.js** — Adds Chart.js import, creates `PhxFilamentChart` hook object, and merges it into the existing liveSocket hooks configuration.

**No CSS patching** — Phoenix 1.8 apps already have daisyUI configured. The installer verifies daisyUI is present but doesn't add CSS imports.

### Implementation

```elixir
defmodule Mix.Tasks.PhxFilament.Install do
  use Igniter.Mix.Task

  @shortdoc "Installs PhoenixFilament admin panel in your Phoenix app"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_filament,
      example: "mix phx_filament.install",
      schema: [],
      aliases: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)
    web_module = Module.concat([Macro.camelize(to_string(app_name)), "Web"])
    panel_module = Module.concat(web_module, "Admin")

    igniter
    |> create_panel_module(panel_module, app_name)
    |> patch_router(web_module, panel_module)
    |> copy_chart_js()
    |> patch_app_js()
  end
end
```

### Generated Panel Module

```elixir
# lib/my_app_web/admin.ex
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "MyApp Admin"

  # Add your resources here:
  # resources do
  #   resource MyAppWeb.Admin.PostResource,
  #     icon: "hero-document-text"
  # end

  # Add dashboard widgets:
  # widgets do
  #   widget MyAppWeb.Admin.StatsWidget
  # end

  # Add community plugins:
  # plugins do
  #   plugin MyPlugin
  # end
end
```

### Router Patch

```elixir
# Added to router.ex:
import PhoenixFilament.Panel.Router

# Inside scope "/", {AppWeb}, :browser do
phoenix_filament_panel "/admin", MyAppWeb.Admin
```

### app.js Patch

```javascript
// Added to assets/js/app.js:
import Chart from "../vendor/chart.min.js"

let PhxFilamentHooks = {}
PhxFilamentHooks.PhxFilamentChart = {
  mounted() {
    const config = JSON.parse(this.el.dataset.chart)
    this.chart = new Chart(this.el, config)
  },
  updated() {
    const config = JSON.parse(this.el.dataset.chart)
    this.chart.data = config.data
    this.chart.update()
  },
  destroyed() {
    if (this.chart) this.chart.destroy()
  }
}

// Merge into existing liveSocket hooks
```

### Idempotency

- `Igniter.create_new_file` skips if file already exists
- Router import check: Igniter verifies `import PhoenixFilament.Panel.Router` before adding
- Router macro check: Igniter verifies `phoenix_filament_panel` call before adding
- Chart.js copy: skips if `assets/vendor/chart.min.js` already exists
- app.js hook: checks if `PhxFilamentChart` is already defined

## 3. mix phx_filament.gen.resource

### Usage

```bash
# Auto-detect repo:
mix phx_filament.gen.resource MyApp.Blog.Post

# Explicit repo:
mix phx_filament.gen.resource MyApp.Blog.Post --repo MyApp.Repo.ReadOnly
```

### What It Does

1. **Creates Resource module** — `lib/{app_web}/admin/{schema_name}_resource.ex`
2. **Patches Panel module** — Adds resource to `resources do...end` block. Creates the block if not present.

### Implementation

```elixir
defmodule Mix.Tasks.PhxFilament.Gen.Resource do
  use Igniter.Mix.Task

  @shortdoc "Generates a PhoenixFilament resource for an Ecto schema"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_filament,
      example: "mix phx_filament.gen.resource MyApp.Blog.Post",
      positional: [:schema],
      schema: [repo: :string],
      aliases: [r: :repo]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    schema = igniter.args.positional.schema
    repo = igniter.args.options[:repo] || detect_repo(igniter)
    # ... create resource module, patch panel
  end
end
```

### Generated Resource Module

```elixir
# lib/my_app_web/admin/post_resource.ex
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo
end
```

### Panel Patch

```elixir
# resources block added/updated in Panel module:
resources do
  resource MyAppWeb.Admin.PostResource,
    icon: "hero-document-text"
end
```

### Repo Auto-Detection

Igniter scans for modules using `use Ecto.Repo` in the codebase. If exactly one is found, uses it. If multiple found, asks the user. If none found, falls back to `{AppName}.Repo`. Override with `--repo` flag.

## 4. mix.exs Finalization

### Dependencies

```elixir
defp deps do
  [
    {:ecto, "~> 3.11"},
    {:nimble_options, "~> 1.0"},
    {:jason, "~> 1.2"},
    {:phoenix, "~> 1.7", optional: true},
    {:phoenix_live_view, "~> 1.0", optional: true},
    {:phoenix_html, "~> 4.1", optional: true},
    {:phoenix_ecto, "~> 4.4", optional: true},
    {:igniter, "~> 0.7", optional: true},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

### Package Metadata

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib priv guides .formatter.exs mix.exs README.md LICENSE)
  ]
end
```

### ExDoc Configuration

```elixir
defp docs do
  [
    main: "PhoenixFilament",
    extras: [
      "guides/getting-started.md",
      "guides/resources.md",
      "guides/plugins.md",
      "guides/theming.md"
    ],
    groups_for_extras: [
      Guides: ~r/guides\/.*/
    ],
    groups_for_modules: [
      Core: [PhoenixFilament, PhoenixFilament.Resource, PhoenixFilament.Panel],
      Components: ~r/PhoenixFilament\.Components\..*/,
      "Form Builder": ~r/PhoenixFilament\.Form\..*/,
      "Table Builder": ~r/PhoenixFilament\.Table\..*/,
      Widgets: ~r/PhoenixFilament\.Widget\..*/,
      "Plugin System": [PhoenixFilament.Plugin, PhoenixFilament.Plugin.Resolver],
      "Mix Tasks": ~r/Mix\.Tasks\..*/
    ]
  ]
end
```

## 5. Guide Pages

### getting-started.md (~800 lines)

Complete tutorial covering:
1. Prerequisites (Phoenix 1.8, Ecto schema)
2. Installation (`mix deps.get`, `mix phx_filament.install`)
3. First resource (`mix phx_filament.gen.resource`)
4. Running the admin (`mix phx.server` → `/admin`)
5. Customizing forms (form DSL: sections, columns, visibility)
6. Customizing tables (table DSL: columns, filters, actions, search)
7. Dashboard widgets (StatsOverview, Chart, Table, Custom)
8. Theming (daisyUI themes, per-panel theme, dark mode)
9. Authentication (on_mount hook, session revocation)
10. Community plugins (registering, creating your own)

### resources.md (~400 lines)

- Form DSL: field types, sections, columns, visible_when
- Table DSL: columns, formatters, filters, actions, search
- Changeset integration: create_changeset, update_changeset
- Authorization: authorize/3 callback
- Show page, page titles, breadcrumbs
- Custom label, plural_label, slug, icon

### plugins.md (~300 lines)

- Plugin behaviour (register/2, boot/1)
- Navigation items (nav_item/2)
- Custom routes (route/3)
- Dashboard widgets from plugins
- Lifecycle hooks (handle_event, handle_info, etc.)
- Testing plugins
- @experimental stability contract

### theming.md (~200 lines)

- daisyUI theme selection (data-theme)
- Per-panel themes
- Dark mode (auto + manual toggle)
- CSS variable overrides
- Custom color palette

## 6. Error Handling

| Scenario | Handling |
|----------|----------|
| Igniter not installed | Prints: "Add {:igniter, \"~> 0.7\"} to deps and run mix deps.get" |
| Not a Phoenix app | Igniter detects missing router.ex, reports |
| Router already patched | Idempotent — skips |
| Schema not found | gen.resource warns: "Schema not found. Create it first." |
| Panel not found | gen.resource: "Run mix phx_filament.install first" |
| `assets/vendor/` missing | Creates directory |
| Duplicate gen.resource | Idempotent — resource module and Panel registration skipped |

## 7. Testing Strategy

| Test Area | Approach |
|-----------|----------|
| Installer creates Panel | Igniter.Test with temp project |
| Installer patches router | Assert AST contains import + macro call |
| Installer idempotent | Run twice, assert no duplicates |
| gen.resource creates module | Assert file with correct schema/repo |
| gen.resource patches Panel | Assert resources block updated |
| Repo auto-detection | Mock project with Ecto.Repo |
| Guides compile | `mix docs` runs without errors |
| Package valid | `mix hex.build --unpack` inspects contents |

---

*Phase: 08-distribution-and-installer*
*Design approved: 2026-04-03*

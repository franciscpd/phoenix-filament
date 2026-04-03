# Phase 7: Plugin Architecture — Design Spec

**Date:** 2026-04-03
**Status:** Approved
**Approach:** Plugin Resolver in `__before_compile__` — register at compile time, boot at runtime

## Overview

Phase 7 introduces a formal `PhoenixFilament.Plugin` behaviour that the framework and third-party authors use as the same extension API. Plugins declare navigation items, custom routes, dashboard widgets, and lifecycle hooks via `register/2` (compile time). Plugins optionally initialize at runtime via `boot/1` (per socket mount). The built-in Resource and Widget systems are refactored into implicit plugins (ResourcePlugin, WidgetPlugin) that use the public Plugin behaviour — proving the contract. The Panel's `__before_compile__` resolves all plugins into unified lists consumed by Router, Hook, Navigation, and Dashboard.

## 1. Module Architecture

### New Modules

| Module | File | Responsibility |
|--------|------|---------------|
| `PhoenixFilament.Plugin` | `lib/phoenix_filament/plugin.ex` | Behaviour (`register/2`, `boot/1`) + `use` macro + helpers (`nav_item/2`, `route/3`) |
| `PhoenixFilament.Plugin.Resolver` | `lib/phoenix_filament/plugin/resolver.ex` | Merges all plugin `register/2` results into unified lists |
| `PhoenixFilament.Plugins.ResourcePlugin` | `lib/phoenix_filament/plugins/resource_plugin.ex` | Built-in plugin wrapping `resources do...end` |
| `PhoenixFilament.Plugins.WidgetPlugin` | `lib/phoenix_filament/plugins/widget_plugin.ex` | Built-in plugin wrapping `widgets do...end` |

### Modified Modules

| Module | File | Changes |
|--------|------|---------|
| `PhoenixFilament.Panel` | `lib/phoenix_filament/panel.ex` | Add `@_phx_filament_panel_plugins` accumulator. `__before_compile__` calls Resolver. New accessors: `:all_routes`, `:all_nav_items`, `:all_widgets`, `:all_hooks`, `:plugins`. Keep `:resources` and `:widgets` for backward compat. |
| `PhoenixFilament.Panel.DSL` | `lib/phoenix_filament/panel/dsl.ex` | Add `plugins/1` and `plugin/2` macros |
| `PhoenixFilament.Panel.Router` | `lib/phoenix_filament/panel/router.ex` | Read `:all_routes` instead of iterating `:resources` directly |
| `PhoenixFilament.Panel.Hook` | `lib/phoenix_filament/panel/hook.ex` | Read `:all_nav_items` for nav. Call `boot/1` on each plugin. Attach `:all_hooks` via `attach_hook/4`. |
| `PhoenixFilament.Panel.Dashboard` | `lib/phoenix_filament/panel/dashboard.ex` | Read `:all_widgets` instead of `:widgets` |
| `PhoenixFilament.Panel.Options` | `lib/phoenix_filament/panel/options.ex` | Add `plugin_schema/0` for plugin registration options |

### File Structure

```
lib/phoenix_filament/
├── plugin.ex                      # Behaviour + use macro + helpers
├── plugin/
│   └── resolver.ex                # Merge plugin results
└── plugins/
    ├── resource_plugin.ex         # Built-in ResourcePlugin
    └── widget_plugin.ex           # Built-in WidgetPlugin
```

## 2. Plugin Behaviour & Helpers

### Behaviour Definition

```elixir
defmodule PhoenixFilament.Plugin do
  @callback register(panel :: module(), opts :: keyword()) :: map()
  @callback boot(socket :: Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  @optional_callbacks [boot: 1]
end
```

**`register/2`** (required):
- Called at compile time in `__before_compile__`
- Receives the panel module (for introspection) and per-plugin keyword opts
- Returns a map with optional keys (framework provides defaults for missing keys):
  - `:nav_items` — `[%{label, path, icon, nav_group, icon_fallback}]` for sidebar entries
  - `:routes` — `[%{path, live_view, live_action}]` for live routes
  - `:widgets` — `[%{module, sort, column_span}]` for dashboard widgets
  - `:hooks` — `[{stage, fun}]` for lifecycle hooks (`{:handle_event, &fun/3}`, `{:handle_info, &fun/2}`, `{:handle_params, &fun/3}`, `{:after_render, &fun/1}`)

**`boot/1`** (optional):
- Called at runtime per socket mount, in `Panel.Hook.on_mount/4`
- Receives socket, returns socket (no `{:halt, redirect}` — auth is Panel's responsibility)
- Used for runtime initialization: inject assigns, subscribe PubSub, etc.

### `use PhoenixFilament.Plugin`

Injects `@behaviour` + imports helpers:

```elixir
defmacro __using__(_opts) do
  quote do
    @behaviour PhoenixFilament.Plugin
    import PhoenixFilament.Plugin, only: [nav_item: 2, route: 3]
  end
end
```

### Helper Functions

```elixir
def nav_item(label, opts) do
  %{
    label: label,
    path: opts[:path],
    icon: opts[:icon],
    nav_group: opts[:nav_group],
    icon_fallback: String.first(label)
  }
end

def route(path, live_view, live_action) do
  %{path: path, live_view: live_view, live_action: live_action}
end
```

### Developer-Facing API

```elixir
defmodule MyApp.AnalyticsPlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    %{
      nav_items: [
        nav_item("Analytics",
          path: "/analytics",
          icon: "hero-chart-bar",
          nav_group: "Reports")
      ],
      routes: [
        route("/analytics", MyApp.AnalyticsLive, :index),
        route("/analytics/:id", MyApp.AnalyticsDetailLive, :show)
      ],
      hooks: [
        {:handle_event, &__MODULE__.on_event/3}
      ]
    }
  end

  @impl true
  def boot(socket) do
    Phoenix.Component.assign(socket, :analytics_enabled, true)
  end

  def on_event("track", params, socket) do
    # Log the event
    {:cont, socket}
  end
end
```

## 3. Plugin Resolver

### `PhoenixFilament.Plugin.Resolver`

Pure function module that merges all plugin registrations:

```elixir
def resolve(plugins, panel_module) do
  defaults = %{nav_items: [], routes: [], widgets: [], hooks: []}

  results =
    Enum.map(plugins, fn {mod, opts} ->
      result = mod.register(panel_module, opts)
      Map.merge(defaults, result)
    end)

  %{
    all_nav_items: Enum.flat_map(results, & &1.nav_items),
    all_routes: Enum.flat_map(results, & &1.routes),
    all_widgets: Enum.flat_map(results, & &1.widgets) |> Enum.sort_by(& &1[:sort] || 0),
    all_hooks: Enum.flat_map(results, & &1.hooks)
  }
end
```

### Panel `__before_compile__` Integration

The `__before_compile__` builds the full plugin list and resolves:

1. If `@_phx_filament_panel_resources` is non-empty, prepend `{ResourcePlugin, resources: enriched_resources}`
2. If `@_phx_filament_panel_widgets` is non-empty, prepend `{WidgetPlugin, widgets: enriched_widgets}`
3. Append all `@_phx_filament_panel_plugins` (community plugins, in declaration order)
4. Call `Resolver.resolve(all_plugins, __MODULE__)`
5. Generate new `__panel__/1` accessors from resolved data

**Backward compatibility preserved:**
- `__panel__(:resources)` — still returns the raw enriched resource list (same as Phase 6)
- `__panel__(:widgets)` — still returns the raw widget list (same as Phase 6)
- `__panel__(:opts)` — unchanged
- `__panel__(:path)` — unchanged

**New accessors:**
- `__panel__(:all_nav_items)` — merged from all plugins
- `__panel__(:all_routes)` — merged from all plugins
- `__panel__(:all_widgets)` — merged from all plugins, sorted by `:sort`
- `__panel__(:all_hooks)` — merged from all plugins
- `__panel__(:plugins)` — raw plugin list `[{mod, opts}, ...]`

## 4. Built-in Plugins

### ResourcePlugin

```elixir
defmodule PhoenixFilament.Plugins.ResourcePlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(panel, opts) do
    resources = opts[:resources] || []
    panel_path = panel.__panel__(:path)

    %{
      nav_items: Enum.map(resources, fn r ->
        nav_item(r.plural_label,
          path: "#{panel_path}/#{r.slug}",
          icon: r.icon,
          nav_group: r.nav_group)
      end),
      routes: Enum.flat_map(resources, fn r ->
        [
          route("/#{r.slug}", r.module, :index),
          route("/#{r.slug}/new", r.module, :new),
          route("/#{r.slug}/:id", r.module, :show),
          route("/#{r.slug}/:id/edit", r.module, :edit)
        ]
      end)
    }
  end
end
```

### WidgetPlugin

```elixir
defmodule PhoenixFilament.Plugins.WidgetPlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    widgets = opts[:widgets] || []
    %{widgets: widgets}
  end
end
```

Both use the same public `PhoenixFilament.Plugin` behaviour — no internal bypass APIs.

## 5. Panel DSL Changes

### New `plugins/1` and `plugin/2` macros in `Panel.DSL`:

```elixir
defmacro plugins(do: block) do
  quote do
    unquote(block)
  end
end

defmacro plugin(module, opts \\ []) do
  quote do
    @_phx_filament_panel_plugins {unquote(module), unquote(opts)}
  end
end
```

### Panel `__using__/1` adds:

```elixir
Module.register_attribute(__MODULE__, :_phx_filament_panel_plugins, accumulate: true)
```

## 6. Consumer Module Changes

### Router

Before:
```elixir
for resource <- resources do
  live "/#{resource.slug}", resource.module, :index
  # ...
end
```

After:
```elixir
all_routes = panel_module.__panel__(:all_routes)
for route <- all_routes do
  live route.path, route.live_view, route.live_action
end
```

### Hook

Before:
```elixir
nav = Navigation.build_tree(resources, panel_path, current_path)
```

After:
```elixir
nav_items = panel_module.__panel__(:all_nav_items)
# Navigation.build_tree now receives pre-built nav items instead of resources
# (nav items already have label, path, icon, nav_group, icon_fallback)

# Boot plugins:
plugins = panel_module.__panel__(:plugins)
socket = Enum.reduce(plugins, socket, fn {mod, _opts}, sock ->
  if function_exported?(mod, :boot, 1), do: mod.boot(sock), else: sock
end)

# Attach plugin hooks:
hooks = panel_module.__panel__(:all_hooks)
socket = Enum.reduce(hooks, socket, fn {stage, fun}, sock ->
  Phoenix.LiveView.attach_hook(sock, :"plugin_#{:erlang.phash2(fun)}", stage, fun)
end)
```

### Dashboard

Before: `panel_module.__panel__(:widgets)`
After: `panel_module.__panel__(:all_widgets)`

### Navigation

`build_tree/3` currently receives a resource list and builds nav items internally. After refactor, it receives pre-built nav items directly (from `:all_nav_items`). The function signature changes from:

```elixir
# Before:
build_tree(resources, panel_path, current_path)
# resources = [%{module, slug, plural_label, icon, nav_group}]

# After:
build_tree(nav_items, current_path)
# nav_items = [%{label, path, icon, nav_group, icon_fallback}]
# path is already fully resolved (includes panel_path)
```

Active state detection changes from `String.starts_with?(current_path, "#{panel_path}/#{r.slug}")` to `String.starts_with?(current_path, item.path)` since paths are pre-resolved.

**Breaking change in Navigation API:** `build_tree/3` becomes `build_tree/2`. This is an internal API (not used by developers), so it's safe to change. Existing Navigation tests must be updated to pass pre-built nav_items instead of resources.

## 7. Error Handling

| Scenario | Handling |
|----------|----------|
| Plugin `register/2` raises | Compile-time error: "Plugin MyPlugin.register/2 raised: {error}" |
| Plugin `boot/1` raises | Hook catches error, logs warning, continues booting other plugins |
| Plugin returns invalid map | Resolver validates, falls back to defaults for missing keys |
| Plugin module missing behaviour | Compile-time error from behaviour check in `plugin/2` macro |
| Hook function wrong arity | `attach_hook` raises at runtime — documented in guide |
| No plugins declared | Works fine — empty unified lists, same as Phase 6 behavior |

## 8. Testing Strategy

| Test Area | What to Assert |
|-----------|---------------|
| `Plugin` behaviour | Module defines callbacks, `use` imports helpers |
| `nav_item/2`, `route/3` | Return correct map shapes |
| `Resolver.resolve/2` | Merges multiple plugins, defaults for missing keys, preserves order, sorts widgets |
| `ResourcePlugin.register/2` | Converts resource list → nav_items + 4 CRUD routes per resource |
| `WidgetPlugin.register/2` | Passes through widget list |
| `Panel` with plugins block | `__panel__(:all_routes)` includes resources + community routes |
| `Panel` backward compat | `__panel__(:resources)` and `__panel__(:widgets)` still return raw lists |
| `Router` unified routes | Generates live routes from `:all_routes` (resource + plugin routes) |
| `Hook` boots plugins | `boot/1` called on each plugin with exported boot |
| `Hook` attaches hooks | Plugin lifecycle hooks attached via `attach_hook` |
| `Hook` boot error isolation | One plugin `boot/1` raising doesn't crash others |
| `Navigation` unified nav | `build_tree/2` works with unified nav_items |
| `Dashboard` unified widgets | Reads `:all_widgets` |
| Compile cascade test | Adding/removing plugin recompiles Panel module only |
| Community plugin E2E | Test plugin registers nav + route, appears in panel sidebar and router |

## 9. @experimental Stability Contract

```elixir
@moduledoc """
Plugin behaviour for extending PhoenixFilament panels.

> #### Experimental {: .warning}
>
> The Plugin API is experimental. Breaking changes may occur in
> minor versions until this notice is removed. Pin your
> `phoenix_filament` dependency to a specific version when using plugins.

## Stability Roadmap
- **v0.1.x** — @experimental, may break in minor versions
- **v0.2+** — stabilize based on community feedback
- **v1.0** — stable, semver-protected
"""
```

## 10. Plugin Developer Guide (in @moduledoc)

The `PhoenixFilament.Plugin` moduledoc includes a comprehensive guide:

1. **Quick Start** — minimal plugin (just nav_item)
2. **Registering Navigation Items** — `nav_item/2` helper, nav_group
3. **Adding Custom Routes** — `route/3` helper, LiveView targets
4. **Dashboard Widgets** — registering widgets from plugins
5. **Lifecycle Hooks** — handle_event, handle_info, handle_params, after_render
6. **Boot-time Initialization** — `boot/1` for runtime assigns and PubSub
7. **Testing Your Plugin** — how to test register/2 and boot/1
8. **@optional_callbacks Reference** — which callbacks are optional and why

---

*Phase: 07-plugin-architecture*
*Design approved: 2026-04-03*

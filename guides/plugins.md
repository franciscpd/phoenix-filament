# Plugin Development

> #### Experimental {: .warning}
>
> The Plugin API is `@experimental`. Breaking changes may occur in minor versions until
> this notice is removed. Pin your `phoenix_filament` dependency to a specific version
> when building plugins.

Plugins let you extend a PhoenixFilament panel with custom navigation, live routes,
dashboard widgets, and lifecycle hooks — using the exact same API that PhoenixFilament
uses internally.

## Quick Start

```elixir
defmodule MyApp.AnalyticsPlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, _opts) do
    %{
      nav_items: [
        nav_item("Analytics",
          path: "/analytics",
          icon: "hero-chart-bar",
          nav_group: "Reports")
      ],
      routes: [
        route("/analytics", MyAppWeb.AnalyticsLive, :index)
      ]
    }
  end
end
```

Register it in your panel:

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel, path: "/admin"

  plugins do
    plugin MyApp.AnalyticsPlugin
  end
end
```

## `use PhoenixFilament.Plugin`

Using this macro:

1. Adds `@behaviour PhoenixFilament.Plugin` to your module
2. Imports `nav_item/2` and `route/3` helper functions

## Callbacks

### `register/2` (required)

Called at compile time when the panel resolves its plugin list. Returns a map describing
what the plugin contributes to the panel.

```elixir
@impl true
def register(panel_module, opts) do
  %{
    nav_items: [...],
    routes: [...],
    widgets: [...],
    hooks: [...]
  }
end
```

Arguments:

- `panel_module` — the Panel module that is registering this plugin
- `opts` — the keyword list passed to `plugin MyPlugin, key: value`

All keys in the returned map are optional. Omit any key you do not need.

#### `:nav_items`

Navigation entries added to the panel sidebar. Build them with `nav_item/2`:

```elixir
nav_item("Analytics",
  path: "/analytics",
  icon: "hero-chart-bar",
  nav_group: "Reports")
```

`nav_item/2` options:

| Key | Type | Description |
|-----|------|-------------|
| `path:` | string | URL path (relative to panel root) |
| `icon:` | string | Heroicon name |
| `nav_group:` | string | Sidebar group heading |

#### `:routes`

Live routes added to the panel's `live_session`. Build them with `route/3`:

```elixir
route("/analytics", MyAppWeb.AnalyticsLive, :index)
route("/analytics/:id", MyAppWeb.AnalyticsLive, :show)
```

`route/3` arguments:

1. Path string (relative to the panel's `scope` path)
2. LiveView module
3. Live action atom

All routes registered via plugins automatically inherit the panel's `on_mount` hooks,
session name, and layout.

#### `:widgets`

Dashboard widgets contributed by the plugin:

```elixir
widgets: [
  %{module: MyApp.AnalyticsWidget, sort: 5, column_span: 6}
]
```

Widget map keys:

| Key | Default | Description |
|-----|---------|-------------|
| `module` | required | LiveComponent module |
| `sort` | `0` | Dashboard rendering order (ascending) |
| `column_span` | `12` | Grid column span (1–12) |

The widget module must implement one of the widget behaviours:
`PhoenixFilament.Widget.StatsOverview`, `PhoenixFilament.Widget.Chart`,
`PhoenixFilament.Widget.Table`, or `PhoenixFilament.Widget.Custom`.

#### `:hooks`

Lifecycle hooks called at various points in the panel LiveView:

```elixir
hooks: [
  {:handle_event, &MyApp.AnalyticsPlugin.handle_event/3},
  {:handle_info,  &MyApp.AnalyticsPlugin.handle_info/2},
  {:handle_params, &MyApp.AnalyticsPlugin.handle_params/3},
  {:after_render,  &MyApp.AnalyticsPlugin.after_render/1}
]
```

Hook function signatures:

```elixir
# handle_event: called before the panel's handle_event
def handle_event(event, params, socket), do: {:cont, socket}

# handle_info: called before the panel's handle_info
def handle_info(message, socket), do: {:cont, socket}

# handle_params: called before the panel's handle_params
def handle_params(params, uri, socket), do: {:cont, socket}

# after_render: called after each render
def after_render(socket), do: socket
```

Return `{:cont, socket}` to allow the default handler to proceed, or `{:halt, socket}`
to stop further processing.

### `boot/1` (optional)

Called at runtime on each panel LiveView `mount`. Receives the socket after the panel's
own `on_mount` hooks have run. Returns the modified socket.

```elixir
@impl true
def boot(socket) do
  user_id = socket.assigns.current_user.id

  # Subscribe to a PubSub topic
  Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics:#{user_id}")

  # Add assigns available throughout the panel session
  Phoenix.Component.assign(socket, :analytics_enabled, true)
end
```

`boot/1` cannot halt the mount — authentication is the Panel's responsibility.

## Plugin Options

Pass configuration to your plugin from the panel:

```elixir
plugins do
  plugin MyApp.AnalyticsPlugin,
    nav_group: "Reports",
    show_realtime: true
end
```

Access options in `register/2`:

```elixir
def register(_panel, opts) do
  group = opts[:nav_group] || "Analytics"
  show_realtime = opts[:show_realtime] || false

  %{
    nav_items: [
      nav_item("Analytics", path: "/analytics", nav_group: group)
    ] ++ if(show_realtime, do: [nav_item("Live", path: "/analytics/live", nav_group: group)], else: [])
  }
end
```

## Complete Plugin Example

```elixir
defmodule MyApp.AuditLogPlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    group = opts[:nav_group] || "System"

    %{
      nav_items: [
        nav_item("Audit Log",
          path: "/audit",
          icon: "hero-clipboard-document-list",
          nav_group: group)
      ],
      routes: [
        route("/audit", MyAppWeb.AuditLive, :index),
        route("/audit/:id", MyAppWeb.AuditLive, :show)
      ],
      widgets: [
        %{module: MyApp.RecentAuditWidget, sort: 10, column_span: 12}
      ],
      hooks: [
        {:handle_info, &__MODULE__.handle_info/2}
      ]
    }
  end

  @impl true
  def boot(socket) do
    if Map.has_key?(socket.assigns, :current_user) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "audit_log")
    end
    socket
  end

  def handle_info({:audit_event, event}, socket) do
    # Update live audit count in sidebar badge, etc.
    updated = update_in(socket.assigns[:audit_count] || 0, &(&1 + 1))
    {:cont, Phoenix.Component.assign(socket, :audit_count, updated)}
  end

  def handle_info(_msg, socket), do: {:cont, socket}
end
```

## Testing Your Plugin

Use ExUnit with the `PhoenixFilament.ComponentCase` helper:

```elixir
defmodule MyApp.AuditLogPluginTest do
  use ExUnit.Case, async: true

  describe "register/2" do
    test "returns nav_items and routes" do
      result = MyApp.AuditLogPlugin.register(MyAppWeb.Admin, [])

      assert [nav_item] = result.nav_items
      assert nav_item.label == "Audit Log"
      assert nav_item.path == "/audit"

      assert [route1, route2] = result.routes
      assert route1.path == "/audit"
      assert route1.live_action == :index
    end

    test "respects nav_group option" do
      result = MyApp.AuditLogPlugin.register(MyAppWeb.Admin, nav_group: "Security")
      [nav_item] = result.nav_items
      assert nav_item.nav_group == "Security"
    end
  end

  describe "boot/1" do
    test "assigns analytics_enabled" do
      socket = %Phoenix.LiveView.Socket{assigns: %{current_user: %{id: 1}}}
      result = MyApp.AuditLogPlugin.boot(socket)
      # boot modifies the socket — assert your expected changes
      assert result != nil
    end
  end
end
```

## Stability Contract

| Version | Status |
|---------|--------|
| v0.1.x | `@experimental` — breaking changes possible in minor versions |
| v0.2+ | Stabilize based on community feedback |
| v1.0 | Stable, semver-protected |

Pin your dependency to a patch version while the API is experimental:

```elixir
{:phoenix_filament, "~> 0.1.0"}
```

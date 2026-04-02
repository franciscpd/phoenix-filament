# Phase 6: Panel Shell and Auth Hook — Design Spec

**Date:** 2026-04-02
**Status:** Approved
**Approach:** Layered Delegation (thin Panel DSL → specialized modules)

## Overview

Phase 6 wraps Resources in an admin panel shell. Developers declare `use PhoenixFilament.Panel` with `resources do...end` and `widgets do...end` DSL blocks, then add `phoenix_filament_panel "/admin", MyApp.Admin` to their router. The panel renders a sidebar, topbar, breadcrumbs, flash toasts, and a dashboard with 4 widget types — all using daisyUI 5 semantic classes and LiveView layout patterns.

## 1. Module Architecture

**Approach:** Layered Delegation — thin Panel DSL module delegates to specialized modules. Same pattern as `PhoenixFilament.Resource` (Phase 5).

### Module Map

| Module | Responsibility |
|--------|---------------|
| `PhoenixFilament.Panel` | `__using__/1` macro, NimbleOptions validation, DSL accumulation, `__panel__/1` accessors |
| `PhoenixFilament.Panel.Options` | NimbleOptions schema for panel, resource registration, and widget registration |
| `PhoenixFilament.Panel.Router` | `phoenix_filament_panel/2` macro — expands to `live_session` + `live` routes |
| `PhoenixFilament.Panel.Hook` | `on_mount` callback — injects panel assigns, subscribes PubSub |
| `PhoenixFilament.Panel.Navigation` | Builds nav tree from registered resources (groups, items, active state) |
| `PhoenixFilament.Panel.Layout` | Function components: `sidebar/1`, `topbar/1`, `breadcrumbs/1`, `flash_group/1` |
| `PhoenixFilament.Panel.Dashboard` | Dashboard LiveView — renders widget grid, manages widget lifecycle |
| `PhoenixFilament.Widget.StatsOverview` | Behaviour + base LiveComponent for stat cards |
| `PhoenixFilament.Widget.Chart` | Behaviour + base LiveComponent for Chart.js charts |
| `PhoenixFilament.Widget.Table` | Behaviour + base LiveComponent wrapping TableLive |
| `PhoenixFilament.Widget.Custom` | Behaviour + base LiveComponent for free-form widgets |

### File Structure

```
lib/phoenix_filament/
├── panel.ex                    # use PhoenixFilament.Panel macro
└── panel/
    ├── options.ex              # NimbleOptions schema
    ├── router.ex               # phoenix_filament_panel/2 macro
    ├── hook.ex                 # on_mount hook
    ├── navigation.ex           # nav tree builder
    ├── layout.ex               # shell components (sidebar, topbar, breadcrumbs, flash)
    ├── dashboard.ex            # dashboard LiveView
    └── widget/
        ├── stats_overview.ex   # StatsOverview behaviour + base
        ├── chart.ex            # Chart behaviour + base
        ├── table.ex            # Table widget behaviour + base
        └── custom.ex           # Custom widget behaviour + base

assets/vendor/
└── chart.min.js                # Chart.js bundled (vendor asset, no npm)
```

## 2. Panel DSL & Configuration

### Developer-Facing API

```elixir
defmodule MyApp.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    on_mount: {MyAuth, :require_admin},
    plug: MyAuthPlug,
    brand_name: "My Admin",
    logo: "/images/logo.svg",
    theme: "corporate",
    theme_switcher: true,
    pubsub: MyApp.PubSub

  resources do
    resource MyApp.Admin.PostResource,
      icon: "hero-document-text",
      nav_group: "Blog"

    resource MyApp.Admin.CategoryResource,
      icon: "hero-tag",
      nav_group: "Blog"

    resource MyApp.Admin.UserResource,
      icon: "hero-users",
      nav_group: "Management",
      slug: "team-members"
  end

  widgets do
    widget MyApp.Admin.StatsOverview, sort: 1, column_span: :full
    widget MyApp.Admin.PostsChart, sort: 2, column_span: 6
    widget MyApp.Admin.RecentPosts, sort: 3, column_span: 6
  end
end
```

### Panel Options (NimbleOptions)

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `path` | `string` | yes | — | URL path prefix (e.g., `"/admin"`) |
| `on_mount` | `{module, atom}` | no | `nil` | LiveView on_mount hook for auth |
| `plug` | `module \| {module, term}` | no | `nil` | Plug for HTTP request auth (module or `{module, opts}` tuple) |
| `brand_name` | `string` | no | `"Admin"` | Display name in sidebar header |
| `logo` | `string` | no | `nil` | Logo URL for sidebar header |
| `theme` | `string` | no | `nil` | daisyUI theme name (`data-theme`) |
| `theme_switcher` | `boolean` | no | `false` | Show light/dark toggle in sidebar |
| `pubsub` | `module` | no | `nil` | PubSub module for session revocation |
| `dashboard` | `module` | no | `nil` | Custom LiveView to override default dashboard |

### Resource Registration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `icon` | `string` | no | `nil` | Heroicon name (e.g., `"hero-document-text"`). Fallback: first letter of label. |
| `nav_group` | `string` | no | `nil` | Sidebar group heading. Ungrouped resources appear at top. |
| `slug` | `string` | no | auto-derived | URL slug override. Default: pluralized schema name (Post → `"posts"`). |

### Widget Registration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `sort` | `integer` | no | `0` | Widget rendering order (ascending) |
| `column_span` | `integer \| :full` | no | `12` | Grid column span (1-12 or `:full` for 12) |

### Panel Macro Internals

`__using__/1`:
1. Validate options via `Panel.Options.schema()`
2. Register module attributes: `@_phx_filament_panel_resources` (accumulate), `@_phx_filament_panel_widgets` (accumulate)
3. Import `PhoenixFilament.Panel.DSL` for `resources/1`, `widgets/1`, `resource/2`, `widget/2` macros
4. `@before_compile PhoenixFilament.Panel`

`__before_compile__/1`:
- Generate `__panel__/1` accessor functions:
  - `__panel__(:opts)` → validated options keyword list
  - `__panel__(:resources)` → list of `%{module: mod, icon: icon, nav_group: group, slug: slug, label: label, plural_label: plural}`
  - `__panel__(:widgets)` → list of `%{module: mod, sort: sort, column_span: span}`
  - `__panel__(:path)` → path string

### Multiple Panels

Each panel is an independent module. Multiple panels coexist by registering separate `phoenix_filament_panel` calls in the router:

```elixir
# router.ex
phoenix_filament_panel "/admin", MyApp.AdminPanel
phoenix_filament_panel "/staff", MyApp.StaffPanel
```

Each gets its own `live_session` (named `:phoenix_filament_{module_hash}` to avoid collision), its own resources, its own theme, and its own auth hook.

## 3. Router Macro

### `phoenix_filament_panel/2`

Defined in `PhoenixFilament.Panel.Router`, imported when the developer `use PhoenixFilament.Panel.Router` or `import PhoenixFilament.Panel.Router` in their router.

**Expansion:**

```elixir
phoenix_filament_panel "/admin", MyApp.Admin
```

Expands to:

```elixir
scope "/admin" do
  # Plug auth (if configured)
  pipe_through [MyAuthPlug]  # only if __panel__(:opts)[:plug] is set

  live_session :"phoenix_filament_#{:erlang.phash2(MyApp.Admin)}",
    on_mount: [
      {MyAuth, :require_admin},        # user's hook FIRST
      {PhoenixFilament.Panel.Hook, {:panel, MyApp.Admin}}  # panel hook SECOND
    ],
    layout: {PhoenixFilament.Panel.Layout, :panel} do

    # Dashboard
    live "/", PhoenixFilament.Panel.Dashboard, :index

    # Per-resource CRUD routes (auto-generated from __panel__(:resources))
    live "/posts", MyApp.Admin.PostResource, :index
    live "/posts/new", MyApp.Admin.PostResource, :new
    live "/posts/:id", MyApp.Admin.PostResource, :show
    live "/posts/:id/edit", MyApp.Admin.PostResource, :edit
    # ... repeat for each resource
  end
end
```

**Key details:**
- User's `on_mount` hook is listed FIRST — auth halts before Panel.Hook runs
- `live_session` name uses `phash2` of the panel module to avoid collision between multiple panels
- Dashboard route is always `/` (relative to panel path)
- Resource slugs auto-derived from schema or overridden via `:slug` option
- The `layout` option points to `Panel.Layout.panel/1` which renders the shell

## 4. Panel Hook (on_mount)

### `PhoenixFilament.Panel.Hook`

Called as `on_mount({:panel, MyApp.Admin}, params, session, socket)`.

**Assigns injected:**

| Assign | Source | Description |
|--------|--------|-------------|
| `panel_module` | `MyApp.Admin` | The panel module atom |
| `panel_brand` | `__panel__(:opts)[:brand_name]` | Display name for topbar/sidebar |
| `panel_logo` | `__panel__(:opts)[:logo]` | Logo URL |
| `panel_theme` | `__panel__(:opts)[:theme]` | daisyUI theme name |
| `panel_theme_switcher` | `__panel__(:opts)[:theme_switcher]` | Boolean |
| `panel_path` | `__panel__(:opts)[:path]` | Base path (e.g., "/admin") |
| `panel_nav` | `Navigation.build_tree(resources, current_path)` | Nav tree struct |
| `current_resource` | matched from URL | Current resource module or nil |
| `breadcrumbs` | auto-computed | List of `%{label: str, path: str}` |

**PubSub subscription:**
If `pubsub` is configured and `current_user` exists in assigns:
```elixir
Phoenix.PubSub.subscribe(pubsub, "user_sessions:#{current_user.id}")
```

**Breadcrumb updates:**
The hook attaches a `handle_params` hook via `attach_hook/4` to recompute breadcrumbs on navigation within the same LiveView (e.g., index → edit modal).

## 5. Navigation

### `PhoenixFilament.Panel.Navigation`

**`build_tree/2`** takes the resources list and current path, returns a nav struct:

```elixir
%{
  groups: [
    %{label: "Blog", items: [
      %{label: "Posts", path: "/admin/posts", icon: "hero-document-text", active: true},
      %{label: "Categories", path: "/admin/categories", icon: "hero-tag", active: false}
    ]},
    %{label: "Management", items: [
      %{label: "Team Members", path: "/admin/team-members", icon: "hero-users", active: false}
    ]}
  ],
  ungrouped: [
    # Resources without nav_group appear here
  ]
}
```

- Groups ordered by first appearance in `resources do...end`
- Items within groups ordered by declaration order
- Active state determined by path prefix match
- Labels auto-derived from resource `__resource__(:opts)[:plural_label]` or resource module name

## 6. Layout Components

### `PhoenixFilament.Panel.Layout`

All function components (stateless, zero process overhead).

**`panel/1`** — Root layout function (used as `live_session` layout):
- Renders daisyUI `drawer lg:drawer-open` pattern
- Sets `data-theme` from `@panel_theme`
- Contains `sidebar/1` in `drawer-side`, everything else in `drawer-content`

**`sidebar/1`** — Sidebar navigation:
- Brand/logo header
- Nav groups with headings
- Ungrouped items at top
- Active state highlighting (daisyUI `active` class)
- Icons via `hero-*` Heroicon names, fallback to first letter
- Theme switcher toggle at bottom (if enabled)

**`topbar/1`** — Top bar:
- Hamburger button (visible only on mobile, `lg:hidden`)
- Currently empty on right side (user menu deferred to v0.2)

**`breadcrumbs/1`** — Breadcrumb trail:
- Panel brand → Resource plural_label → Action label
- Each item is a link except the last (current page)
- Auto-computed: `Admin > Posts > New Post`

**`flash_group/1`** — Toast notifications:
- daisyUI `toast toast-end` position (bottom-right, fixed)
- `alert-success` for `:info` flash, `alert-error` for `:error` flash
- Auto-dismiss after ~5 seconds via `phx-mounted` + `JS.transition`

## 7. Dashboard & Widget System

### Dashboard LiveView

`PhoenixFilament.Panel.Dashboard` is a LiveView that:
1. On mount: reads `panel_module.__panel__(:widgets)`, sorts by `:sort`
2. If `__panel__(:opts)[:dashboard]` is set, delegates to the custom LiveView instead
3. Renders a 12-column Tailwind grid with widgets as LiveComponents

```heex
<div class="grid grid-cols-12 gap-4 p-6">
  <div :for={w <- @widgets} class={"col-span-#{w.column_span}"}>
    <.live_component module={w.module} id={"widget-#{w.id}"} panel={@panel_module} />
  </div>
</div>
```

### Widget Behaviours

#### `PhoenixFilament.Widget.StatsOverview`

```elixir
@callback stats(assigns :: map()) :: [stat()]
```

Where `stat()` is built via the `stat/3` helper:
```elixir
stat(label, value, opts \\ [])
# opts: icon, description, description_icon, color (:success | :error | :warning | :info), chart (list of numbers for sparkline)
```

**Rendering:** Each stat renders as a daisyUI card with:
- Label (small uppercase), value (large bold number), description + icon, color accent, optional sparkline (SVG, no JS needed for mini charts)

**Polling:** If `@polling_interval` module attribute is set, the LiveComponent schedules `Process.send_after(self(), :refresh, interval)` and re-calls `stats/1` on tick.

#### `PhoenixFilament.Widget.Chart`

```elixir
@callback chart_type() :: :line | :bar | :pie | :doughnut
@callback chart_data(assigns :: map()) :: %{labels: [String.t()], datasets: [map()]}
@optional_callbacks chart_options: 0
@callback chart_options() :: map()  # Chart.js options passthrough
```

**Rendering:** Renders `<canvas phx-hook="PhxFilamentChart" data-chart={Jason.encode!(data)} data-type={type}>`. The colocated JS hook initializes Chart.js and updates on `phx:update`.

**Chart.js distribution:** Bundled as `priv/static/vendor/chart.min.js`. The installer (Phase 8) copies to `assets/vendor/`. Imported in the app's `app.js`.

#### `PhoenixFilament.Widget.Table`

```elixir
@callback query() :: Ecto.Query.t()
@callback columns() :: [PhoenixFilament.Column.t()]
@optional_callbacks repo: 0, heading: 0
@callback repo() :: module()       # defaults to panel's first resource repo
@callback heading() :: String.t()  # widget title
```

**Rendering:** Wraps `PhoenixFilament.Table.TableLive` (Phase 4) as a simplified read-only table inside the widget card. No actions, no filters — just query + columns.

#### `PhoenixFilament.Widget.Custom`

```elixir
@callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
@optional_callbacks mount: 1, update: 2, handle_event: 3
```

Free-form LiveComponent. Developer has full control over render, state, and events.

### Widget Polling

All widget base modules support `@polling_interval`:

```elixir
# In widget base module:
def handle_info(:refresh, socket) do
  # Re-call the widget's data callback (stats/1, chart_data/1, etc.)
  # Update assigns
  # Re-schedule next refresh
  Process.send_after(self(), :refresh, @polling_interval)
  {:noreply, updated_socket}
end
```

Default: no polling (`@polling_interval nil`).

## 8. Auth & Session Security

### Auth Flow

1. **HTTP request** → `plug` (if configured) validates session cookie. Unauthorized → redirect to login.
2. **LiveView mount** → user's `on_mount` runs first. Sets `current_user` or returns `{:halt, redirect}`.
3. **Panel.Hook** → runs only if user's hook didn't halt. Injects panel assigns. Subscribes PubSub.
4. **Reconnect** → same `on_mount` chain runs again. Expired sessions caught.

### Session Revocation

```elixir
# Developer calls when revoking admin access:
PhoenixFilament.Panel.revoke_sessions(MyApp.PubSub, user_id)
# → Phoenix.PubSub.broadcast(pubsub, "user_sessions:#{user_id}", :session_revoked)

# Panel.Hook handle_info (injected via attach_hook):
def handle_info(:session_revoked, socket) do
  {:noreply, socket |> put_flash(:error, "Session revoked") |> redirect(to: "/login")}
end
```

### Auth Optional with Warning

If `on_mount` is not configured, Panel works without auth (useful for dev/prototyping). A compile-time warning is emitted:

```
warning: Panel MyApp.Admin has no on_mount configured. Add on_mount for production use.
```

## 9. Error Handling

| Scenario | Handling |
|----------|----------|
| User not authenticated | User's `on_mount` returns `{:halt, redirect}`. Panel.Hook never runs. |
| Session revoked | PubSub broadcast → `handle_info` → flash + redirect to login |
| Widget callback raises | LiveComponent catches error, renders error card. Other widgets unaffected. |
| Invalid panel config | NimbleOptions compile-time error with clear message |
| Missing resource module | Compile-time error from resource macro validation |
| PubSub not configured | Session revocation silently does nothing. Warning logged at panel compile. |
| No widgets declared | Dashboard renders empty state: "No widgets configured" |

## 10. Testing Strategy

| Test Area | What to Assert |
|-----------|---------------|
| **Panel module** | `__panel__/1` returns correct resources, widgets, opts |
| **Router expansion** | Route helpers exist, correct LiveView modules and live_actions |
| **Panel.Hook** | Mock socket mount → panel assigns injected (panel_nav, panel_brand, breadcrumbs) |
| **Navigation** | `build_tree/2` with various configs → correct groups, items, active state |
| **Layout components** | `render_component` for sidebar/topbar/breadcrumbs → correct HTML structure |
| **Dashboard** | Mount Dashboard LiveView → widgets render in grid |
| **StatsOverview widget** | LiveComponent renders stat cards with correct values |
| **Chart widget** | LiveComponent renders canvas with correct data-chart JSON |
| **Table widget** | LiveComponent renders table with query results |
| **Custom widget** | LiveComponent renders developer's HEEx |
| **Widget polling** | Assert `:refresh` message triggers re-render |
| **Auth integration** | Mount without current_user → halt; with current_user → panel renders |
| **Session revocation** | Broadcast `:session_revoked` → assert redirect |
| **Compile-time safety** | Touch panel module → resources don't recompile (cascade test) |
| **Multiple panels** | Two panels in router → independent sessions, no route collision |

---

*Phase: 06-panel-shell-and-auth-hook*
*Design approved: 2026-04-02*

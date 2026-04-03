# Getting Started with PhoenixFilament

PhoenixFilament lets you go from an Ecto schema to a fully-functional admin interface in minutes.
This guide walks you through installation, your first resource, and common customizations.

## Prerequisites

Before starting, you need:

- A Phoenix 1.7+ application with at least one Ecto schema
- Phoenix LiveView installed and configured
- Tailwind CSS configured (Phoenix 1.7+ includes it by default)
- daisyUI 5 (optional but recommended — Phoenix 1.8 includes it by default)

If you are on Phoenix 1.8, all of the above are included out of the box.

## Installation

### 1. Add dependencies

Add PhoenixFilament and Igniter to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_filament, "~> 0.1"},
    {:igniter, "~> 0.7"}  # required for the installer
  ]
end
```

Fetch your dependencies:

```bash
mix deps.get
```

### 2. Run the installer

```bash
mix phx_filament.install
```

The installer is idempotent — safe to run multiple times.

## What the Installer Creates

Running `mix phx_filament.install` creates three files:

**`lib/my_app_web/admin.ex`** — your Panel module:

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "MyApp Admin"

  # Add resources with: mix phx_filament.gen.resource MyApp.Schema
end
```

**`assets/vendor/chart.min.js`** — the Chart.js library for chart widgets.

**`assets/js/phx_filament_hooks.js`** — the LiveView hook that powers Chart widgets.

## Router Setup

Add two lines to your `router.ex`:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # 1. Import the panel router macro
  import PhoenixFilament.Panel.Router

  pipeline :browser do
    # ... your existing pipeline
  end

  scope "/" do
    pipe_through :browser

    # 2. Mount the panel
    phoenix_filament_panel "/admin", MyAppWeb.Admin
  end
end
```

The `phoenix_filament_panel/2` macro registers all CRUD routes, the dashboard, and any
plugin routes automatically.

## Hook Setup

Open `assets/js/app.js` and import the PhoenixFilament hooks:

```javascript
import PhxFilamentHooks from "./phx_filament_hooks"

// Find your LiveSocket initialization and merge the hooks:
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  // Merge PhoenixFilament hooks with any existing hooks:
  hooks: {...Hooks, ...PhxFilamentHooks}
})
```

If you don't have any custom hooks yet, the hooks object will simply be `PhxFilamentHooks`.

## Your First Resource

Generate a resource for an existing Ecto schema:

```bash
mix phx_filament.gen.resource MyApp.Blog.Post
```

This creates `lib/my_app_web/admin/post_resource.ex`:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo
end
```

### Register the resource in your Panel

Open `lib/my_app_web/admin.ex` and add the resource:

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "MyApp Admin"

  resources do
    resource MyAppWeb.Admin.PostResource,
      icon: "hero-document-text",
      nav_group: "Blog"
  end
end
```

## Visit /admin

Start your Phoenix server:

```bash
mix phx.server
```

Navigate to `http://localhost:4000/admin`. You will see:

- A sidebar with "Posts" listed under "Blog"
- An index page with a table of all posts, with search, sort, and pagination
- Create / Edit / View / Delete actions out of the box

PhoenixFilament auto-derives columns and form fields from your Ecto schema — no additional
configuration required to get a working interface.

## Customizing Forms

By default, PhoenixFilament infers form fields from your schema's Ecto field types. To
customize, add a `form do...end` block to your resource:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo,
    label: "Post",
    plural_label: "Posts"

  form do
    text_input :title, label: "Title", placeholder: "Enter post title"
    textarea :body, label: "Body"
    toggle :published, label: "Published"
    date :published_at, label: "Publish Date"
  end
end
```

### Available field types

| Macro | Description |
|-------|-------------|
| `text_input :name` | Single-line text input |
| `textarea :name` | Multi-line text area |
| `number_input :name` | Numeric input |
| `select :name, options: [...]` | Drop-down select |
| `checkbox :name` | Checkbox (boolean) |
| `toggle :name` | Toggle switch (boolean) |
| `date :name` | Date picker |
| `datetime :name` | Date + time picker |
| `hidden :name` | Hidden field |

All field macros accept these common options:

- `label:` — override the auto-derived label
- `placeholder:` — input placeholder text

### Form sections

Group related fields with `section`:

```elixir
form do
  section "Basic Info" do
    text_input :title
    textarea :body
  end

  section "Publishing" do
    toggle :published
    date :published_at
  end
end
```

### Multi-column layout

Use `columns` to render fields side by side:

```elixir
form do
  columns 2 do
    text_input :first_name
    text_input :last_name
  end

  textarea :bio
end
```

### Conditional field visibility

Show or hide a field based on another field's value using `visible_when`:

```elixir
form do
  toggle :published
  date :published_at, visible_when: [field: :published, eq: true]
end
```

`visible_when` accepts `field:` (the field to watch) and `eq:` (the value that makes this
field visible). The check happens in real-time as the user fills in the form.

You can also apply `visible_when` to an entire section:

```elixir
form do
  toggle :published

  section "Schedule", visible_when: [field: :published, eq: true] do
    date :published_at
    select :timezone, options: ["UTC", "America/New_York", "Europe/Berlin"]
  end
end
```

## Customizing Tables

Add a `table do...end` block to your resource to customize the index listing:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  table do
    column :title, label: "Title"
    column :published, label: "Published"
    column :inserted_at, label: "Created"

    actions do
      action :view,   label: "View",   icon: "hero-eye"
      action :edit,   label: "Edit",   icon: "hero-pencil"
      action :delete, label: "Delete", icon: "hero-trash", confirm: "Are you sure?"
    end

    filters do
      boolean_filter :published, label: "Published"
      select_filter :author_id, label: "Author", options: [{"Alice", 1}, {"Bob", 2}]
    end
  end
end
```

### Columns

Each `column` declaration renders a column in the index table.

```elixir
column :field_name                          # auto-derives label
column :field_name, label: "Custom Label"  # explicit label
```

### Actions

The `actions do...end` block defines the per-row action buttons.

```elixir
actions do
  action :view                                           # View action (shows the record)
  action :edit                                           # Edit action (opens edit form)
  action :delete, confirm: "Delete this post?"          # Delete with confirmation dialog
  action :archive, label: "Archive", icon: "hero-archive-box"  # Custom action
end
```

Built-in action types (`:view`, `:edit`, `:delete`) are handled automatically.
Custom action types dispatch `{:table_action, action, id}` to your resource's `handle_info/2`,
which you can override:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  @impl true
  def handle_info({:table_action, :archive, id}, socket) do
    MyApp.Blog.archive_post(id)
    {:noreply, Phoenix.LiveView.put_flash(socket, :info, "Post archived")}
  end

  def handle_info(msg, socket), do: super(msg, socket)
end
```

### Filters

The `filters do...end` block renders a filter toolbar above the table.

```elixir
filters do
  boolean_filter :published                              # true / false toggle
  select_filter  :status, options: [{"Draft", "draft"}, {"Published", "published"}]
  date_filter    :inserted_at, label: "Created After"   # date range picker
end
```

### Search

Full-text search across string columns is enabled by default. The search box appears in the
table header and searches across all `:string` fields in your schema.

### Pagination and Sorting

Pagination and column sorting are enabled automatically. Clicking any column header toggles
ascending/descending sort. Pagination controls appear below the table.

## Dashboard Widgets

The dashboard (the page you land on at `/admin`) supports four widget types:
`StatsOverview`, `Chart`, `Table`, and `Custom`.

### StatsOverview widget

Shows stat cards with optional icons, colors, and sparklines.

```elixir
defmodule MyAppWeb.Admin.OverviewStats do
  use PhoenixFilament.Widget.StatsOverview

  @impl true
  def stats(_assigns) do
    [
      stat("Total Posts", MyApp.Repo.aggregate(MyApp.Blog.Post, :count),
        icon: "hero-document-text",
        color: :success,
        description: "#{new_today()} new today"),

      stat("Published", published_count(),
        icon: "hero-check-circle",
        color: :info),

      stat("Draft", draft_count(),
        icon: "hero-pencil-square",
        color: :warning)
    ]
  end

  defp new_today, do: 0       # implement with real query
  defp published_count, do: 0 # implement with real query
  defp draft_count, do: 0     # implement with real query
end
```

`stat/2` and `stat/3` build stat card data. Options for `stat/3`:

| Option | Values | Description |
|--------|--------|-------------|
| `icon:` | Heroicon name | Icon displayed in the stat card |
| `color:` | `:success`, `:error`, `:warning`, `:info` | Value text color |
| `description:` | String | Subtitle text below the value |
| `chart:` | List of numbers | Renders an inline sparkline |

### Chart widget

Renders a Chart.js chart. Requires the hook setup described above.

```elixir
defmodule MyAppWeb.Admin.PostsChart do
  use PhoenixFilament.Widget.Chart

  @impl true
  def chart_type, do: :bar

  @impl true
  def chart_data(_assigns) do
    %{
      labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
      datasets: [
        %{
          label: "Posts Published",
          data: [12, 19, 8, 25, 14, 30],
          backgroundColor: "rgba(99, 102, 241, 0.5)"
        }
      ]
    }
  end

  # Optional: override default Chart.js options
  def chart_options do
    %{responsive: true, plugins: %{legend: %{position: "top"}}}
  end
end
```

Supported `chart_type` values: `:line`, `:bar`, `:pie`, `:doughnut`

### Table widget

Renders a read-only table on the dashboard.

```elixir
defmodule MyAppWeb.Admin.RecentPosts do
  use PhoenixFilament.Widget.Table

  @impl true
  def heading, do: "Recent Posts"

  @impl true
  def columns do
    [
      PhoenixFilament.Column.column(:title, label: "Title"),
      PhoenixFilament.Column.column(:inserted_at, label: "Date")
    ]
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)
    rows = MyApp.Repo.all(
      from p in MyApp.Blog.Post,
        order_by: [desc: p.inserted_at],
        limit: 10
    )
    {:ok, Phoenix.Component.assign(socket, :rows, rows)}
  end
end
```

### Custom widget

For completely custom dashboard content, use `PhoenixFilament.Widget.Custom`:

```elixir
defmodule MyAppWeb.Admin.WelcomeWidget do
  use PhoenixFilament.Widget.Custom

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title">Welcome to the Admin Panel</h2>
        <p>You are logged in as {@current_user.email}.</p>
      </div>
    </div>
    """
  end
end
```

### Registering widgets in your Panel

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "MyApp Admin"

  resources do
    resource MyAppWeb.Admin.PostResource, icon: "hero-document-text"
  end

  widgets do
    widget MyAppWeb.Admin.OverviewStats, sort: 1, column_span: :full
    widget MyAppWeb.Admin.PostsChart,    sort: 2, column_span: 6
    widget MyAppWeb.Admin.RecentPosts,   sort: 3, column_span: 6
  end
end
```

Widget options:

| Option | Default | Description |
|--------|---------|-------------|
| `sort:` | `0` | Rendering order (ascending) |
| `column_span:` | `12` (full width) | Grid column span: 1–12 or `:full` |

## Theming

PhoenixFilament uses daisyUI's theme system. Set a theme per panel:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  brand_name: "MyApp Admin",
  theme: "corporate"
```

Popular daisyUI themes: `light`, `dark`, `corporate`, `retro`, `cyberpunk`, `cupcake`,
`bumblebee`, `emerald`, `synthwave`, `dracula`, `night`, `dim`, `nord`, `sunset`.

### Dark mode toggle

Enable a built-in light/dark toggle button in the panel header:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  theme: "corporate",
  theme_switcher: true
```

When `theme_switcher: true`, a sun/moon icon button appears in the top navigation bar.
It uses daisyUI's `theme-controller` — clicking it toggles between the configured theme
and `dark`.

## Authentication

PhoenixFilament does not bundle an auth solution — it integrates with whatever your app
already uses.

### LiveView on_mount hook

The recommended approach is to use a LiveView `on_mount` hook. If you use `phx.gen.auth`,
the generated `UserAuth` module includes an `on_mount/4` callback:

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel,
    path: "/admin",
    on_mount: {MyAppWeb.UserAuth, :require_authenticated_user},
    brand_name: "MyApp Admin"

  resources do
    resource MyAppWeb.Admin.PostResource, icon: "hero-document-text"
  end
end
```

The `on_mount:` option must be a `{Module, :function}` tuple. The function must match the
`Phoenix.LiveView.on_mount/4` callback signature:

```elixir
def on_mount(:require_authenticated_user, _params, session, socket) do
  # validate session, assign current_user, or redirect
  {:cont, assign(socket, :current_user, user)}
  # or {:halt, redirect(socket, to: "/login")}
end
```

### HTTP-level authentication

For HTTP-level protection (guards against non-LiveView requests), use `pipe_through`:

```elixir
scope "/admin" do
  pipe_through [:browser, :require_authenticated_user]
  phoenix_filament_panel "/", MyAppWeb.Admin
end
```

### Session revocation

To disconnect all live sessions for a user (e.g. after password change, logout-everywhere):

```elixir
# In your UserAuth or session management code:
PhoenixFilament.Panel.revoke_sessions(MyApp.PubSub, current_user.id)
```

This requires the `pubsub:` option on your panel:

```elixir
use PhoenixFilament.Panel,
  path: "/admin",
  pubsub: MyApp.PubSub,
  on_mount: {MyAppWeb.UserAuth, :require_authenticated_user}
```

## Plugins

Plugins let you add custom navigation, routes, and widgets to a panel without modifying
the panel module directly.

### Using a community plugin

```elixir
defmodule MyAppWeb.Admin do
  use PhoenixFilament.Panel, path: "/admin"

  plugins do
    plugin MyApp.AnalyticsPlugin
    plugin MyApp.AuditLogPlugin, nav_group: "System"
  end
end
```

Plugin options (the keyword list after the module name) are passed to the plugin's
`register/2` callback.

### Creating a simple plugin

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
          nav_group: opts[:nav_group] || "Reports")
      ],
      routes: [
        route("/analytics", MyAppWeb.AnalyticsLive, :index)
      ]
    }
  end
end
```

See the [Plugin Development Guide](plugins.html) for the full plugin API.

## Authorization

You can define an `authorize/3` callback on any resource to control CRUD access:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  def authorize(:delete, _record, %{role: "admin"}), do: :ok
  def authorize(:delete, _record, _user), do: {:error, :forbidden}
  def authorize(_action, _record, _user), do: :ok
end
```

`authorize/3` receives:
- `action` — `:index`, `:create`, `:edit`, `:delete`, or `:show`
- `record` — the Ecto struct (or `nil` for `:create`)
- `user` — the value of `socket.assigns.current_user`

Return `:ok` to allow or `{:error, reason}` to deny (raises `UnauthorizedError`).

## Next Steps

- [Resource Customization](resources.html) — Complete reference for form fields, table columns, filters, and authorization
- [Plugin Development](plugins.html) — Build and distribute your own plugins
- [Theming Guide](theming.html) — Custom themes, CSS variables, brand customization
- [API Reference](PhoenixFilament.Resource.html) — Module-level API documentation

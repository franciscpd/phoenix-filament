# Phase 7: Plugin Architecture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a formal `PhoenixFilament.Plugin` behaviour so the framework and third-party authors use the same extension API. Refactor built-in Resource and Widget systems into implicit plugins. Resolve all plugins at compile time, boot at runtime.

**Architecture:** Plugin behaviour with `register/2` (compile-time metadata) + `boot/1` (runtime socket init). Panel `__before_compile__` calls `Plugin.Resolver` to merge all plugins into unified lists. Router/Hook/Dashboard consume unified lists. Built-in ResourcePlugin and WidgetPlugin use the public behaviour — no bypass APIs.

**Tech Stack:** Elixir, Phoenix LiveView 1.1, NimbleOptions, `attach_hook/4`

---

## File Structure

```
NEW FILES:
lib/phoenix_filament/plugin.ex                       # Behaviour + use macro + helpers
lib/phoenix_filament/plugin/resolver.ex               # Merge plugin register/2 results
lib/phoenix_filament/plugins/resource_plugin.ex       # Built-in ResourcePlugin
lib/phoenix_filament/plugins/widget_plugin.ex         # Built-in WidgetPlugin

test/phoenix_filament/plugin_test.exs                 # Behaviour + helpers tests
test/phoenix_filament/plugin/resolver_test.exs        # Resolver merge tests
test/phoenix_filament/plugins/resource_plugin_test.exs
test/phoenix_filament/plugins/widget_plugin_test.exs
test/support/plugins/test_community_plugin.ex         # Test community plugin

MODIFIED FILES:
lib/phoenix_filament/panel.ex                         # Add plugin accumulator, resolve in __before_compile__
lib/phoenix_filament/panel/dsl.ex                     # Add plugins/1, plugin/2 macros
lib/phoenix_filament/panel/options.ex                 # Add plugin_schema/0
lib/phoenix_filament/panel/navigation.ex              # Change build_tree/3 → build_tree/2 (accept nav_items directly)
lib/phoenix_filament/panel/hook.ex                    # Read :all_nav_items, boot plugins, attach hooks
lib/phoenix_filament/panel/router.ex                  # Read :all_routes
lib/phoenix_filament/panel/dashboard.ex               # Read :all_widgets

test/phoenix_filament/panel/navigation_test.exs       # Update for build_tree/2 signature
test/phoenix_filament/panel/panel_test.exs            # Add plugin integration tests
test/support/panels/test_panel.ex                     # Add plugins block
```

---

## Task 1: Plugin Behaviour + Helpers

**Files:**
- Create: `lib/phoenix_filament/plugin.ex`
- Create: `test/phoenix_filament/plugin_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/plugin_test.exs
defmodule PhoenixFilament.PluginTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugin

  describe "nav_item/2" do
    test "builds nav item map with all fields" do
      item = Plugin.nav_item("Analytics", path: "/analytics", icon: "hero-chart-bar", nav_group: "Reports")

      assert item.label == "Analytics"
      assert item.path == "/analytics"
      assert item.icon == "hero-chart-bar"
      assert item.nav_group == "Reports"
      assert item.icon_fallback == "A"
    end

    test "handles missing optional fields" do
      item = Plugin.nav_item("Settings", path: "/settings")

      assert item.label == "Settings"
      assert item.path == "/settings"
      assert item.icon == nil
      assert item.nav_group == nil
      assert item.icon_fallback == "S"
    end
  end

  describe "route/3" do
    test "builds route map" do
      route = Plugin.route("/analytics", MyApp.AnalyticsLive, :index)

      assert route.path == "/analytics"
      assert route.live_view == MyApp.AnalyticsLive
      assert route.live_action == :index
    end
  end

  describe "use PhoenixFilament.Plugin" do
    test "injects @behaviour and imports helpers" do
      defmodule TestPlugin do
        use PhoenixFilament.Plugin

        @impl true
        def register(_panel, _opts) do
          %{
            nav_items: [nav_item("Test", path: "/test")],
            routes: [route("/test", TestLive, :index)]
          }
        end
      end

      result = TestPlugin.register(nil, [])
      assert length(result.nav_items) == 1
      assert hd(result.nav_items).label == "Test"
      assert length(result.routes) == 1
      assert hd(result.routes).path == "/test"
    end
  end

  describe "@experimental moduledoc" do
    test "module has documentation" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(Plugin)
      assert moduledoc =~ "Experimental"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/plugin_test.exs`
Expected: FAIL — `PhoenixFilament.Plugin` not found

- [ ] **Step 3: Implement Plugin behaviour**

```elixir
# lib/phoenix_filament/plugin.ex
defmodule PhoenixFilament.Plugin do
  @moduledoc """
  Plugin behaviour for extending PhoenixFilament panels.

  > #### Experimental {: .warning}
  >
  > The Plugin API is experimental. Breaking changes may occur in
  > minor versions until this notice is removed. Pin your
  > `phoenix_filament` dependency to a specific version when using plugins.

  ## Quick Start

  Create a plugin module:

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
              route("/analytics", MyApp.AnalyticsLive, :index)
            ]
          }
        end
      end

  Register it in your panel:

      defmodule MyApp.Admin do
        use PhoenixFilament.Panel, path: "/admin"

        plugins do
          plugin MyApp.AnalyticsPlugin
        end
      end

  ## Callbacks

  ### `register/2` (required)

  Called at compile time. Returns a map with any of these optional keys:

  - `:nav_items` — sidebar navigation entries (use `nav_item/2` helper)
  - `:routes` — custom live routes (use `route/3` helper)
  - `:widgets` — dashboard widgets (`%{module, sort, column_span}`)
  - `:hooks` — lifecycle hooks (`{:handle_event, &fun/3}`, etc.)

  ### `boot/1` (optional)

  Called at runtime on each LiveView mount. Receives the socket, returns
  the socket. Use for runtime initialization (assigns, PubSub subscriptions).

  Cannot halt the mount — authentication is the Panel's responsibility.

  ## Stability Roadmap

  - **v0.1.x** — `@experimental`, may break in minor versions
  - **v0.2+** — stabilize based on community feedback
  - **v1.0** — stable, semver-protected
  """

  @type nav_item :: %{
          label: String.t(),
          path: String.t(),
          icon: String.t() | nil,
          nav_group: String.t() | nil,
          icon_fallback: String.t()
        }

  @type route :: %{
          path: String.t(),
          live_view: module(),
          live_action: atom()
        }

  @type register_result :: %{
          optional(:nav_items) => [nav_item()],
          optional(:routes) => [route()],
          optional(:widgets) => [map()],
          optional(:hooks) => [{atom(), function()}]
        }

  @callback register(panel :: module(), opts :: keyword()) :: register_result()
  @callback boot(socket :: Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  @optional_callbacks [boot: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour PhoenixFilament.Plugin
      import PhoenixFilament.Plugin, only: [nav_item: 2, route: 3]
    end
  end

  @doc "Builds a navigation item map for sidebar entries."
  @spec nav_item(String.t(), keyword()) :: nav_item()
  def nav_item(label, opts) do
    %{
      label: label,
      path: opts[:path],
      icon: opts[:icon],
      nav_group: opts[:nav_group],
      icon_fallback: String.first(label)
    }
  end

  @doc "Builds a route map for custom live routes."
  @spec route(String.t(), module(), atom()) :: route()
  def route(path, live_view, live_action) do
    %{path: path, live_view: live_view, live_action: live_action}
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/plugin_test.exs`
Expected: All PASS

- [ ] **Step 5: Commit**

```
feat(plugin): add Plugin behaviour with register/2, boot/1 and helpers
```

---

## Task 2: Plugin.Resolver

**Files:**
- Create: `lib/phoenix_filament/plugin/resolver.ex`
- Create: `test/phoenix_filament/plugin/resolver_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/plugin/resolver_test.exs
defmodule PhoenixFilament.Plugin.ResolverTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugin.Resolver

  defmodule NavPlugin do
    use PhoenixFilament.Plugin
    @impl true
    def register(_panel, _opts) do
      %{nav_items: [nav_item("Reports", path: "/reports", icon: "hero-chart-bar")]}
    end
  end

  defmodule RoutePlugin do
    use PhoenixFilament.Plugin
    @impl true
    def register(_panel, _opts) do
      %{routes: [route("/custom", CustomLive, :index)]}
    end
  end

  defmodule FullPlugin do
    use PhoenixFilament.Plugin
    @impl true
    def register(_panel, opts) do
      %{
        nav_items: [nav_item("Full", path: "/full")],
        routes: [route("/full", FullLive, :index)],
        widgets: [%{module: FullWidget, sort: 1, column_span: 6}],
        hooks: [{:handle_info, &__MODULE__.on_info/2}]
      }
    end
    def on_info(_msg, socket), do: {:cont, socket}
  end

  defmodule ErrorPlugin do
    use PhoenixFilament.Plugin
    @impl true
    def register(_panel, _opts), do: raise("boom")
  end

  describe "resolve/2" do
    test "merges nav_items from multiple plugins in order" do
      plugins = [{NavPlugin, []}, {FullPlugin, []}]
      result = Resolver.resolve(plugins, nil)

      assert length(result.all_nav_items) == 2
      assert hd(result.all_nav_items).label == "Reports"
      assert List.last(result.all_nav_items).label == "Full"
    end

    test "merges routes from multiple plugins" do
      plugins = [{RoutePlugin, []}, {FullPlugin, []}]
      result = Resolver.resolve(plugins, nil)

      assert length(result.all_routes) == 2
    end

    test "sorts widgets by :sort" do
      plugins = [{FullPlugin, []}]
      result = Resolver.resolve(plugins, nil)

      assert length(result.all_widgets) == 1
      assert hd(result.all_widgets).sort == 1
    end

    test "collects hooks from plugins" do
      plugins = [{FullPlugin, []}]
      result = Resolver.resolve(plugins, nil)

      assert length(result.all_hooks) == 1
      [{:handle_info, fun}] = result.all_hooks
      assert is_function(fun, 2)
    end

    test "defaults missing keys to empty lists" do
      plugins = [{NavPlugin, []}]
      result = Resolver.resolve(plugins, nil)

      assert result.all_routes == []
      assert result.all_widgets == []
      assert result.all_hooks == []
    end

    test "empty plugin list returns empty results" do
      result = Resolver.resolve([], nil)

      assert result.all_nav_items == []
      assert result.all_routes == []
      assert result.all_widgets == []
      assert result.all_hooks == []
    end

    test "wraps register/2 errors with descriptive message" do
      assert_raise RuntimeError, ~r/boom/, fn ->
        Resolver.resolve([{ErrorPlugin, []}], nil)
      end
    end

    test "passes opts to register/2" do
      defmodule OptsPlugin do
        use PhoenixFilament.Plugin
        @impl true
        def register(_panel, opts) do
          %{nav_items: [PhoenixFilament.Plugin.nav_item(opts[:label] || "Default", path: "/x")]}
        end
      end

      result = Resolver.resolve([{OptsPlugin, [label: "Custom"]}], nil)
      assert hd(result.all_nav_items).label == "Custom"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/plugin/resolver_test.exs`
Expected: FAIL — `PhoenixFilament.Plugin.Resolver` not found

- [ ] **Step 3: Implement Resolver**

```elixir
# lib/phoenix_filament/plugin/resolver.ex
defmodule PhoenixFilament.Plugin.Resolver do
  @moduledoc false

  @defaults %{nav_items: [], routes: [], widgets: [], hooks: []}

  @doc """
  Resolves all plugins by calling register/2 on each and merging results.

  Returns %{all_nav_items, all_routes, all_widgets, all_hooks}.
  """
  def resolve(plugins, panel_module) do
    results =
      Enum.map(plugins, fn {mod, opts} ->
        result = mod.register(panel_module, opts)
        Map.merge(@defaults, result)
      end)

    %{
      all_nav_items: Enum.flat_map(results, & &1.nav_items),
      all_routes: Enum.flat_map(results, & &1.routes),
      all_widgets: Enum.flat_map(results, & &1.widgets) |> Enum.sort_by(& &1[:sort] || 0),
      all_hooks: Enum.flat_map(results, & &1.hooks)
    }
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/plugin/resolver_test.exs`
Expected: All PASS

- [ ] **Step 5: Commit**

```
feat(plugin): add Resolver to merge plugin registrations into unified lists
```

---

## Task 3: Built-in ResourcePlugin + WidgetPlugin

**Files:**
- Create: `lib/phoenix_filament/plugins/resource_plugin.ex`
- Create: `lib/phoenix_filament/plugins/widget_plugin.ex`
- Create: `test/phoenix_filament/plugins/resource_plugin_test.exs`
- Create: `test/phoenix_filament/plugins/widget_plugin_test.exs`

- [ ] **Step 1: Write failing tests for ResourcePlugin**

```elixir
# test/phoenix_filament/plugins/resource_plugin_test.exs
defmodule PhoenixFilament.Plugins.ResourcePluginTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugins.ResourcePlugin

  @resources [
    %{module: PostResource, icon: "hero-document-text", nav_group: "Content",
      slug: "posts", label: "Post", plural_label: "Posts"},
    %{module: UserResource, icon: "hero-users", nav_group: nil,
      slug: "users", label: "User", plural_label: "Users"}
  ]

  # Fake panel module for register/2
  defmodule FakePanel do
    def __panel__(:path), do: "/admin"
  end

  describe "register/2" do
    test "generates nav_items from resources" do
      result = ResourcePlugin.register(FakePanel, resources: @resources)

      assert length(result.nav_items) == 2
      [posts, users] = result.nav_items
      assert posts.label == "Posts"
      assert posts.path == "/admin/posts"
      assert posts.icon == "hero-document-text"
      assert posts.nav_group == "Content"
      assert users.label == "Users"
      assert users.nav_group == nil
    end

    test "generates 4 CRUD routes per resource" do
      result = ResourcePlugin.register(FakePanel, resources: @resources)

      assert length(result.routes) == 8  # 4 routes × 2 resources

      post_routes = Enum.filter(result.routes, &String.starts_with?(&1.path, "/posts"))
      assert length(post_routes) == 4
      actions = Enum.map(post_routes, & &1.live_action) |> Enum.sort()
      assert actions == [:edit, :index, :new, :show]
    end

    test "routes reference correct live_view modules" do
      result = ResourcePlugin.register(FakePanel, resources: @resources)

      index = Enum.find(result.routes, &(&1.path == "/posts" && &1.live_action == :index))
      assert index.live_view == PostResource
    end

    test "empty resources returns empty results" do
      result = ResourcePlugin.register(FakePanel, resources: [])
      assert result.nav_items == []
      assert result.routes == []
    end
  end
end
```

- [ ] **Step 2: Write failing tests for WidgetPlugin**

```elixir
# test/phoenix_filament/plugins/widget_plugin_test.exs
defmodule PhoenixFilament.Plugins.WidgetPluginTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugins.WidgetPlugin

  describe "register/2" do
    test "passes through widget list" do
      widgets = [%{module: StatsWidget, sort: 1, column_span: 12}]
      result = WidgetPlugin.register(nil, widgets: widgets)

      assert result.widgets == widgets
    end

    test "empty widgets returns empty list" do
      result = WidgetPlugin.register(nil, widgets: [])
      assert result.widgets == []
    end

    test "defaults to empty when no widgets option" do
      result = WidgetPlugin.register(nil, [])
      assert result.widgets == []
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/plugins/`
Expected: FAIL — modules not found

- [ ] **Step 4: Implement ResourcePlugin**

```elixir
# lib/phoenix_filament/plugins/resource_plugin.ex
defmodule PhoenixFilament.Plugins.ResourcePlugin do
  @moduledoc false
  use PhoenixFilament.Plugin

  @impl true
  def register(panel, opts) do
    resources = opts[:resources] || []
    panel_path = panel.__panel__(:path)

    %{
      nav_items:
        Enum.map(resources, fn r ->
          nav_item(r.plural_label,
            path: "#{panel_path}/#{r.slug}",
            icon: r.icon,
            nav_group: r.nav_group
          )
        end),
      routes:
        Enum.flat_map(resources, fn r ->
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

- [ ] **Step 5: Implement WidgetPlugin**

```elixir
# lib/phoenix_filament/plugins/widget_plugin.ex
defmodule PhoenixFilament.Plugins.WidgetPlugin do
  @moduledoc false
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    %{widgets: opts[:widgets] || []}
  end
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/plugins/`
Expected: All PASS

- [ ] **Step 7: Commit**

```
feat(plugin): add built-in ResourcePlugin and WidgetPlugin
```

---

## Task 4: Panel DSL + Options — Add plugins block

**Files:**
- Modify: `lib/phoenix_filament/panel/dsl.ex`
- Modify: `lib/phoenix_filament/panel/options.ex`

- [ ] **Step 1: Add plugin_schema to Options**

In `lib/phoenix_filament/panel/options.ex`, add after `@widget_schema`:

```elixir
@plugin_schema NimbleOptions.new!([])
```

And add:
```elixir
def plugin_schema, do: @plugin_schema
```

Note: Plugin registration itself doesn't need NimbleOptions validation — the plugin module validates its own opts via `register/2`. The schema is empty but exists for consistency and future extension.

- [ ] **Step 2: Add plugins/1 and plugin/2 macros to DSL**

In `lib/phoenix_filament/panel/dsl.ex`, add:

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

- [ ] **Step 3: Run existing tests**

Run: `mix test test/phoenix_filament/panel/`
Expected: All 52 tests still PASS (no breaking changes yet)

- [ ] **Step 4: Commit**

```
feat(panel): add plugins DSL block and plugin registration macro
```

---

## Task 5: Panel __before_compile__ — Plugin Resolution

**Files:**
- Modify: `lib/phoenix_filament/panel.ex`
- Create: `test/support/plugins/test_community_plugin.ex`
- Modify: `test/support/panels/test_panel.ex`
- Modify: `test/phoenix_filament/panel/panel_test.exs`

This is the core integration task. The Panel `__using__` and `__before_compile__` are updated to:
1. Register `@_phx_filament_panel_plugins` accumulator
2. Build implicit ResourcePlugin + WidgetPlugin from resources/widgets blocks
3. Call `Resolver.resolve/2` on all plugins
4. Generate new unified accessors alongside existing ones

- [ ] **Step 1: Create test community plugin**

```elixir
# test/support/plugins/test_community_plugin.ex
defmodule PhoenixFilament.Test.Plugins.TestCommunityPlugin do
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
        route("/analytics", PhoenixFilament.Test.Plugins.TestCommunityPlugin, :index)
      ]
    }
  end

  @impl true
  def boot(socket) do
    Phoenix.Component.assign(socket, :analytics_enabled, true)
  end
end
```

- [ ] **Step 2: Update TestPanel with plugins block**

```elixir
# test/support/panels/test_panel.ex
defmodule PhoenixFilament.Test.Panels.TestPanel do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "Test Admin",
    theme: "corporate",
    theme_switcher: true

  resources do
    resource PhoenixFilament.Test.Resources.TestPostResource,
      icon: "hero-document-text",
      nav_group: "Content"
  end

  widgets do
    widget PhoenixFilament.Test.Widgets.TestStats, sort: 1, column_span: :full
    widget PhoenixFilament.Test.Widgets.TestCustom, sort: 2, column_span: 6
  end

  plugins do
    plugin PhoenixFilament.Test.Plugins.TestCommunityPlugin, nav_group: "Tools"
  end
end
```

- [ ] **Step 3: Write failing tests for unified accessors**

Add to `test/phoenix_filament/panel/panel_test.exs`:

```elixir
describe "plugin resolution" do
  test "__panel__(:all_nav_items) includes resources + community plugin nav" do
    nav_items = TestPanel.__panel__(:all_nav_items)

    # ResourcePlugin contributes Posts nav item
    assert Enum.any?(nav_items, &(&1.label == "Posts"))
    # Community plugin contributes Analytics nav item
    assert Enum.any?(nav_items, &(&1.label == "Analytics"))
  end

  test "__panel__(:all_routes) includes resource CRUD routes + plugin routes" do
    routes = TestPanel.__panel__(:all_routes)

    # ResourcePlugin contributes 4 CRUD routes for Posts
    post_routes = Enum.filter(routes, &String.contains?(&1.path, "posts"))
    assert length(post_routes) == 4

    # Community plugin contributes analytics route
    assert Enum.any?(routes, &(&1.path == "/analytics"))
  end

  test "__panel__(:all_widgets) includes widgets from WidgetPlugin" do
    widgets = TestPanel.__panel__(:all_widgets)
    assert length(widgets) == 2
    assert hd(widgets).module == PhoenixFilament.Test.Widgets.TestStats
  end

  test "__panel__(:plugins) returns raw plugin list" do
    plugins = TestPanel.__panel__(:plugins)
    assert is_list(plugins)
    # Should include ResourcePlugin, WidgetPlugin, and community plugin
    assert length(plugins) >= 3
  end

  test "backward compat: __panel__(:resources) still works" do
    resources = TestPanel.__panel__(:resources)
    assert length(resources) == 1
    assert hd(resources).module == TestPostResource
  end

  test "backward compat: __panel__(:widgets) still works" do
    widgets = TestPanel.__panel__(:widgets)
    assert length(widgets) == 2
  end

  test "built-in plugins listed before community plugins" do
    plugins = TestPanel.__panel__(:plugins)
    modules = Enum.map(plugins, &elem(&1, 0))

    resource_idx = Enum.find_index(modules, &(&1 == PhoenixFilament.Plugins.ResourcePlugin))
    community_idx = Enum.find_index(modules, &(&1 == PhoenixFilament.Test.Plugins.TestCommunityPlugin))

    assert resource_idx < community_idx
  end
end
```

- [ ] **Step 4: Run tests to verify new tests fail**

Run: `mix test test/phoenix_filament/panel/panel_test.exs`
Expected: New plugin tests FAIL (`:all_nav_items` etc. not yet implemented)

- [ ] **Step 5: Update Panel `__using__` and `__before_compile__`**

In `lib/phoenix_filament/panel.ex`:

Update `__using__/1` — add plugins accumulator:
```elixir
Module.register_attribute(__MODULE__, :_phx_filament_panel_plugins, accumulate: true)
```

Update `@callback` list — add new accessors:
```elixir
@callback __panel__(:all_nav_items) :: [map()]
@callback __panel__(:all_routes) :: [map()]
@callback __panel__(:all_widgets) :: [map()]
@callback __panel__(:all_hooks) :: [{atom(), function()}]
@callback __panel__(:plugins) :: [{module(), keyword()}]
```

Update `__before_compile__/1` — add plugin resolution after existing `:resources` and `:widgets` accessors:

```elixir
# Build full plugin list: built-in first, then community
@_phx_filament_all_plugins (
  # 1. ResourcePlugin (if resources declared)
  (if @_phx_filament_panel_resources != [] do
    [{PhoenixFilament.Plugins.ResourcePlugin,
      [resources: __MODULE__.__panel__(:resources)]}]
  else
    []
  end) ++
  # 2. WidgetPlugin (if widgets declared)
  (if @_phx_filament_panel_widgets != [] do
    [{PhoenixFilament.Plugins.WidgetPlugin,
      [widgets: __MODULE__.__panel__(:widgets)]}]
  else
    []
  end) ++
  # 3. Community plugins (in declaration order)
  (@_phx_filament_panel_plugins |> Enum.reverse())
)

@_phx_filament_resolved PhoenixFilament.Plugin.Resolver.resolve(
  @_phx_filament_all_plugins,
  __MODULE__
)

@impl PhoenixFilament.Panel
def __panel__(:all_nav_items), do: @_phx_filament_resolved.all_nav_items

@impl PhoenixFilament.Panel
def __panel__(:all_routes), do: @_phx_filament_resolved.all_routes

@impl PhoenixFilament.Panel
def __panel__(:all_widgets), do: @_phx_filament_resolved.all_widgets

@impl PhoenixFilament.Panel
def __panel__(:all_hooks), do: @_phx_filament_resolved.all_hooks

@impl PhoenixFilament.Panel
def __panel__(:plugins), do: @_phx_filament_all_plugins
```

Also update the error clause to include new valid keys:
```elixir
def __panel__(key) do
  raise ArgumentError,
        "unknown panel key #{inspect(key)}. Valid keys are: #{inspect([:opts, :path, :resources, :widgets, :all_nav_items, :all_routes, :all_widgets, :all_hooks, :plugins])}"
end
```

- [ ] **Step 6: Run tests**

Run: `mix test test/phoenix_filament/panel/panel_test.exs`
Expected: All tests PASS (existing + new plugin tests)

- [ ] **Step 7: Commit**

```
feat(panel): integrate Plugin Resolver — unified accessors from all plugins
```

---

## Task 6: Refactor Navigation — build_tree/2

**Files:**
- Modify: `lib/phoenix_filament/panel/navigation.ex`
- Modify: `test/phoenix_filament/panel/navigation_test.exs`

- [ ] **Step 1: Update Navigation tests for new signature**

The `build_tree` function changes from `build_tree(resources, panel_path, current_path)` to `build_tree(nav_items, current_path)` since nav_items now come pre-built from plugins with full paths.

```elixir
# test/phoenix_filament/panel/navigation_test.exs — REPLACE entire file
defmodule PhoenixFilament.Panel.NavigationTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Navigation

  @nav_items [
    %{label: "Posts", path: "/admin/posts", icon: "hero-document-text",
      icon_fallback: "P", nav_group: "Content"},
    %{label: "Categories", path: "/admin/categories", icon: "hero-tag",
      icon_fallback: "C", nav_group: "Content"},
    %{label: "Users", path: "/admin/users", icon: "hero-users",
      icon_fallback: "U", nav_group: "Management"},
    %{label: "Settings", path: "/admin/settings", icon: nil,
      icon_fallback: "S", nav_group: nil}
  ]

  describe "build_tree/2" do
    test "groups nav items by nav_group" do
      tree = Navigation.build_tree(@nav_items, "/admin/posts")

      assert length(tree.groups) == 2
      [content, management] = tree.groups
      assert content.label == "Content"
      assert length(content.items) == 2
      assert management.label == "Management"
      assert length(management.items) == 1
    end

    test "ungrouped items appear separately" do
      tree = Navigation.build_tree(@nav_items, "/admin/settings")
      assert length(tree.ungrouped) == 1
      assert hd(tree.ungrouped).label == "Settings"
    end

    test "marks active item by path prefix match" do
      tree = Navigation.build_tree(@nav_items, "/admin/posts")

      [content | _] = tree.groups
      [posts, categories] = content.items
      assert posts.active == true
      assert categories.active == false
    end

    test "marks active for nested paths" do
      tree = Navigation.build_tree(@nav_items, "/admin/posts/123/edit")

      [content | _] = tree.groups
      [posts | _] = content.items
      assert posts.active == true
    end

    test "preserves declaration order within groups" do
      tree = Navigation.build_tree(@nav_items, "/admin")
      [content | _] = tree.groups
      labels = Enum.map(content.items, & &1.label)
      assert labels == ["Posts", "Categories"]
    end

    test "merges non-adjacent groups with same name" do
      items = [
        %{label: "A", path: "/a", icon: nil, icon_fallback: "A", nav_group: "Blog"},
        %{label: "B", path: "/b", icon: nil, icon_fallback: "B", nav_group: "Admin"},
        %{label: "C", path: "/c", icon: nil, icon_fallback: "C", nav_group: "Blog"}
      ]
      tree = Navigation.build_tree(items, "/")
      assert length(tree.groups) == 2
      [blog | _] = tree.groups
      assert blog.label == "Blog"
      assert length(blog.items) == 2
    end

    test "icon_fallback preserved from input" do
      tree = Navigation.build_tree(@nav_items, "/admin")
      [settings] = tree.ungrouped
      assert settings.icon_fallback == "S"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/navigation_test.exs`
Expected: FAIL — `build_tree/2` doesn't exist (still `build_tree/3`)

- [ ] **Step 3: Update Navigation module**

```elixir
# lib/phoenix_filament/panel/navigation.ex — REPLACE entire file
defmodule PhoenixFilament.Panel.Navigation do
  @moduledoc false

  @doc """
  Builds a navigation tree from pre-built nav items.

  Receives nav items with `:label`, `:path`, `:icon`, `:icon_fallback`,
  `:nav_group`, and adds `:active` based on current_path prefix match.

  Returns `%{groups: [group], ungrouped: [item]}`.
  """
  def build_tree(nav_items, current_path) do
    items = Enum.map(nav_items, &add_active(&1, current_path))

    {grouped, ungrouped} = Enum.split_with(items, &(&1.nav_group != nil))

    groups =
      grouped
      |> Enum.reduce({[], %{}}, fn item, {order, groups} ->
        group_name = item.nav_group

        if Map.has_key?(groups, group_name) do
          {order, Map.update!(groups, group_name, &(&1 ++ [item]))}
        else
          {order ++ [group_name], Map.put(groups, group_name, [item])}
        end
      end)
      |> then(fn {order, groups} ->
        Enum.map(order, fn name -> %{label: name, items: groups[name]} end)
      end)

    %{groups: groups, ungrouped: ungrouped}
  end

  defp add_active(item, current_path) do
    Map.put(item, :active, String.starts_with?(current_path, item.path))
  end
end
```

- [ ] **Step 4: Run tests**

Run: `mix test test/phoenix_filament/panel/navigation_test.exs`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```
refactor(panel): change Navigation.build_tree to accept pre-built nav items
```

---

## Task 7: Refactor Hook — Use unified accessors + boot plugins

**Files:**
- Modify: `lib/phoenix_filament/panel/hook.ex`

- [ ] **Step 1: Update Hook to use unified accessors**

Replace `lib/phoenix_filament/panel/hook.ex` with:

```elixir
defmodule PhoenixFilament.Panel.Hook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  alias PhoenixFilament.Panel.Navigation

  def on_mount({:panel, panel_module}, _params, _session, socket) do
    opts = panel_module.__panel__(:opts)
    nav_items = panel_module.__panel__(:all_nav_items)
    plugins = panel_module.__panel__(:plugins)
    all_hooks = panel_module.__panel__(:all_hooks)
    panel_path = opts[:path]
    current_path = current_path_from_socket(socket)

    socket =
      socket
      |> assign(:panel_module, panel_module)
      |> assign(:panel_brand, opts[:brand_name])
      |> assign(:panel_logo, opts[:logo])
      |> assign(:panel_theme, opts[:theme])
      |> assign(:panel_theme_switcher, opts[:theme_switcher])
      |> assign(:panel_path, panel_path)
      |> assign(:panel_nav, Navigation.build_tree(nav_items, current_path))
      |> assign(:current_resource, match_nav_item(nav_items, current_path))
      |> assign(:breadcrumbs, build_breadcrumbs(opts, nav_items, current_path))

    socket = maybe_subscribe_pubsub(socket, opts)

    # Boot plugins
    socket = boot_plugins(socket, plugins)

    # Attach plugin lifecycle hooks
    socket = attach_plugin_hooks(socket, all_hooks)

    # Nav update on handle_params
    socket =
      Phoenix.LiveView.attach_hook(socket, :panel_nav_update, :handle_params, fn
        _params, uri, socket ->
          path = URI.parse(uri).path
          nav = Navigation.build_tree(nav_items, path)
          crumbs = build_breadcrumbs(opts, nav_items, path)
          current = match_nav_item(nav_items, path)

          {:cont,
           socket
           |> assign(:panel_nav, nav)
           |> assign(:current_resource, current)
           |> assign(:breadcrumbs, crumbs)}
      end)

    # Session revocation
    socket =
      Phoenix.LiveView.attach_hook(socket, :panel_session_revoke, :handle_info, fn
        :session_revoked, socket ->
          {:halt,
           socket
           |> Phoenix.LiveView.put_flash(:error, "Session revoked")
           |> Phoenix.LiveView.redirect(to: opts[:path] || "/")}

        _other, socket ->
          {:cont, socket}
      end)

    {:cont, socket}
  end

  defp boot_plugins(socket, plugins) do
    Enum.reduce(plugins, socket, fn {mod, _opts}, sock ->
      if function_exported?(mod, :boot, 1) do
        try do
          mod.boot(sock)
        rescue
          e ->
            require Logger
            Logger.warning("Plugin #{inspect(mod)}.boot/1 raised: #{Exception.message(e)}")
            sock
        end
      else
        sock
      end
    end)
  end

  defp attach_plugin_hooks(socket, hooks) do
    Enum.reduce(hooks, socket, fn {stage, fun}, sock ->
      hook_name = :"plugin_hook_#{:erlang.phash2(fun)}"
      Phoenix.LiveView.attach_hook(sock, hook_name, stage, fun)
    end)
  end

  defp current_path_from_socket(%{host_uri: %URI{path: path}}) when is_binary(path), do: path
  defp current_path_from_socket(_), do: "/"

  defp match_nav_item(nav_items, current_path) do
    Enum.find(nav_items, fn item ->
      String.starts_with?(current_path, item.path)
    end)
  end

  defp build_breadcrumbs(opts, nav_items, current_path) do
    base = [%{label: opts[:brand_name], path: opts[:path]}]

    case match_nav_item(nav_items, current_path) do
      nil ->
        base

      item ->
        resource_crumb = %{label: item.label, path: item.path}
        remaining = String.replace_prefix(current_path, item.path, "")
        action_crumb = action_breadcrumb(remaining)

        base ++ [resource_crumb | action_crumb]
    end
  end

  defp action_breadcrumb("/new"), do: [%{label: "New", path: nil}]

  defp action_breadcrumb("/" <> rest) do
    case String.split(rest, "/", parts: 2) do
      [_id, "edit"] -> [%{label: "Edit", path: nil}]
      [_id] -> [%{label: "Show", path: nil}]
      _ -> []
    end
  end

  defp action_breadcrumb(_), do: []

  defp maybe_subscribe_pubsub(socket, opts) do
    pubsub = opts[:pubsub]
    current_user = Map.get(socket.assigns, :current_user)

    if pubsub && current_user && Map.has_key?(current_user, :id) do
      Phoenix.PubSub.subscribe(pubsub, "user_sessions:#{current_user.id}")
    end

    socket
  end
end
```

- [ ] **Step 2: Run Hook tests**

Run: `mix test test/phoenix_filament/panel/hook_test.exs`
Expected: PASS (module still exports on_mount/4)

- [ ] **Step 3: Commit**

```
refactor(panel): Hook uses unified plugin accessors, boots plugins, attaches hooks
```

---

## Task 8: Refactor Router — Use :all_routes

**Files:**
- Modify: `lib/phoenix_filament/panel/router.ex`

- [ ] **Step 1: Update Router to use :all_routes**

Replace the route generation in `phoenix_filament_panel/2`:

```elixir
defmacro phoenix_filament_panel(path, panel_module) do
  quote bind_quoted: [path: path, panel_module: panel_module] do
    opts = panel_module.__panel__(:opts)
    all_routes = panel_module.__panel__(:all_routes)
    session_name = :"phoenix_filament_#{:erlang.phash2(panel_module)}"

    on_mount_hooks =
      case opts[:on_mount] do
        nil -> [{PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
        hook -> [hook, {PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
      end

    dashboard_module = opts[:dashboard] || PhoenixFilament.Panel.Dashboard

    scope path do
      live_session session_name,
        on_mount: on_mount_hooks,
        layout: {PhoenixFilament.Panel.Layout, :panel} do
        live "/", dashboard_module, :index

        for route <- all_routes do
          live route.path, route.live_view, route.live_action
        end
      end
    end
  end
end
```

- [ ] **Step 2: Run Router tests**

Run: `mix test test/phoenix_filament/panel/router_test.exs`
Expected: PASS

- [ ] **Step 3: Commit**

```
refactor(panel): Router generates routes from unified :all_routes
```

---

## Task 9: Refactor Dashboard — Use :all_widgets

**Files:**
- Modify: `lib/phoenix_filament/panel/dashboard.ex`

- [ ] **Step 1: Update Dashboard to use :all_widgets**

Change `panel_module.__panel__(:widgets)` to `panel_module.__panel__(:all_widgets)`:

```elixir
widgets =
  if panel_module do
    panel_module.__panel__(:all_widgets)
  else
    []
  end
```

- [ ] **Step 2: Run Dashboard tests**

Run: `mix test test/phoenix_filament/panel/dashboard_test.exs`
Expected: PASS

- [ ] **Step 3: Commit**

```
refactor(panel): Dashboard reads :all_widgets from unified plugin registry
```

---

## Task 10: Full Test Suite + Compile Safety

- [ ] **Step 1: Run full test suite**

Run: `mix test`
Expected: All tests PASS

- [ ] **Step 2: Compile with warnings as errors**

Run: `mix compile --warnings-as-errors`
Expected: Clean

- [ ] **Step 3: Verify module structure**

Run: `ls -R lib/phoenix_filament/plugin/ lib/phoenix_filament/plugins/`
Expected:
```
lib/phoenix_filament/plugin/:
resolver.ex

lib/phoenix_filament/plugins/:
resource_plugin.ex
widget_plugin.ex
```

And `lib/phoenix_filament/plugin.ex` exists.

- [ ] **Step 4: Fix any issues**

- [ ] **Step 5: Commit**

```
test(07): complete Phase 7 — Plugin Architecture implementation verified
```

---

*Plan: 07-plugin-architecture*
*Created: 2026-04-03*
*Tasks: 10*

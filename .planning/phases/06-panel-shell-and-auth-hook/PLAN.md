# Phase 6: Panel Shell and Auth Hook — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wrap PhoenixFilament Resources in an admin panel shell with sidebar navigation, breadcrumbs, responsive layout, BYO auth hook, flash toasts, and a dashboard with 4 widget types.

**Architecture:** Layered Delegation — thin Panel DSL module (`PhoenixFilament.Panel`) delegates to specialized modules: `Panel.Options`, `Panel.Router`, `Panel.Hook`, `Panel.Navigation`, `Panel.Layout`, `Panel.Dashboard`, and `Widget.*` behaviours. Follows the same pattern established by `PhoenixFilament.Resource` in Phase 5.

**Tech Stack:** Elixir, Phoenix LiveView 1.1, NimbleOptions, daisyUI 5, Tailwind CSS v4, Chart.js (vendor asset), Phoenix.PubSub

---

## File Structure

```
lib/phoenix_filament/
├── panel.ex                       # use PhoenixFilament.Panel — DSL macro, __panel__/1 accessors
└── panel/
    ├── options.ex                 # NimbleOptions schemas (panel opts, resource reg, widget reg)
    ├── dsl.ex                     # resources/1, widgets/1, resource/2, widget/2 macros
    ├── router.ex                  # phoenix_filament_panel/2 router macro
    ├── hook.ex                    # on_mount — inject panel assigns, PubSub subscribe
    ├── navigation.ex              # build_tree/2 — nav tree from resources + current path
    ├── layout.ex                  # Function components: panel/1, sidebar/1, topbar/1, breadcrumbs/1, flash_group/1
    ├── dashboard.ex               # Dashboard LiveView — widget grid
    └── widget/
        ├── stats_overview.ex      # StatsOverview behaviour + base LiveComponent
        ├── chart.ex               # Chart behaviour + base LiveComponent (Chart.js hook)
        ├── table.ex               # Table widget behaviour + base LiveComponent
        └── custom.ex              # Custom widget behaviour + base LiveComponent

test/phoenix_filament/panel/
├── options_test.exs               # NimbleOptions validation tests
├── panel_test.exs                 # Panel macro + __panel__/1 accessor tests
├── navigation_test.exs            # Nav tree building tests
├── hook_test.exs                  # on_mount assign injection tests
├── layout_test.exs                # Component render tests
├── router_test.exs                # Route generation tests
├── dashboard_test.exs             # Dashboard LiveView tests
└── widget/
    ├── stats_overview_test.exs    # StatsOverview widget tests
    ├── chart_test.exs             # Chart widget tests
    ├── table_test.exs             # Table widget tests
    └── custom_test.exs            # Custom widget tests

test/support/
├── panels/                        # Test panel modules
│   └── test_panel.ex
├── widgets/                       # Test widget modules
│   ├── test_stats.ex
│   ├── test_chart.ex
│   ├── test_table.ex
│   └── test_custom.ex
└── conn_case.ex                   # ConnCase for router tests (if not existing)

priv/static/vendor/
└── chart.min.js                   # Chart.js bundled vendor asset
```

---

## Task 1: Panel.Options — NimbleOptions Schema

**Files:**
- Create: `lib/phoenix_filament/panel/options.ex`
- Create: `test/phoenix_filament/panel/options_test.exs`

- [ ] **Step 1: Write failing tests for panel options validation**

```elixir
# test/phoenix_filament/panel/options_test.exs
defmodule PhoenixFilament.Panel.OptionsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Options

  describe "panel_schema/0" do
    test "validates valid panel options" do
      opts = [path: "/admin"]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.panel_schema())
      assert validated[:path] == "/admin"
      assert validated[:brand_name] == "Admin"
    end

    test "requires :path option" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               NimbleOptions.validate([], Options.panel_schema())
    end

    test "validates on_mount as {module, atom} tuple" do
      opts = [path: "/admin", on_mount: {MyAuth, :require_admin}]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.panel_schema())
      assert validated[:on_mount] == {MyAuth, :require_admin}
    end

    test "validates plug as module or {module, term} tuple" do
      assert {:ok, _} = NimbleOptions.validate([path: "/admin", plug: MyPlug], Options.panel_schema())
      assert {:ok, _} = NimbleOptions.validate([path: "/admin", plug: {MyPlug, []}], Options.panel_schema())
    end

    test "defaults brand_name to Admin" do
      {:ok, validated} = NimbleOptions.validate([path: "/admin"], Options.panel_schema())
      assert validated[:brand_name] == "Admin"
    end

    test "defaults theme_switcher to false" do
      {:ok, validated} = NimbleOptions.validate([path: "/admin"], Options.panel_schema())
      assert validated[:theme_switcher] == false
    end

    test "rejects unknown options" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               NimbleOptions.validate([path: "/admin", bogus: true], Options.panel_schema())
    end
  end

  describe "resource_schema/0" do
    test "validates resource registration with all options" do
      opts = [icon: "hero-document", nav_group: "Blog", slug: "articles"]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.resource_schema())
      assert validated[:icon] == "hero-document"
      assert validated[:nav_group] == "Blog"
      assert validated[:slug] == "articles"
    end

    test "all resource options are optional" do
      assert {:ok, _} = NimbleOptions.validate([], Options.resource_schema())
    end
  end

  describe "widget_schema/0" do
    test "validates widget registration options" do
      opts = [sort: 1, column_span: 6]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.widget_schema())
      assert validated[:sort] == 1
      assert validated[:column_span] == 6
    end

    test "defaults sort to 0 and column_span to 12" do
      {:ok, validated} = NimbleOptions.validate([], Options.widget_schema())
      assert validated[:sort] == 0
      assert validated[:column_span] == 12
    end

    test "accepts :full as column_span" do
      {:ok, validated} = NimbleOptions.validate([column_span: :full], Options.widget_schema())
      assert validated[:column_span] == :full
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/options_test.exs`
Expected: FAIL — `PhoenixFilament.Panel.Options` module not found

- [ ] **Step 3: Implement Panel.Options**

```elixir
# lib/phoenix_filament/panel/options.ex
defmodule PhoenixFilament.Panel.Options do
  @moduledoc false

  @panel_schema NimbleOptions.new!([
    path: [type: :string, required: true, doc: "URL path prefix (e.g., \"/admin\")"],
    on_mount: [
      type: {:tuple, [:atom, :atom]},
      doc: "LiveView on_mount hook for auth as {Module, :function}"
    ],
    plug: [
      type: {:or, [:atom, {:tuple, [:atom, :any]}]},
      doc: "Plug module or {module, opts} for HTTP auth"
    ],
    brand_name: [type: :string, default: "Admin", doc: "Display name in sidebar header"],
    logo: [type: :string, doc: "Logo URL for sidebar header"],
    theme: [type: :string, doc: "daisyUI theme name"],
    theme_switcher: [type: :boolean, default: false, doc: "Show light/dark toggle"],
    pubsub: [type: :atom, doc: "PubSub module for session revocation"],
    dashboard: [type: :atom, doc: "Custom LiveView to override default dashboard"]
  ])

  @resource_schema NimbleOptions.new!([
    icon: [type: :string, doc: "Heroicon name (e.g., \"hero-document-text\")"],
    nav_group: [type: :string, doc: "Sidebar group heading"],
    slug: [type: :string, doc: "URL slug override"]
  ])

  @widget_schema NimbleOptions.new!([
    sort: [type: :integer, default: 0, doc: "Widget rendering order (ascending)"],
    column_span: [
      type: {:or, [:integer, {:in, [:full]}]},
      default: 12,
      doc: "Grid column span (1-12 or :full)"
    ]
  ])

  def panel_schema, do: @panel_schema
  def resource_schema, do: @resource_schema
  def widget_schema, do: @widget_schema
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/options_test.exs`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```
test(panel): add NimbleOptions schema validation for Panel, resource, and widget options
```

---

## Task 2: Panel DSL Macros

**Files:**
- Create: `lib/phoenix_filament/panel/dsl.ex`

- [ ] **Step 1: Implement Panel DSL macros**

The DSL provides `resources/1`, `widgets/1`, `resource/2`, and `widget/2` macros that accumulate declarations into module attributes. These are tested via the Panel macro in Task 3.

```elixir
# lib/phoenix_filament/panel/dsl.ex
defmodule PhoenixFilament.Panel.DSL do
  @moduledoc false

  defmacro resources(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro widgets(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro resource(module, opts \\ []) do
    quote do
      validated_opts =
        NimbleOptions.validate!(unquote(opts), PhoenixFilament.Panel.Options.resource_schema())

      resource_mod =
        Macro.expand_literals(
          unquote(module),
          %{__CALLER__ | function: {:__panel__, 1}}
        )

      @_phx_filament_panel_resources {resource_mod, validated_opts}
    end
  end

  defmacro widget(module, opts \\ []) do
    quote do
      validated_opts =
        NimbleOptions.validate!(unquote(opts), PhoenixFilament.Panel.Options.widget_schema())

      widget_mod =
        Macro.expand_literals(
          unquote(module),
          %{__CALLER__ | function: {:__panel__, 1}}
        )

      @_phx_filament_panel_widgets {widget_mod, validated_opts}
    end
  end
end
```

- [ ] **Step 2: Commit**

```
feat(panel): add DSL macros for resources and widgets registration
```

---

## Task 3: Panel Macro — `use PhoenixFilament.Panel`

**Files:**
- Create: `lib/phoenix_filament/panel.ex`
- Create: `test/phoenix_filament/panel/panel_test.exs`
- Create: `test/support/panels/test_panel.ex`
- Create: `test/support/resources/test_post_resource.ex`

- [ ] **Step 1: Create test support modules**

```elixir
# test/support/resources/test_post_resource.ex
defmodule PhoenixFilament.Test.Resources.TestPostResource do
  use PhoenixFilament.Resource,
    schema: PhoenixFilament.Test.Schemas.Post,
    repo: PhoenixFilament.Test.FakeRepo,
    label: "Post",
    plural_label: "Posts",
    icon: "hero-document-text"
end
```

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
  end
end
```

- [ ] **Step 2: Write failing tests for Panel macro**

```elixir
# test/phoenix_filament/panel/panel_test.exs
defmodule PhoenixFilament.PanelTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Panels.TestPanel
  alias PhoenixFilament.Test.Resources.TestPostResource

  describe "__panel__/1 accessors" do
    test "returns validated options" do
      opts = TestPanel.__panel__(:opts)
      assert opts[:path] == "/admin"
      assert opts[:brand_name] == "Test Admin"
      assert opts[:theme] == "corporate"
      assert opts[:theme_switcher] == true
    end

    test "returns path" do
      assert TestPanel.__panel__(:path) == "/admin"
    end

    test "returns registered resources" do
      resources = TestPanel.__panel__(:resources)
      assert length(resources) == 1

      [resource] = resources
      assert resource.module == TestPostResource
      assert resource.icon == "hero-document-text"
      assert resource.nav_group == "Content"
    end

    test "resources have auto-derived labels from resource module" do
      [resource] = TestPanel.__panel__(:resources)
      assert resource.label == "Post"
      assert resource.plural_label == "Posts"
    end

    test "resources have auto-derived slugs from schema" do
      [resource] = TestPanel.__panel__(:resources)
      assert resource.slug == "posts"
    end

    test "returns registered widgets (empty)" do
      assert TestPanel.__panel__(:widgets) == []
    end

    test "raises on unknown key" do
      assert_raise ArgumentError, ~r/unknown panel key/, fn ->
        TestPanel.__panel__(:bogus)
      end
    end
  end

  describe "compile-time validation" do
    test "missing :path raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/required :path option/, fn ->
        defmodule BadPanel do
          use PhoenixFilament.Panel, brand_name: "Bad"
        end
      end
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/panel_test.exs`
Expected: FAIL — `PhoenixFilament.Panel` module not found

- [ ] **Step 4: Implement Panel macro**

```elixir
# lib/phoenix_filament/panel.ex
defmodule PhoenixFilament.Panel do
  @moduledoc """
  Declares an admin panel that wraps Resources in a shell with sidebar navigation,
  breadcrumbs, responsive layout, and a dashboard.

  ## Usage

      defmodule MyApp.Admin do
        use PhoenixFilament.Panel,
          path: "/admin",
          on_mount: {MyAuth, :require_admin},
          brand_name: "My Admin"

        resources do
          resource MyApp.Admin.PostResource,
            icon: "hero-document-text",
            nav_group: "Blog"
        end

        widgets do
          widget MyApp.Admin.StatsWidget, sort: 1
        end
      end

  ## Options

  #{NimbleOptions.docs(PhoenixFilament.Panel.Options.panel_schema())}
  """

  @callback __panel__(:opts) :: keyword()
  @callback __panel__(:path) :: String.t()
  @callback __panel__(:resources) :: [map()]
  @callback __panel__(:widgets) :: [map()]

  defmacro __using__(opts) do
    quote do
      @behaviour PhoenixFilament.Panel

      @_phx_filament_panel_opts NimbleOptions.validate!(
                                   unquote(opts),
                                   PhoenixFilament.Panel.Options.panel_schema()
                                 )

      if is_nil(@_phx_filament_panel_opts[:on_mount]) do
        IO.warn(
          "Panel #{inspect(__MODULE__)} has no on_mount configured. Add on_mount for production use."
        )
      end

      Module.register_attribute(__MODULE__, :_phx_filament_panel_resources, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_panel_widgets, accumulate: true)

      import PhoenixFilament.Panel.DSL

      @before_compile PhoenixFilament.Panel
    end
  end

  defmacro __before_compile__(env) do
    quote do
      @impl PhoenixFilament.Panel
      def __panel__(:opts), do: @_phx_filament_panel_opts

      @impl PhoenixFilament.Panel
      def __panel__(:path), do: @_phx_filament_panel_opts[:path]

      @impl PhoenixFilament.Panel
      def __panel__(:resources) do
        @_phx_filament_panel_resources
        |> Enum.reverse()
        |> Enum.map(fn {mod, opts} ->
          resource_opts = mod.__resource__(:opts)
          schema = mod.__resource__(:schema)
          schema_name = schema |> Module.split() |> List.last()

          %{
            module: mod,
            icon: opts[:icon],
            nav_group: opts[:nav_group],
            slug: opts[:slug] || schema_name |> Macro.underscore() |> Kernel.<>("s"),
            label: resource_opts[:label] || PhoenixFilament.Naming.humanize(
              schema_name |> Macro.underscore() |> String.to_atom()
            ),
            plural_label: resource_opts[:plural_label] || schema_name |> Macro.underscore() |> Kernel.<>("s") |> String.replace("_", " ") |> String.capitalize()
          }
        end)
      end

      @impl PhoenixFilament.Panel
      def __panel__(:widgets) do
        @_phx_filament_panel_widgets
        |> Enum.reverse()
        |> Enum.map(fn {mod, opts} ->
          %{
            module: mod,
            sort: opts[:sort] || 0,
            column_span: case opts[:column_span] do
              :full -> 12
              n -> n || 12
            end,
            id: mod |> Module.split() |> List.last() |> Macro.underscore()
          }
        end)
        |> Enum.sort_by(& &1.sort)
      end

      def __panel__(key) do
        raise ArgumentError,
              "unknown panel key #{inspect(key)}. Valid keys are: #{inspect([:opts, :path, :resources, :widgets])}"
      end
    end
  end

  @doc """
  Broadcasts session revocation for a user, disconnecting all their active panel sessions.
  """
  def revoke_sessions(pubsub, user_id) do
    Phoenix.PubSub.broadcast(pubsub, "user_sessions:#{user_id}", :session_revoked)
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/panel_test.exs`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```
feat(panel): add Panel macro with DSL for resources and widgets registration
```

---

## Task 4: Panel.Navigation — Nav Tree Builder

**Files:**
- Create: `lib/phoenix_filament/panel/navigation.ex`
- Create: `test/phoenix_filament/panel/navigation_test.exs`

- [ ] **Step 1: Write failing tests for navigation tree**

```elixir
# test/phoenix_filament/panel/navigation_test.exs
defmodule PhoenixFilament.Panel.NavigationTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Navigation

  @resources [
    %{module: PostResource, icon: "hero-document-text", nav_group: "Content",
      slug: "posts", label: "Post", plural_label: "Posts"},
    %{module: CategoryResource, icon: "hero-tag", nav_group: "Content",
      slug: "categories", label: "Category", plural_label: "Categories"},
    %{module: UserResource, icon: "hero-users", nav_group: "Management",
      slug: "users", label: "User", plural_label: "Users"},
    %{module: SettingsResource, icon: nil, nav_group: nil,
      slug: "settings", label: "Setting", plural_label: "Settings"}
  ]

  describe "build_tree/3" do
    test "groups resources by nav_group" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin/posts")

      assert length(tree.groups) == 2
      [content, management] = tree.groups
      assert content.label == "Content"
      assert length(content.items) == 2
      assert management.label == "Management"
      assert length(management.items) == 1
    end

    test "ungrouped resources appear separately" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin/settings")
      assert length(tree.ungrouped) == 1
      assert hd(tree.ungrouped).label == "Settings"
    end

    test "marks active resource by path prefix match" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin/posts")

      [content | _] = tree.groups
      [posts, categories] = content.items
      assert posts.active == true
      assert categories.active == false
    end

    test "marks active for nested paths (e.g., /admin/posts/123/edit)" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin/posts/123/edit")

      [content | _] = tree.groups
      [posts | _] = content.items
      assert posts.active == true
    end

    test "builds correct paths from panel_path + slug" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin")

      [content | _] = tree.groups
      [posts | _] = content.items
      assert posts.path == "/admin/posts"
    end

    test "preserves declaration order within groups" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin")
      [content | _] = tree.groups
      labels = Enum.map(content.items, & &1.label)
      assert labels == ["Posts", "Categories"]
    end

    test "icon fallback to first letter when nil" do
      tree = Navigation.build_tree(@resources, "/admin", "/admin")
      [settings] = tree.ungrouped
      assert settings.icon_fallback == "S"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/navigation_test.exs`
Expected: FAIL — `PhoenixFilament.Panel.Navigation` module not found

- [ ] **Step 3: Implement Navigation**

```elixir
# lib/phoenix_filament/panel/navigation.ex
defmodule PhoenixFilament.Panel.Navigation do
  @moduledoc false

  @doc """
  Builds a navigation tree from registered resources.

  Returns `%{groups: [group], ungrouped: [item]}` where each group has
  `:label` and `:items`, and each item has `:label`, `:path`, `:icon`,
  `:icon_fallback`, and `:active`.
  """
  def build_tree(resources, panel_path, current_path) do
    {grouped, ungrouped} =
      resources
      |> Enum.map(fn r -> build_item(r, panel_path, current_path) end)
      |> Enum.split_with(fn item -> item.nav_group != nil end)

    groups =
      grouped
      |> Enum.chunk_by(& &1.nav_group)
      |> Enum.map(fn items ->
        %{label: hd(items).nav_group, items: items}
      end)

    %{groups: groups, ungrouped: ungrouped}
  end

  defp build_item(resource, panel_path, current_path) do
    path = "#{panel_path}/#{resource.slug}"
    label = resource.plural_label

    %{
      label: label,
      path: path,
      icon: resource.icon,
      icon_fallback: String.first(label),
      nav_group: resource.nav_group,
      active: String.starts_with?(current_path, path),
      module: resource.module
    }
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/navigation_test.exs`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```
feat(panel): add Navigation module for building sidebar nav tree
```

---

## Task 5: Panel.Hook — on_mount Callback

**Files:**
- Create: `lib/phoenix_filament/panel/hook.ex`
- Create: `test/phoenix_filament/panel/hook_test.exs`

- [ ] **Step 1: Write failing tests for Panel.Hook**

```elixir
# test/phoenix_filament/panel/hook_test.exs
defmodule PhoenixFilament.Panel.HookTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Hook
  alias PhoenixFilament.Test.Panels.TestPanel

  defp build_socket(path \\ "/admin/posts") do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        live_action: :index
      },
      private: %{
        connect_params: %{},
        lifecycle: %Phoenix.LiveView.Lifecycle{handle_params: [], handle_info: [], after_render: [], handle_event: []},
      },
      router: TestRouter,
      view: TestView
    }
    |> Phoenix.Component.assign(:current_user, nil)
    |> Map.put(:host_uri, %URI{path: path})
  end

  describe "on_mount/4" do
    test "injects panel assigns" do
      socket = build_socket()
      {:cont, socket} = Hook.on_mount({:panel, TestPanel}, %{}, %{}, socket)

      assert socket.assigns.panel_module == TestPanel
      assert socket.assigns.panel_brand == "Test Admin"
      assert socket.assigns.panel_theme == "corporate"
      assert socket.assigns.panel_theme_switcher == true
      assert socket.assigns.panel_path == "/admin"
    end

    test "builds nav tree from panel resources" do
      socket = build_socket()
      {:cont, socket} = Hook.on_mount({:panel, TestPanel}, %{}, %{}, socket)

      assert %{groups: _, ungrouped: _} = socket.assigns.panel_nav
    end

    test "sets breadcrumbs" do
      socket = build_socket()
      {:cont, socket} = Hook.on_mount({:panel, TestPanel}, %{}, %{}, socket)

      assert is_list(socket.assigns.breadcrumbs)
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/hook_test.exs`
Expected: FAIL — `PhoenixFilament.Panel.Hook` module not found

- [ ] **Step 3: Implement Panel.Hook**

```elixir
# lib/phoenix_filament/panel/hook.ex
defmodule PhoenixFilament.Panel.Hook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  alias PhoenixFilament.Panel.Navigation

  def on_mount({:panel, panel_module}, params, _session, socket) do
    opts = panel_module.__panel__(:opts)
    resources = panel_module.__panel__(:resources)
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
      |> assign(:panel_nav, Navigation.build_tree(resources, panel_path, current_path))
      |> assign(:current_resource, match_resource(resources, panel_path, current_path))
      |> assign(:breadcrumbs, build_breadcrumbs(opts, resources, panel_path, current_path))

    socket = maybe_subscribe_pubsub(socket, opts)

    socket =
      Phoenix.LiveView.attach_hook(socket, :panel_nav_update, :handle_params, fn
        _params, uri, socket ->
          path = URI.parse(uri).path
          nav = Navigation.build_tree(resources, panel_path, path)
          crumbs = build_breadcrumbs(opts, resources, panel_path, path)
          resource = match_resource(resources, panel_path, path)

          {:cont,
           socket
           |> assign(:panel_nav, nav)
           |> assign(:current_resource, resource)
           |> assign(:breadcrumbs, crumbs)}
      end)

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

  defp current_path_from_socket(%{host_uri: %URI{path: path}}) when is_binary(path), do: path
  defp current_path_from_socket(_), do: "/"

  defp match_resource(resources, panel_path, current_path) do
    Enum.find(resources, fn r ->
      String.starts_with?(current_path, "#{panel_path}/#{r.slug}")
    end)
  end

  defp build_breadcrumbs(opts, resources, panel_path, current_path) do
    base = [%{label: opts[:brand_name], path: panel_path}]

    case match_resource(resources, panel_path, current_path) do
      nil ->
        base

      resource ->
        base ++ [%{label: resource.plural_label, path: "#{panel_path}/#{resource.slug}"}]
    end
  end

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

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/hook_test.exs`
Expected: Tests pass (some may need socket struct adjustments — fix as needed)

- [ ] **Step 5: Commit**

```
feat(panel): add Hook on_mount for panel assign injection and PubSub
```

---

## Task 6: Panel.Layout — Shell Components

**Files:**
- Create: `lib/phoenix_filament/panel/layout.ex`
- Create: `test/phoenix_filament/panel/layout_test.exs`

- [ ] **Step 1: Write failing tests for layout components**

```elixir
# test/phoenix_filament/panel/layout_test.exs
defmodule PhoenixFilament.Panel.LayoutTest do
  use PhoenixFilament.ComponentCase

  alias PhoenixFilament.Panel.Layout

  @nav %{
    groups: [
      %{label: "Content", items: [
        %{label: "Posts", path: "/admin/posts", icon: "hero-document-text", icon_fallback: "P", active: true},
        %{label: "Categories", path: "/admin/categories", icon: "hero-tag", icon_fallback: "C", active: false}
      ]}
    ],
    ungrouped: []
  }

  describe "sidebar/1" do
    test "renders nav groups with headings" do
      assigns = %{nav: @nav, brand: "Admin", logo: nil, path: "/admin", theme_switcher: false}
      html = rendered_to_string(~H"<Layout.sidebar {assigns} />")

      assert html =~ "Content"
      assert html =~ "Posts"
      assert html =~ "Categories"
    end

    test "renders active state on current resource" do
      assigns = %{nav: @nav, brand: "Admin", logo: nil, path: "/admin", theme_switcher: false}
      html = rendered_to_string(~H"<Layout.sidebar {assigns} />")

      assert html =~ "active"
    end

    test "renders brand name" do
      assigns = %{nav: @nav, brand: "My Admin", logo: nil, path: "/admin", theme_switcher: false}
      html = rendered_to_string(~H"<Layout.sidebar {assigns} />")

      assert html =~ "My Admin"
    end
  end

  describe "breadcrumbs/1" do
    test "renders breadcrumb trail" do
      assigns = %{items: [
        %{label: "Admin", path: "/admin"},
        %{label: "Posts", path: "/admin/posts"}
      ]}
      html = rendered_to_string(~H"<Layout.breadcrumbs {assigns} />")

      assert html =~ "Admin"
      assert html =~ "Posts"
    end
  end

  describe "flash_group/1" do
    test "renders success flash as toast" do
      assigns = %{flash: %{"info" => "Record created"}}
      html = rendered_to_string(~H"<Layout.flash_group {assigns} />")

      assert html =~ "Record created"
      assert html =~ "alert"
    end

    test "renders error flash" do
      assigns = %{flash: %{"error" => "Something failed"}}
      html = rendered_to_string(~H"<Layout.flash_group {assigns} />")

      assert html =~ "Something failed"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/layout_test.exs`
Expected: FAIL — `PhoenixFilament.Panel.Layout` module not found

- [ ] **Step 3: Implement Panel.Layout**

```elixir
# lib/phoenix_filament/panel/layout.ex
defmodule PhoenixFilament.Panel.Layout do
  @moduledoc false
  use Phoenix.Component

  @doc """
  Root panel layout — renders the daisyUI drawer shell.
  Used as the `layout` in `live_session`.
  """
  def panel(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open" data-theme={assigns[:panel_theme]}>
      <input id="panel-sidebar" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col min-h-screen">
        <.topbar brand={assigns[:panel_brand]} />
        <.breadcrumbs items={assigns[:breadcrumbs] || []} />
        <main class="flex-1 p-6">
          {@inner_content}
        </main>
        <.flash_group flash={assigns[:flash] || %{}} />
      </div>
      <div class="drawer-side z-40">
        <label for="panel-sidebar" aria-label="close sidebar" class="drawer-overlay"></label>
        <.sidebar
          nav={assigns[:panel_nav] || %{groups: [], ungrouped: []}}
          brand={assigns[:panel_brand] || "Admin"}
          logo={assigns[:panel_logo]}
          path={assigns[:panel_path] || "/"}
          theme_switcher={assigns[:panel_theme_switcher] || false}
        />
      </div>
    </div>
    """
  end

  attr :nav, :map, required: true
  attr :brand, :string, required: true
  attr :logo, :string, default: nil
  attr :path, :string, required: true
  attr :theme_switcher, :boolean, default: false

  def sidebar(assigns) do
    ~H"""
    <aside class="menu bg-base-200 text-base-content w-64 min-h-full p-4">
      <div class="flex items-center gap-3 px-2 mb-6">
        <img :if={@logo} src={@logo} alt={@brand} class="w-8 h-8 rounded" />
        <div
          :if={!@logo}
          class="w-8 h-8 bg-primary rounded flex items-center justify-center text-primary-content font-bold text-sm"
        >
          {String.first(@brand)}
        </div>
        <span class="font-semibold text-lg">{@brand}</span>
      </div>

      <ul class="menu">
        <li>
          <a href={@path} class="flex items-center gap-2">
            <span class="text-base">📊</span>
            Dashboard
          </a>
        </li>
      </ul>

      <div :for={group <- @nav.groups} class="mt-4">
        <li class="menu-title text-xs uppercase tracking-wider">{group.label}</li>
        <ul class="menu">
          <li :for={item <- group.items}>
            <a href={item.path} class={["flex items-center gap-2", item.active && "active"]}>
              <span :if={item.icon} class="hero-icon">{item.icon}</span>
              <span
                :if={!item.icon}
                class="w-5 h-5 bg-base-300 rounded flex items-center justify-center text-xs"
              >
                {item.icon_fallback}
              </span>
              {item.label}
            </a>
          </li>
        </ul>
      </div>

      <ul :if={@nav.ungrouped != []} class="menu mt-4">
        <li :for={item <- @nav.ungrouped}>
          <a href={item.path} class={["flex items-center gap-2", item.active && "active"]}>
            <span :if={item.icon}>{item.icon}</span>
            <span
              :if={!item.icon}
              class="w-5 h-5 bg-base-300 rounded flex items-center justify-center text-xs"
            >
              {item.icon_fallback}
            </span>
            {item.label}
          </a>
        </li>
      </ul>

      <div :if={@theme_switcher} class="mt-auto pt-4 border-t border-base-300">
        <label class="swap swap-rotate">
          <input type="checkbox" class="theme-controller" value="dark" />
          <span class="swap-on">🌙</span>
          <span class="swap-off">☀️</span>
        </label>
      </div>
    </aside>
    """
  end

  attr :brand, :string, default: "Admin"

  def topbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 border-b border-base-300 lg:hidden">
      <div class="flex-none">
        <label for="panel-sidebar" class="btn btn-square btn-ghost">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </label>
      </div>
      <div class="flex-1">
        <span class="font-semibold">{@brand}</span>
      </div>
    </div>
    """
  end

  attr :items, :list, required: true

  def breadcrumbs(assigns) do
    ~H"""
    <div :if={@items != []} class="breadcrumbs text-sm px-6 pt-4">
      <ul>
        <li :for={item <- @items}>
          <a href={item.path}>{item.label}</a>
        </li>
      </ul>
    </div>
    """
  end

  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div class="toast toast-end z-50">
      <div
        :if={msg = Phoenix.Flash.get(@flash, :info)}
        class="alert alert-success"
        phx-mounted={Phoenix.LiveView.JS.transition("opacity-0", time: 5000)}
      >
        <span>{msg}</span>
      </div>
      <div
        :if={msg = Phoenix.Flash.get(@flash, :error)}
        class="alert alert-error"
        phx-mounted={Phoenix.LiveView.JS.transition("opacity-0", time: 5000)}
      >
        <span>{msg}</span>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/layout_test.exs`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```
feat(panel): add Layout components — sidebar, topbar, breadcrumbs, flash toasts
```

---

## Task 7: Panel.Router — Route Macro

**Files:**
- Create: `lib/phoenix_filament/panel/router.ex`
- Create: `test/phoenix_filament/panel/router_test.exs`

- [ ] **Step 1: Write failing tests for router macro**

```elixir
# test/phoenix_filament/panel/router_test.exs
defmodule PhoenixFilament.Panel.RouterTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Panels.TestPanel

  describe "phoenix_filament_panel/2 route generation" do
    test "panel module has resources registered" do
      resources = TestPanel.__panel__(:resources)
      assert length(resources) >= 1
    end

    test "resources have correct slug for route generation" do
      [resource | _] = TestPanel.__panel__(:resources)
      assert is_binary(resource.slug)
    end
  end
end
```

Note: Full router integration tests require a Phoenix endpoint and are complex to set up in a library. The router macro will be validated more thoroughly in the integration test (Task 12). Here we focus on the macro module compilation.

- [ ] **Step 2: Implement Panel.Router**

```elixir
# lib/phoenix_filament/panel/router.ex
defmodule PhoenixFilament.Panel.Router do
  @moduledoc """
  Provides the `phoenix_filament_panel/2` router macro.

  ## Usage

  In your router:

      import PhoenixFilament.Panel.Router

      scope "/" do
        pipe_through [:browser]
        phoenix_filament_panel "/admin", MyApp.Admin
      end
  """

  defmacro phoenix_filament_panel(path, panel_module) do
    quote bind_quoted: [path: path, panel_module: panel_module] do
      opts = panel_module.__panel__(:opts)
      resources = panel_module.__panel__(:resources)
      session_name = :"phoenix_filament_#{:erlang.phash2(panel_module)}"

      on_mount_hooks =
        case opts[:on_mount] do
          nil -> [{PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
          hook -> [hook, {PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
        end

      scope path do
        if plug = opts[:plug] do
          pipe_through [plug]
        end

        live_session session_name,
          on_mount: on_mount_hooks,
          layout: {PhoenixFilament.Panel.Layout, :panel} do
          live "/", PhoenixFilament.Panel.Dashboard, :index

          for resource <- resources do
            slug = resource.slug
            mod = resource.module

            live "/#{slug}", mod, :index
            live "/#{slug}/new", mod, :new
            live "/#{slug}/:id", mod, :show
            live "/#{slug}/:id/edit", mod, :edit
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/router_test.exs`
Expected: PASS

- [ ] **Step 4: Commit**

```
feat(panel): add Router macro for auto-generating panel live routes
```

---

## Task 8: Widget.StatsOverview

**Files:**
- Create: `lib/phoenix_filament/panel/widget/stats_overview.ex`
- Create: `test/phoenix_filament/panel/widget/stats_overview_test.exs`
- Create: `test/support/widgets/test_stats.ex`

- [ ] **Step 1: Create test widget module**

```elixir
# test/support/widgets/test_stats.ex
defmodule PhoenixFilament.Test.Widgets.TestStats do
  use PhoenixFilament.Widget.StatsOverview

  @impl true
  def stats(_assigns) do
    [
      stat("Total Posts", 42, icon: "hero-document-text", color: :success, description: "5 new today"),
      stat("Users", 128, color: :info)
    ]
  end
end
```

- [ ] **Step 2: Write failing tests**

```elixir
# test/phoenix_filament/panel/widget/stats_overview_test.exs
defmodule PhoenixFilament.Widget.StatsOverviewTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestStats

  describe "stats/1 callback" do
    test "returns list of stat structs" do
      stats = TestStats.stats(%{})
      assert length(stats) == 2

      [first, second] = stats
      assert first.label == "Total Posts"
      assert first.value == 42
      assert first.icon == "hero-document-text"
      assert first.color == :success
      assert first.description == "5 new today"
      assert second.label == "Users"
      assert second.value == 128
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/widget/stats_overview_test.exs`
Expected: FAIL — `PhoenixFilament.Widget.StatsOverview` not found

- [ ] **Step 4: Implement Widget.StatsOverview**

```elixir
# lib/phoenix_filament/panel/widget/stats_overview.ex
defmodule PhoenixFilament.Widget.StatsOverview do
  @moduledoc """
  A widget that displays statistics as cards.

  ## Usage

      defmodule MyApp.Admin.StatsWidget do
        use PhoenixFilament.Widget.StatsOverview

        @impl true
        def stats(_assigns) do
          [
            stat("Posts", Repo.aggregate(Post, :count),
              icon: "hero-document-text",
              color: :success,
              description: "12 new today")
          ]
        end
      end
  """

  @callback stats(assigns :: map()) :: [stat()]

  @type stat :: %{
          label: String.t(),
          value: term(),
          icon: String.t() | nil,
          description: String.t() | nil,
          description_icon: String.t() | nil,
          color: :success | :error | :warning | :info | nil,
          chart: [number()] | nil
        }

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.StatsOverview
      import PhoenixFilament.Widget.StatsOverview, only: [stat: 2, stat: 3]

      @polling_interval nil

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)
        stats = __MODULE__.stats(socket.assigns)
        socket = Phoenix.Component.assign(socket, :stats, stats)

        if @polling_interval do
          Process.send_after(self(), {:widget_refresh, __MODULE__}, @polling_interval)
        end

        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.StatsOverview.__render__(assigns)
      end

      defoverridable render: 1
    end
  end

  def stat(label, value, opts \\ []) do
    %{
      label: label,
      value: value,
      icon: opts[:icon],
      description: opts[:description],
      description_icon: opts[:description_icon],
      color: opts[:color],
      chart: opts[:chart]
    }
  end

  @doc false
  def __render__(assigns) do
    assigns = Phoenix.Component.assign(assigns, :stats, Map.get(assigns, :stats, []))

    Phoenix.LiveView.TagEngine.component(
      &stats_overview_template/1,
      assigns,
      {__ENV__.file, __ENV__.line}
    )
  end

  use Phoenix.Component

  defp stats_overview_template(assigns) do
    ~H"""
    <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
      <div :for={stat <- @stats} class="stat">
        <div :if={stat.icon} class="stat-figure text-primary">
          <span>{stat.icon}</span>
        </div>
        <div class="stat-title">{stat.label}</div>
        <div class={["stat-value", stat_color_class(stat.color)]}>{stat.value}</div>
        <div :if={stat.description} class="stat-desc">{stat.description}</div>
      </div>
    </div>
    """
  end

  defp stat_color_class(:success), do: "text-success"
  defp stat_color_class(:error), do: "text-error"
  defp stat_color_class(:warning), do: "text-warning"
  defp stat_color_class(:info), do: "text-info"
  defp stat_color_class(_), do: ""
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/widget/stats_overview_test.exs`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```
feat(widget): add StatsOverview widget with stat cards and polling support
```

---

## Task 9: Widget.Chart

**Files:**
- Create: `lib/phoenix_filament/panel/widget/chart.ex`
- Create: `test/phoenix_filament/panel/widget/chart_test.exs`
- Create: `test/support/widgets/test_chart.ex`

- [ ] **Step 1: Create test chart widget**

```elixir
# test/support/widgets/test_chart.ex
defmodule PhoenixFilament.Test.Widgets.TestChart do
  use PhoenixFilament.Widget.Chart

  @impl true
  def chart_type, do: :bar

  @impl true
  def chart_data(_assigns) do
    %{
      labels: ["Jan", "Feb", "Mar"],
      datasets: [%{label: "Posts", data: [10, 20, 15]}]
    }
  end
end
```

- [ ] **Step 2: Write failing tests**

```elixir
# test/phoenix_filament/panel/widget/chart_test.exs
defmodule PhoenixFilament.Widget.ChartTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestChart

  describe "chart callbacks" do
    test "chart_type returns atom" do
      assert TestChart.chart_type() == :bar
    end

    test "chart_data returns labels and datasets" do
      data = TestChart.chart_data(%{})
      assert data.labels == ["Jan", "Feb", "Mar"]
      assert length(data.datasets) == 1
      assert hd(data.datasets).data == [10, 20, 15]
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/widget/chart_test.exs`
Expected: FAIL — `PhoenixFilament.Widget.Chart` not found

- [ ] **Step 4: Implement Widget.Chart**

```elixir
# lib/phoenix_filament/panel/widget/chart.ex
defmodule PhoenixFilament.Widget.Chart do
  @moduledoc """
  A widget that displays a Chart.js chart.

  ## Usage

      defmodule MyApp.Admin.RevenueChart do
        use PhoenixFilament.Widget.Chart

        @impl true
        def chart_type, do: :line

        @impl true
        def chart_data(_assigns) do
          %{labels: ["Jan", "Feb"], datasets: [%{label: "Revenue", data: [100, 200]}]}
        end
      end
  """

  @callback chart_type() :: :line | :bar | :pie | :doughnut
  @callback chart_data(assigns :: map()) :: %{labels: [String.t()], datasets: [map()]}
  @optional_callbacks [chart_options: 0]
  @callback chart_options() :: map()

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Chart

      @polling_interval nil

      def chart_options, do: %{}
      defoverridable chart_options: 0

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)
        data = __MODULE__.chart_data(socket.assigns)
        chart_type = __MODULE__.chart_type()
        chart_options = __MODULE__.chart_options()

        chart_config = %{
          type: chart_type,
          data: data,
          options: chart_options
        }

        socket = Phoenix.Component.assign(socket, :chart_config, Jason.encode!(chart_config))

        if @polling_interval do
          Process.send_after(self(), {:widget_refresh, __MODULE__}, @polling_interval)
        end

        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.Chart.__render__(assigns)
      end

      defoverridable render: 1
    end
  end

  use Phoenix.Component

  @doc false
  def __render__(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <canvas
          id={assigns[:id] || "chart-#{System.unique_integer([:positive])}"}
          phx-hook="PhxFilamentChart"
          data-chart={@chart_config}
          phx-update="ignore"
          style="max-height: 300px;"
        >
        </canvas>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/widget/chart_test.exs`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```
feat(widget): add Chart widget with Chart.js integration via JS hook
```

---

## Task 10: Widget.Table

**Files:**
- Create: `lib/phoenix_filament/panel/widget/table.ex`
- Create: `test/phoenix_filament/panel/widget/table_test.exs`
- Create: `test/support/widgets/test_table.ex`

- [ ] **Step 1: Create test table widget**

```elixir
# test/support/widgets/test_table.ex
defmodule PhoenixFilament.Test.Widgets.TestTable do
  use PhoenixFilament.Widget.Table

  @impl true
  def heading, do: "Recent Posts"

  @impl true
  def columns do
    [
      %PhoenixFilament.Column{name: :title, label: "Title"},
      %PhoenixFilament.Column{name: :published, label: "Published"}
    ]
  end
end
```

- [ ] **Step 2: Write failing tests**

```elixir
# test/phoenix_filament/panel/widget/table_test.exs
defmodule PhoenixFilament.Widget.TableTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestTable

  describe "table widget callbacks" do
    test "heading returns string" do
      assert TestTable.heading() == "Recent Posts"
    end

    test "columns returns list of Column structs" do
      columns = TestTable.columns()
      assert length(columns) == 2
      assert hd(columns).name == :title
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/widget/table_test.exs`
Expected: FAIL

- [ ] **Step 4: Implement Widget.Table**

```elixir
# lib/phoenix_filament/panel/widget/table.ex
defmodule PhoenixFilament.Widget.Table do
  @moduledoc """
  A widget that displays a simple read-only table on the dashboard.

  ## Usage

      defmodule MyApp.Admin.RecentPosts do
        use PhoenixFilament.Widget.Table

        @impl true
        def heading, do: "Recent Posts"

        @impl true
        def columns do
          [
            %PhoenixFilament.Column{name: :title, label: "Title"},
            %PhoenixFilament.Column{name: :status, label: "Status"}
          ]
        end
      end
  """

  @callback columns() :: [PhoenixFilament.Column.t()]
  @callback heading() :: String.t()
  @optional_callbacks [heading: 0]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Table

      @polling_interval nil

      def heading, do: "Table"
      defoverridable heading: 0

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)
        socket = Phoenix.Component.assign(socket, :widget_heading, __MODULE__.heading())
        socket = Phoenix.Component.assign(socket, :widget_columns, __MODULE__.columns())

        if @polling_interval do
          Process.send_after(self(), {:widget_refresh, __MODULE__}, @polling_interval)
        end

        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.Table.__render__(assigns)
      end

      defoverridable render: 1
    end
  end

  use Phoenix.Component

  @doc false
  def __render__(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h3 class="card-title text-sm">{@widget_heading}</h3>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th :for={col <- @widget_columns}>{col.label || PhoenixFilament.Naming.humanize(col.name)}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- Map.get(assigns, :rows, [])}>
                <td :for={col <- @widget_columns}>{Map.get(row, col.name)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/widget/table_test.exs`
Expected: PASS

- [ ] **Step 6: Commit**

```
feat(widget): add Table widget for dashboard read-only tables
```

---

## Task 11: Widget.Custom

**Files:**
- Create: `lib/phoenix_filament/panel/widget/custom.ex`
- Create: `test/phoenix_filament/panel/widget/custom_test.exs`
- Create: `test/support/widgets/test_custom.ex`

- [ ] **Step 1: Create test custom widget**

```elixir
# test/support/widgets/test_custom.ex
defmodule PhoenixFilament.Test.Widgets.TestCustom do
  use PhoenixFilament.Widget.Custom

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title">Welcome!</h2>
        <p>Custom widget content</p>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 2: Write failing tests**

```elixir
# test/phoenix_filament/panel/widget/custom_test.exs
defmodule PhoenixFilament.Widget.CustomTest do
  use ExUnit.Case, async: true

  test "custom widget module compiles and has render/1" do
    assert function_exported?(PhoenixFilament.Test.Widgets.TestCustom, :render, 1)
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/widget/custom_test.exs`
Expected: FAIL

- [ ] **Step 4: Implement Widget.Custom**

```elixir
# lib/phoenix_filament/panel/widget/custom.ex
defmodule PhoenixFilament.Widget.Custom do
  @moduledoc """
  A free-form widget for custom content on the dashboard.

  ## Usage

      defmodule MyApp.Admin.WelcomeWidget do
        use PhoenixFilament.Widget.Custom

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2>Welcome!</h2>
            </div>
          </div>
          \"\"\"
        end
      end
  """

  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Custom

      @polling_interval nil

      def update(assigns, socket) do
        {:ok, Phoenix.Component.assign(socket, assigns)}
      end

      defoverridable update: 2
    end
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/widget/custom_test.exs`
Expected: PASS

- [ ] **Step 6: Commit**

```
feat(widget): add Custom widget for free-form dashboard content
```

---

## Task 12: Panel.Dashboard — Dashboard LiveView

**Files:**
- Create: `lib/phoenix_filament/panel/dashboard.ex`
- Create: `test/phoenix_filament/panel/dashboard_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/panel/dashboard_test.exs
defmodule PhoenixFilament.Panel.DashboardTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Dashboard

  test "module compiles and is a LiveView" do
    assert function_exported?(Dashboard, :mount, 3)
    assert function_exported?(Dashboard, :render, 1)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/panel/dashboard_test.exs`
Expected: FAIL

- [ ] **Step 3: Implement Panel.Dashboard**

```elixir
# lib/phoenix_filament/panel/dashboard.ex
defmodule PhoenixFilament.Panel.Dashboard do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    panel_module = socket.assigns[:panel_module]

    widgets =
      if panel_module do
        panel_module.__panel__(:widgets)
      else
        []
      end

    custom_dashboard =
      if panel_module do
        panel_module.__panel__(:opts)[:dashboard]
      else
        nil
      end

    socket =
      socket
      |> assign(:widgets, widgets)
      |> assign(:custom_dashboard, custom_dashboard)
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-6">Dashboard</h1>

      <div :if={@custom_dashboard} class="w-full">
        {live_render(@socket, @custom_dashboard, id: "custom-dashboard")}
      </div>

      <div :if={!@custom_dashboard && @widgets != []} class="grid grid-cols-12 gap-4">
        <div :for={w <- @widgets} class={"col-span-#{w.column_span}"}>
          <.live_component module={w.module} id={"widget-#{w.id}"} />
        </div>
      </div>

      <div :if={!@custom_dashboard && @widgets == []} class="text-center py-12 text-base-content/50">
        <p class="text-lg">No widgets configured</p>
        <p class="text-sm mt-2">Add widgets to your panel module to populate this dashboard.</p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:widget_refresh, widget_module}, socket) do
    send_update(widget_module, id: "widget-#{widget_module |> Module.split() |> List.last() |> Macro.underscore()}")
    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/panel/dashboard_test.exs`
Expected: PASS

- [ ] **Step 5: Commit**

```
feat(panel): add Dashboard LiveView with widget grid rendering
```

---

## Task 13: Chart.js Vendor Asset

**Files:**
- Create: `priv/static/vendor/chart.min.js`

- [ ] **Step 1: Download Chart.js minified bundle**

Run: `mkdir -p priv/static/vendor && curl -sL https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js -o priv/static/vendor/chart.min.js`

Verify: `ls -la priv/static/vendor/chart.min.js` — file should be ~200KB

- [ ] **Step 2: Commit**

```
chore(vendor): bundle Chart.js 4.4.7 as vendor asset
```

---

## Task 14: Full Test Suite Pass

- [ ] **Step 1: Run the complete test suite**

Run: `mix test`
Expected: All tests PASS with zero failures

- [ ] **Step 2: Fix any failures**

Address any compilation errors or test failures from module interactions.

- [ ] **Step 3: Run mix compile with warnings as errors**

Run: `mix compile --warnings-as-errors`
Expected: Compiles cleanly

- [ ] **Step 4: Commit any fixes**

```
fix(panel): resolve test suite integration issues
```

---

## Task 15: Update Test Panel with Widgets

**Files:**
- Modify: `test/support/panels/test_panel.ex`

- [ ] **Step 1: Update TestPanel to include widgets for integration testing**

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
end
```

- [ ] **Step 2: Write integration test for panel with widgets**

```elixir
# Add to test/phoenix_filament/panel/panel_test.exs
describe "panel with widgets" do
  test "returns sorted widgets with resolved column_span" do
    widgets = PhoenixFilament.Test.Panels.TestPanel.__panel__(:widgets)
    assert length(widgets) == 2

    [first, second] = widgets
    assert first.module == PhoenixFilament.Test.Widgets.TestStats
    assert first.sort == 1
    assert first.column_span == 12  # :full resolved to 12
    assert second.module == PhoenixFilament.Test.Widgets.TestCustom
    assert second.sort == 2
    assert second.column_span == 6
  end
end
```

- [ ] **Step 3: Run tests**

Run: `mix test test/phoenix_filament/panel/panel_test.exs`
Expected: All PASS

- [ ] **Step 4: Commit**

```
test(panel): add integration tests for panel with widgets
```

---

## Task 16: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `mix test`
Expected: All tests PASS

- [ ] **Step 2: Run compile check**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 3: Verify module structure**

Run: `ls -R lib/phoenix_filament/panel/`
Expected: All planned files exist:
```
lib/phoenix_filament/panel/
├── dashboard.ex
├── dsl.ex
├── hook.ex
├── layout.ex
├── navigation.ex
├── options.ex
├── router.ex
└── widget/
    ├── chart.ex
    ├── custom.ex
    ├── stats_overview.ex
    └── table.ex
```

- [ ] **Step 4: Final commit**

```
docs(06): complete Phase 6 — Panel Shell and Auth Hook implementation
```

---

*Plan: 06-panel-shell-and-auth-hook*
*Created: 2026-04-02*
*Tasks: 16*

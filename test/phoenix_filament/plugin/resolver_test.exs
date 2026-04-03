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
    def register(_panel, _opts) do
      %{
        nav_items: [nav_item("Full", path: "/full")],
        routes: [route("/full", FullLive, :index)],
        widgets: [%{module: FullWidget, sort: 1, column_span: 6}],
        hooks: [{:handle_info, &__MODULE__.on_info/2}]
      }
    end
    def on_info(_msg, socket), do: {:cont, socket}
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

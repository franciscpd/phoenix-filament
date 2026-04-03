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
    test "module has documentation with Experimental warning" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(Plugin)
      assert moduledoc =~ "Experimental"
    end
  end
end

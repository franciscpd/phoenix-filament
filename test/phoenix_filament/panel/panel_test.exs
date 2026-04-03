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

    test "returns sorted widgets with resolved column_span" do
      widgets = TestPanel.__panel__(:widgets)
      assert length(widgets) == 2

      [first, second] = widgets
      assert first.module == PhoenixFilament.Test.Widgets.TestStats
      assert first.sort == 1
      assert first.column_span == 12
      assert second.module == PhoenixFilament.Test.Widgets.TestCustom
      assert second.sort == 2
      assert second.column_span == 6
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

  describe "plugin resolution" do
    test "__panel__(:all_nav_items) includes resources + community plugin nav" do
      nav_items = TestPanel.__panel__(:all_nav_items)
      assert Enum.any?(nav_items, &(&1.label == "Posts"))
      assert Enum.any?(nav_items, &(&1.label == "Analytics"))
    end

    test "__panel__(:all_routes) includes resource CRUD routes + plugin routes" do
      routes = TestPanel.__panel__(:all_routes)
      post_routes = Enum.filter(routes, &String.contains?(&1.path, "posts"))
      assert length(post_routes) == 4
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

      community_idx =
        Enum.find_index(modules, &(&1 == PhoenixFilament.Test.Plugins.TestCommunityPlugin))

      assert resource_idx < community_idx
    end
  end
end

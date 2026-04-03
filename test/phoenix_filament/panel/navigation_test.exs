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

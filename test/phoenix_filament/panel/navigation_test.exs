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

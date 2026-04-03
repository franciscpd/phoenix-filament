defmodule PhoenixFilament.Plugins.ResourcePluginTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugins.ResourcePlugin

  @resources [
    %{module: PostResource, icon: "hero-document-text", nav_group: "Content",
      slug: "posts", label: "Post", plural_label: "Posts"},
    %{module: UserResource, icon: "hero-users", nav_group: nil,
      slug: "users", label: "User", plural_label: "Users"}
  ]

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
      assert length(result.routes) == 8
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

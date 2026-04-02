defmodule PhoenixFilament.Panel.LayoutTest do
  use PhoenixFilament.ComponentCase

  alias PhoenixFilament.Panel.Layout

  @nav %{
    groups: [
      %{
        label: "Content",
        items: [
          %{
            label: "Posts",
            path: "/admin/posts",
            icon: "hero-document-text",
            icon_fallback: "P",
            active: true
          },
          %{
            label: "Categories",
            path: "/admin/categories",
            icon: "hero-tag",
            icon_fallback: "C",
            active: false
          }
        ]
      }
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

    test "renders Dashboard link" do
      assigns = %{nav: @nav, brand: "Admin", logo: nil, path: "/admin", theme_switcher: false}
      html = rendered_to_string(~H"<Layout.sidebar {assigns} />")

      assert html =~ "Dashboard"
    end
  end

  describe "topbar/1" do
    test "renders hamburger menu" do
      assigns = %{brand: "Admin"}
      html = rendered_to_string(~H"<Layout.topbar {assigns} />")

      assert html =~ "panel-sidebar"
      assert html =~ "Admin"
    end
  end

  describe "breadcrumbs/1" do
    test "renders breadcrumb trail" do
      assigns = %{
        items: [
          %{label: "Admin", path: "/admin"},
          %{label: "Posts", path: "/admin/posts"}
        ]
      }

      html = rendered_to_string(~H"<Layout.breadcrumbs {assigns} />")

      assert html =~ "Admin"
      assert html =~ "Posts"
      assert html =~ "breadcrumbs"
    end

    test "renders nothing when items is empty" do
      assigns = %{items: []}
      html = rendered_to_string(~H"<Layout.breadcrumbs {assigns} />")

      refute html =~ "breadcrumbs"
    end
  end

  describe "flash_group/1" do
    test "renders success flash" do
      assigns = %{flash: %{"info" => "Record created"}}
      html = rendered_to_string(~H"<Layout.flash_group {assigns} />")

      assert html =~ "Record created"
      assert html =~ "alert-success"
    end

    test "renders error flash" do
      assigns = %{flash: %{"error" => "Something failed"}}
      html = rendered_to_string(~H"<Layout.flash_group {assigns} />")

      assert html =~ "Something failed"
      assert html =~ "alert-error"
    end

    test "renders nothing when flash is empty" do
      assigns = %{flash: %{}}
      html = rendered_to_string(~H"<Layout.flash_group {assigns} />")

      refute html =~ "alert-success"
      refute html =~ "alert-error"
    end
  end
end

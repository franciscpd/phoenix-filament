defmodule PhoenixFilament.Components.BadgeTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Badge

  describe "badge/1" do
    test "renders badge" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge>Status</Badge.badge>")
      assert html =~ "badge"
      assert html =~ "Status"
    end

    test "renders success color" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge color={:success}>Active</Badge.badge>")
      assert html =~ "badge-success"
    end

    test "renders warning color" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge color={:warning}>Pending</Badge.badge>")
      assert html =~ "badge-warning"
    end

    test "renders error color" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge color={:error}>Failed</Badge.badge>")
      assert html =~ "badge-error"
    end

    test "renders info color" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge color={:info}>Note</Badge.badge>")
      assert html =~ "badge-info"
    end

    test "renders size sm" do
      assigns = %{}
      html = rendered_to_string(~H"<Badge.badge size={:sm}>Small</Badge.badge>")
      assert html =~ "badge-sm"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge class="gap-2">Custom</Badge.badge>
        """)

      assert html =~ "badge"
      assert html =~ "gap-2"
    end
  end
end

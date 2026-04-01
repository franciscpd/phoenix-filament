defmodule PhoenixFilament.Components.ThemeTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Theme

  describe "css_vars/1" do
    test "converts keyword list to CSS variable string" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)", accent: "oklch(70% 0.2 150)")
      assert result =~ "--color-primary: oklch(55% 0.25 260)"
      assert result =~ "--color-accent: oklch(70% 0.2 150)"
    end

    test "returns empty string for empty list" do
      assert Theme.css_vars([]) == ""
    end

    test "handles single color" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)")
      assert result =~ "--color-primary:"
    end
  end

  describe "theme_attr/1" do
    test "returns theme name as string from atom" do
      assert Theme.theme_attr(:dark) == "dark"
      assert Theme.theme_attr(:corporate) == "corporate"
    end

    test "handles string input" do
      assert Theme.theme_attr("retro") == "retro"
    end
  end

  describe "theme_switcher/1" do
    test "renders theme controller toggle" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Theme.theme_switcher />
        """)

      assert html =~ "theme-controller"
      assert html =~ "swap"
    end

    test "accepts custom dark theme" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Theme.theme_switcher dark_theme="cyberpunk" />
        """)

      assert html =~ ~s(value="cyberpunk")
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Theme.theme_switcher class="ml-4" />
        """)

      assert html =~ "swap"
      assert html =~ "ml-4"
    end
  end
end

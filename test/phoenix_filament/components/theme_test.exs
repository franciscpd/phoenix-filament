defmodule PhoenixFilament.Components.ThemeTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Theme

  describe "css_vars/1" do
    test "converts keyword list to CSS variable string" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)", accent: "oklch(70% 0.2 150)")
      assert result =~ "--p:"
      assert result =~ "55% 0.25 260"
      assert result =~ "--a:"
      assert result =~ "70% 0.2 150"
    end

    test "returns empty string for empty list" do
      assert Theme.css_vars([]) == ""
    end

    test "handles single color" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)")
      assert result =~ "--p:"
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
end

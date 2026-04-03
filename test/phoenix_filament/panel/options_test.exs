defmodule PhoenixFilament.Panel.OptionsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Options

  describe "panel_schema/0" do
    test "validates valid panel options" do
      opts = [path: "/admin"]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.panel_schema())
      assert validated[:path] == "/admin"
      assert validated[:brand_name] == "Admin"
    end

    test "requires :path option" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               NimbleOptions.validate([], Options.panel_schema())
    end

    test "validates on_mount as {module, atom} tuple" do
      opts = [path: "/admin", on_mount: {MyAuth, :require_admin}]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.panel_schema())
      assert validated[:on_mount] == {MyAuth, :require_admin}
    end

    test "validates plug as module or {module, term} tuple" do
      assert {:ok, _} =
               NimbleOptions.validate([path: "/admin", plug: MyPlug], Options.panel_schema())

      assert {:ok, _} =
               NimbleOptions.validate(
                 [path: "/admin", plug: {MyPlug, []}],
                 Options.panel_schema()
               )
    end

    test "defaults brand_name to Admin" do
      {:ok, validated} = NimbleOptions.validate([path: "/admin"], Options.panel_schema())
      assert validated[:brand_name] == "Admin"
    end

    test "defaults theme_switcher to false" do
      {:ok, validated} = NimbleOptions.validate([path: "/admin"], Options.panel_schema())
      assert validated[:theme_switcher] == false
    end

    test "rejects unknown options" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               NimbleOptions.validate([path: "/admin", bogus: true], Options.panel_schema())
    end
  end

  describe "resource_schema/0" do
    test "validates resource registration with all options" do
      opts = [icon: "hero-document", nav_group: "Blog", slug: "articles"]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.resource_schema())
      assert validated[:icon] == "hero-document"
      assert validated[:nav_group] == "Blog"
      assert validated[:slug] == "articles"
    end

    test "all resource options are optional" do
      assert {:ok, _} = NimbleOptions.validate([], Options.resource_schema())
    end
  end

  describe "widget_schema/0" do
    test "validates widget registration options" do
      opts = [sort: 1, column_span: 6]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.widget_schema())
      assert validated[:sort] == 1
      assert validated[:column_span] == 6
    end

    test "defaults sort to 0 and column_span to 12" do
      {:ok, validated} = NimbleOptions.validate([], Options.widget_schema())
      assert validated[:sort] == 0
      assert validated[:column_span] == 12
    end

    test "accepts :full as column_span" do
      {:ok, validated} = NimbleOptions.validate([column_span: :full], Options.widget_schema())
      assert validated[:column_span] == :full
    end
  end
end

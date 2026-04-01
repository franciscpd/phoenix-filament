defmodule PhoenixFilament.NamingTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Naming

  describe "humanize/1" do
    test "converts atom to capitalized string" do
      assert Naming.humanize(:title) == "Title"
    end

    test "replaces underscores with spaces" do
      assert Naming.humanize(:published_at) == "Published at"
    end

    test "handles single-word atoms" do
      assert Naming.humanize(:name) == "Name"
    end

    test "handles multi-underscore atoms" do
      assert Naming.humanize(:some_long_field_name) == "Some long field name"
    end
  end
end

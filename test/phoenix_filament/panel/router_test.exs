defmodule PhoenixFilament.Panel.RouterTest do
  use ExUnit.Case, async: true

  test "Router module compiles and exports phoenix_filament_panel/2 macro" do
    assert {:phoenix_filament_panel, 2} in PhoenixFilament.Panel.Router.__info__(:macros)
  end

  test "panel module has resources with correct slugs for route generation" do
    resources = PhoenixFilament.Test.Panels.TestPanel.__panel__(:resources)
    assert length(resources) >= 1

    [resource | _] = resources
    assert is_binary(resource.slug)
    assert resource.slug == "posts"
  end
end

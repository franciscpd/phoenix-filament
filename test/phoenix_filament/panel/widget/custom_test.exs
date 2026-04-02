defmodule PhoenixFilament.Widget.CustomTest do
  use ExUnit.Case, async: true

  test "custom widget module compiles and has render/1" do
    Code.ensure_loaded!(PhoenixFilament.Test.Widgets.TestCustom)
    assert function_exported?(PhoenixFilament.Test.Widgets.TestCustom, :render, 1)
  end

  test "custom widget is a LiveComponent" do
    Code.ensure_loaded!(PhoenixFilament.Test.Widgets.TestCustom)
    assert function_exported?(PhoenixFilament.Test.Widgets.TestCustom, :update, 2)
  end
end

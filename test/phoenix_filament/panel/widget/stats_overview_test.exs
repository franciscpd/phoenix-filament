defmodule PhoenixFilament.Widget.StatsOverviewTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestStats

  describe "stats/1 callback" do
    test "returns list of stat structs" do
      stats = TestStats.stats(%{})
      assert length(stats) == 2

      [first, second] = stats
      assert first.label == "Total Posts"
      assert first.value == 42
      assert first.icon == "hero-document-text"
      assert first.color == :success
      assert first.description == "5 new today"
      assert second.label == "Users"
      assert second.value == 128
    end
  end

  test "module is a LiveComponent" do
    Code.ensure_loaded!(TestStats)
    assert function_exported?(TestStats, :update, 2)
    assert function_exported?(TestStats, :render, 1)
  end
end

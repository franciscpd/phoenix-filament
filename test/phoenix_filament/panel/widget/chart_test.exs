defmodule PhoenixFilament.Widget.ChartTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestChart

  describe "chart callbacks" do
    test "chart_type returns atom" do
      assert TestChart.chart_type() == :bar
    end

    test "chart_data returns labels and datasets" do
      data = TestChart.chart_data(%{})
      assert data.labels == ["Jan", "Feb", "Mar"]
      assert length(data.datasets) == 1
      assert hd(data.datasets).data == [10, 20, 15]
    end
  end

  test "module is a LiveComponent" do
    Code.ensure_loaded!(TestChart)
    assert function_exported?(TestChart, :update, 2)
    assert function_exported?(TestChart, :render, 1)
  end
end

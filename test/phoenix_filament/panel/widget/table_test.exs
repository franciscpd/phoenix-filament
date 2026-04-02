defmodule PhoenixFilament.Widget.TableTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Widgets.TestTable

  describe "table widget callbacks" do
    test "heading returns string" do
      assert TestTable.heading() == "Recent Posts"
    end

    test "columns returns list of Column structs" do
      columns = TestTable.columns()
      assert length(columns) == 2
      assert hd(columns).name == :title
    end
  end

  test "module is a LiveComponent" do
    Code.ensure_loaded!(TestTable)
    assert function_exported?(TestTable, :update, 2)
    assert function_exported?(TestTable, :render, 1)
  end
end

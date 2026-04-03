defmodule PhoenixFilament.Panel.DashboardTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Dashboard

  test "module compiles and is a LiveView" do
    Code.ensure_loaded!(Dashboard)
    assert function_exported?(Dashboard, :mount, 3)
    assert function_exported?(Dashboard, :render, 1)
    assert function_exported?(Dashboard, :handle_info, 2)
  end
end

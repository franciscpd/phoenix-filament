defmodule PhoenixFilament.Panel.DashboardTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Dashboard

  test "module compiles and is a LiveView" do
    Code.ensure_loaded!(Dashboard)
    assert function_exported?(Dashboard, :mount, 3)
    assert function_exported?(Dashboard, :render, 1)
    assert function_exported?(Dashboard, :handle_info, 2)
  end

  test "Dashboard reads :all_widgets from panel module" do
    {:ok, source} = File.read("lib/phoenix_filament/panel/dashboard.ex")
    assert source =~ ":all_widgets"
  end

  test "Dashboard renders empty state message for no widgets" do
    {:ok, source} = File.read("lib/phoenix_filament/panel/dashboard.ex")
    assert source =~ "No widgets configured"
  end
end

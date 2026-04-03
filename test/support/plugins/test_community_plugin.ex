defmodule PhoenixFilament.Test.Plugins.TestCommunityPlugin do
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    %{
      nav_items: [
        nav_item("Analytics",
          path: "/analytics",
          icon: "hero-chart-bar",
          nav_group: opts[:nav_group] || "Reports"
        )
      ],
      routes: [
        route("/analytics", PhoenixFilament.Test.Plugins.TestCommunityPlugin, :index)
      ]
    }
  end

  @impl true
  def boot(socket) do
    Phoenix.Component.assign(socket, :analytics_enabled, true)
  end
end

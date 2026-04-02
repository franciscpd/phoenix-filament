defmodule PhoenixFilament.Test.Widgets.TestStats do
  use PhoenixFilament.Widget.StatsOverview

  @impl true
  def stats(_assigns) do
    [
      stat("Total Posts", 42, icon: "hero-document-text", color: :success, description: "5 new today"),
      stat("Users", 128, color: :info)
    ]
  end
end

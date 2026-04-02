defmodule PhoenixFilament.Test.Widgets.TestChart do
  use PhoenixFilament.Widget.Chart

  @impl true
  def chart_type, do: :bar

  @impl true
  def chart_data(_assigns) do
    %{
      labels: ["Jan", "Feb", "Mar"],
      datasets: [%{label: "Posts", data: [10, 20, 15]}]
    }
  end
end

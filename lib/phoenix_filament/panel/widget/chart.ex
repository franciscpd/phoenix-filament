defmodule PhoenixFilament.Widget.Chart do
  @moduledoc """
  A widget that displays a Chart.js chart.
  """

  @callback chart_type() :: :line | :bar | :pie | :doughnut
  @callback chart_data(assigns :: map()) :: %{labels: [String.t()], datasets: [map()]}

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Chart

      @polling_interval nil

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)
        data = __MODULE__.chart_data(socket.assigns)
        chart_type = __MODULE__.chart_type()

        chart_config = %{type: chart_type, data: data, options: %{}}
        socket = Phoenix.Component.assign(socket, :chart_config, Jason.encode!(chart_config))
        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.Chart.render(assigns)
      end

      defoverridable render: 1, update: 2
    end
  end

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <canvas
          id={@id <> "-canvas"}
          phx-hook="PhxFilamentChart"
          data-chart={@chart_config}
          phx-update="ignore"
          style="max-height: 300px;"
        >
        </canvas>
      </div>
    </div>
    """
  end
end

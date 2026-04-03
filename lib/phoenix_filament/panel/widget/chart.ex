defmodule PhoenixFilament.Widget.Chart do
  @moduledoc """
  A widget that displays a Chart.js chart.
  """

  @callback chart_type() :: :line | :bar | :pie | :doughnut
  @callback chart_data(assigns :: map()) :: %{labels: [String.t()], datasets: [map()]}
  @callback chart_options() :: map()

  @optional_callbacks [chart_options: 0]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Chart

      @polling_interval nil

      @doc "Override to provide Chart.js options map. Defaults to empty map."
      def chart_options, do: %{}
      defoverridable chart_options: 0

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)

        {chart_config, widget_error} =
          try do
            data = __MODULE__.chart_data(socket.assigns)
            chart_type = __MODULE__.chart_type()
            chart_opts = __MODULE__.chart_options()
            {Jason.encode!(%{type: chart_type, data: data, options: chart_opts}), nil}
          rescue
            e -> {nil, Exception.message(e)}
          end

        socket =
          socket
          |> Phoenix.Component.assign(:chart_config, chart_config)
          |> Phoenix.Component.assign(:widget_error, widget_error)

        socket =
          if @polling_interval && !socket.assigns[:_polling_started] do
            Process.send_after(self(), {:widget_refresh, __MODULE__}, @polling_interval)
            Phoenix.Component.assign(socket, :_polling_started, true)
          else
            socket
          end

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
    <div :if={assigns[:widget_error]} class="alert alert-error">
      <span>Widget error: {assigns[:widget_error]}</span>
    </div>
    <div :if={!assigns[:widget_error]} class="card bg-base-100 shadow">
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

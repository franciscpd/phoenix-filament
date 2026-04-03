defmodule PhoenixFilament.Widget.StatsOverview do
  @moduledoc """
  A widget that displays statistics as cards.

  ## Usage

      defmodule MyApp.Admin.StatsWidget do
        use PhoenixFilament.Widget.StatsOverview

        @impl true
        def stats(_assigns) do
          [
            stat("Posts", Repo.aggregate(Post, :count),
              icon: "hero-document-text",
              color: :success,
              description: "12 new today")
          ]
        end
      end
  """

  @callback stats(assigns :: map()) :: [map()]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.StatsOverview
      import PhoenixFilament.Widget.StatsOverview, only: [stat: 2, stat: 3]

      @polling_interval nil

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)

        {stats, widget_error} =
          try do
            {__MODULE__.stats(socket.assigns), nil}
          rescue
            e -> {[], Exception.message(e)}
          end

        socket =
          socket
          |> Phoenix.Component.assign(:stats, stats)
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
        PhoenixFilament.Widget.StatsOverview.render(assigns)
      end

      defoverridable render: 1, update: 2
    end
  end

  use Phoenix.Component
  import PhoenixFilament.Components.Icon

  def render(assigns) do
    ~H"""
    <div :if={assigns[:widget_error]} class="alert alert-error">
      <span>Widget error: {assigns[:widget_error]}</span>
    </div>
    <div :if={!assigns[:widget_error]} class="stats stats-vertical lg:stats-horizontal shadow w-full">
      <div :for={s <- @stats} class="stat">
        <div :if={s.icon} class="stat-figure text-primary">
          <.icon name={s.icon} />
        </div>
        <div class="stat-title">{s.label}</div>
        <div class={["stat-value", stat_color_class(s.color)]}>{s.value}</div>
        <div :if={s.description} class="stat-desc">{s.description}</div>
        <.sparkline :if={s.chart} data={s.chart} />
      </div>
    </div>
    """
  end

  attr :data, :list, required: true

  def sparkline(assigns) do
    ~H"""
    <div class="stat-figure">
      <svg viewBox={"0 0 #{length(@data) * 10} 40"} class="h-10 w-20 overflow-visible">
        <polyline
          points={sparkline_points(@data)}
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="text-primary"
        />
      </svg>
    </div>
    """
  end

  defp sparkline_points([]), do: ""

  defp sparkline_points(data) do
    max_val = Enum.max(data, fn -> 1 end)
    min_val = Enum.min(data, fn -> 0 end)
    range = max(max_val - min_val, 1)
    total = length(data)

    data
    |> Enum.with_index()
    |> Enum.map(fn {val, i} ->
      x = if total > 1, do: i * 10, else: 0
      y = 40 - round((val - min_val) / range * 36) - 2
      "#{x},#{y}"
    end)
    |> Enum.join(" ")
  end

  defp stat_color_class(:success), do: "text-success"
  defp stat_color_class(:error), do: "text-error"
  defp stat_color_class(:warning), do: "text-warning"
  defp stat_color_class(:info), do: "text-info"
  defp stat_color_class(_), do: ""

  def stat(label, value, opts \\ []) do
    %{
      label: label,
      value: value,
      icon: opts[:icon],
      description: opts[:description],
      description_icon: opts[:description_icon],
      color: opts[:color],
      chart: opts[:chart]
    }
  end
end

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
        stats = __MODULE__.stats(socket.assigns)
        socket = Phoenix.Component.assign(socket, :stats, stats)
        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.StatsOverview.render(assigns)
      end

      defoverridable render: 1, update: 2
    end
  end

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
      <div :for={s <- @stats} class="stat">
        <div :if={s.icon} class="stat-figure text-primary">
          <span>{s.icon}</span>
        </div>
        <div class="stat-title">{s.label}</div>
        <div class={["stat-value", stat_color_class(s.color)]}>{s.value}</div>
        <div :if={s.description} class="stat-desc">{s.description}</div>
      </div>
    </div>
    """
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

defmodule PhoenixFilament.Widget.Table do
  @moduledoc """
  A widget that displays a simple read-only table on the dashboard.
  """

  @callback columns() :: [PhoenixFilament.Column.t()]
  @callback heading() :: String.t()

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Table

      @polling_interval nil

      def heading, do: "Table"
      defoverridable heading: 0

      def update(assigns, socket) do
        socket = Phoenix.Component.assign(socket, assigns)
        socket = Phoenix.Component.assign(socket, :widget_heading, __MODULE__.heading())
        socket = Phoenix.Component.assign(socket, :widget_columns, __MODULE__.columns())
        {:ok, socket}
      end

      def render(assigns) do
        PhoenixFilament.Widget.Table.render(assigns)
      end

      defoverridable render: 1, update: 2
    end
  end

  use Phoenix.Component

  def render(assigns) do
    assigns = Map.put_new(assigns, :rows, [])

    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h3 class="card-title text-sm">{@widget_heading}</h3>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th :for={col <- @widget_columns}>{col.label || PhoenixFilament.Naming.humanize(col.name)}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- @rows}>
                <td :for={col <- @widget_columns}>{Map.get(row, col.name)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end

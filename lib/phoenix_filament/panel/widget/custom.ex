defmodule PhoenixFilament.Widget.Custom do
  @moduledoc """
  A free-form widget for custom content on the dashboard.
  """

  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      @behaviour PhoenixFilament.Widget.Custom

      def update(assigns, socket) do
        {:ok, Phoenix.Component.assign(socket, assigns)}
      end

      defoverridable update: 2
    end
  end
end

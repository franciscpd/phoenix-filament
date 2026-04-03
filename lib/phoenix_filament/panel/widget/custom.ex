defmodule PhoenixFilament.Widget.Custom do
  @moduledoc """
  A free-form widget for custom content on the dashboard.

  Implements `Phoenix.LiveComponent` — provide a `render/1` callback.
  """

  # No @callback — Phoenix.LiveComponent already defines render/1
  # No @behaviour declaration needed

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent

      def update(assigns, socket) do
        {:ok, Phoenix.Component.assign(socket, assigns)}
      end

      defoverridable update: 2
    end
  end
end

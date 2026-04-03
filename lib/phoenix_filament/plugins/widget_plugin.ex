defmodule PhoenixFilament.Plugins.WidgetPlugin do
  @moduledoc false
  use PhoenixFilament.Plugin

  @impl true
  def register(_panel, opts) do
    %{widgets: opts[:widgets] || []}
  end
end

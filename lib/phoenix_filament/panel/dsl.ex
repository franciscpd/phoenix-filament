defmodule PhoenixFilament.Panel.DSL do
  @moduledoc false

  defmacro resources(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro widgets(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro resource(module, opts \\ []) do
    quote do
      validated_opts =
        NimbleOptions.validate!(unquote(opts), PhoenixFilament.Panel.Options.resource_schema())

      @_phx_filament_panel_resources {unquote(module), validated_opts}
    end
  end

  defmacro widget(module, opts \\ []) do
    quote do
      validated_opts =
        NimbleOptions.validate!(unquote(opts), PhoenixFilament.Panel.Options.widget_schema())

      @_phx_filament_panel_widgets {unquote(module), validated_opts}
    end
  end

  defmacro plugins(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro plugin(module, opts \\ []) do
    quote do
      @_phx_filament_panel_plugins {unquote(module), unquote(opts)}
    end
  end
end

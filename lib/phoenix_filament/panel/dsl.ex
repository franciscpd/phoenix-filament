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
      mod = unquote(module)

      case Code.ensure_compiled(mod) do
        {:module, _} ->
          unless function_exported?(mod, :register, 2) do
            raise ArgumentError,
                  "#{inspect(mod)} does not implement PhoenixFilament.Plugin behaviour " <>
                  "(missing register/2). Did you forget `use PhoenixFilament.Plugin`?"
          end

        {:error, _} ->
          :ok
      end

      @_phx_filament_panel_plugins {unquote(module), unquote(opts)}
    end
  end
end

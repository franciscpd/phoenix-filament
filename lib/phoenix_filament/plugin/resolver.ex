defmodule PhoenixFilament.Plugin.Resolver do
  @moduledoc false

  @defaults %{nav_items: [], routes: [], widgets: [], hooks: []}

  @doc false
  def resolve(plugins, panel_module) do
    results =
      Enum.map(plugins, fn {mod, opts} ->
        result = mod.register(panel_module, opts)
        Map.merge(@defaults, result)
      end)

    %{
      all_nav_items: Enum.flat_map(results, & &1.nav_items),
      all_routes: Enum.flat_map(results, & &1.routes),
      all_widgets: Enum.flat_map(results, & &1.widgets) |> Enum.sort_by(&(&1[:sort] || 0)),
      all_hooks: Enum.flat_map(results, & &1.hooks)
    }
  end
end

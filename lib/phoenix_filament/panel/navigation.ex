defmodule PhoenixFilament.Panel.Navigation do
  @moduledoc false

  def build_tree(resources, panel_path, current_path) do
    {grouped, ungrouped} =
      resources
      |> Enum.map(fn r -> build_item(r, panel_path, current_path) end)
      |> Enum.split_with(fn item -> item.nav_group != nil end)

    groups =
      grouped
      |> Enum.reduce({[], %{}}, fn item, {order, groups} ->
        group_name = item.nav_group

        if Map.has_key?(groups, group_name) do
          {order, Map.update!(groups, group_name, &(&1 ++ [item]))}
        else
          {order ++ [group_name], Map.put(groups, group_name, [item])}
        end
      end)
      |> then(fn {order, groups} ->
        Enum.map(order, fn name -> %{label: name, items: groups[name]} end)
      end)

    %{groups: groups, ungrouped: ungrouped}
  end

  defp build_item(resource, panel_path, current_path) do
    path = "#{panel_path}/#{resource.slug}"
    label = resource.plural_label

    %{
      label: label,
      path: path,
      icon: resource.icon,
      icon_fallback: String.first(label),
      nav_group: resource.nav_group,
      active: String.starts_with?(current_path, path),
      module: resource.module
    }
  end
end

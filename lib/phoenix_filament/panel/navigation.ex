defmodule PhoenixFilament.Panel.Navigation do
  @moduledoc false

  def build_tree(nav_items, current_path) do
    items = Enum.map(nav_items, &add_active(&1, current_path))
    {grouped, ungrouped} = Enum.split_with(items, &(&1.nav_group != nil))

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

  defp add_active(item, current_path) do
    Map.put(item, :active, String.starts_with?(current_path, item.path))
  end
end

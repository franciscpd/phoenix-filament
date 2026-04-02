defmodule PhoenixFilament.Panel.Navigation do
  @moduledoc false

  def build_tree(resources, panel_path, current_path) do
    {grouped, ungrouped} =
      resources
      |> Enum.map(fn r -> build_item(r, panel_path, current_path) end)
      |> Enum.split_with(fn item -> item.nav_group != nil end)

    groups =
      grouped
      |> Enum.chunk_by(& &1.nav_group)
      |> Enum.map(fn items ->
        %{label: hd(items).nav_group, items: items}
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

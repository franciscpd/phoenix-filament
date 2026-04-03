defmodule PhoenixFilament.Plugins.ResourcePlugin do
  @moduledoc false
  use PhoenixFilament.Plugin

  @impl true
  def register(panel, opts) do
    resources = opts[:resources] || []
    panel_path = panel.__panel__(:path)

    %{
      nav_items:
        Enum.map(resources, fn r ->
          nav_item(r.plural_label,
            path: "#{panel_path}/#{r.slug}",
            icon: r.icon,
            nav_group: r.nav_group
          )
        end),
      routes:
        Enum.flat_map(resources, fn r ->
          [
            route("/#{r.slug}", r.module, :index),
            route("/#{r.slug}/new", r.module, :new),
            route("/#{r.slug}/:id", r.module, :show),
            route("/#{r.slug}/:id/edit", r.module, :edit)
          ]
        end)
    }
  end
end

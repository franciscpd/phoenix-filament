defmodule PhoenixFilament.Panel.Options do
  @moduledoc false

  @panel_schema NimbleOptions.new!(
                  path: [type: :string, required: true, doc: "URL path prefix (e.g., \"/admin\")"],
                  on_mount: [
                    type: {:tuple, [:atom, :atom]},
                    doc: "LiveView on_mount hook for auth as {Module, :function}"
                  ],
                  plug: [
                    type: {:or, [:atom, {:tuple, [:atom, :any]}]},
                    doc: "Plug module or {module, opts} for HTTP auth"
                  ],
                  brand_name: [
                    type: :string,
                    default: "Admin",
                    doc: "Display name in sidebar header"
                  ],
                  logo: [type: :string, doc: "Logo URL for sidebar header"],
                  theme: [type: :string, doc: "daisyUI theme name"],
                  theme_switcher: [type: :boolean, default: false, doc: "Show light/dark toggle"],
                  theme_switcher_target: [
                    type: :string,
                    default: "dark",
                    doc: "Theme to toggle to when theme switcher is activated"
                  ],
                  pubsub: [type: :atom, doc: "PubSub module for session revocation"],
                  dashboard: [type: :atom, doc: "Custom LiveView to override default dashboard"]
                )

  @resource_schema NimbleOptions.new!(
                     icon: [type: :string, doc: "Heroicon name (e.g., \"hero-document-text\")"],
                     nav_group: [type: :string, doc: "Sidebar group heading"],
                     slug: [type: :string, doc: "URL slug override"]
                   )

  @widget_schema NimbleOptions.new!(
                   sort: [type: :integer, default: 0, doc: "Widget rendering order (ascending)"],
                   column_span: [
                     type: {:or, [:integer, {:in, [:full]}]},
                     default: 12,
                     doc: "Grid column span (1-12 or :full)"
                   ]
                 )

  def panel_schema, do: @panel_schema
  def resource_schema, do: @resource_schema
  def widget_schema, do: @widget_schema
end

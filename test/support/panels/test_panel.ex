defmodule PhoenixFilament.Test.Panels.TestPanel do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "Test Admin",
    theme: "corporate",
    theme_switcher: true

  resources do
    resource PhoenixFilament.Test.Resources.TestPostResource,
      icon: "hero-document-text",
      nav_group: "Content"
  end

  widgets do
    widget PhoenixFilament.Test.Widgets.TestStats, sort: 1, column_span: :full
    widget PhoenixFilament.Test.Widgets.TestCustom, sort: 2, column_span: 6
  end

  plugins do
    plugin PhoenixFilament.Test.Plugins.TestCommunityPlugin, nav_group: "Tools"
  end
end

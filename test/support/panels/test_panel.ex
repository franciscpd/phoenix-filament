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
  end
end

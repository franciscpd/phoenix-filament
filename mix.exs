defmodule PhoenixFilament.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/franciscpd/phoenix-filament"

  def project do
    [
      app: :phoenix_filament,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "PhoenixFilament",
      source_url: @source_url,
      description:
        "Rapid application development framework for Phoenix — declarative admin panels from Ecto schemas",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.11"},
      {:nimble_options, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:phoenix_html, "~> 4.1", optional: true},
      {:phoenix_ecto, "~> 4.4", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:igniter, "~> 0.7", optional: true}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv guides .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "PhoenixFilament",
      extras: [
        "guides/getting-started.md",
        "guides/resources.md",
        "guides/plugins.md",
        "guides/theming.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.*/
      ],
      groups_for_modules: [
        Core: [PhoenixFilament, PhoenixFilament.Resource, PhoenixFilament.Panel],
        Components: ~r/PhoenixFilament\.Components\..*/,
        "Form Builder": ~r/PhoenixFilament\.Form\..*/,
        "Table Builder": ~r/PhoenixFilament\.Table\..*/,
        Widgets: ~r/PhoenixFilament\.Widget\..*/,
        "Plugin System": [PhoenixFilament.Plugin, PhoenixFilament.Plugin.Resolver],
        "Mix Tasks": ~r/Mix\.Tasks\..*/
      ]
    ]
  end
end

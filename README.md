# PhoenixFilament

Rapid application development framework for Phoenix — declarative admin panels from Ecto schemas.

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_filament.svg)](https://hex.pm/packages/phoenix_filament)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/phoenix_filament)

## Features

- **Declarative DSL** — Define forms and tables with `form do...end` and `table do...end` blocks
- **Zero-code CRUD** — `use PhoenixFilament.Resource` generates index, create, edit, show pages
- **Admin Panel Shell** — Sidebar navigation, breadcrumbs, responsive layout, flash toasts
- **Dashboard Widgets** — Stats cards, charts (Chart.js), tables, custom widgets
- **Plugin System** — Extend panels with community plugins using the same API as built-in features
- **BYO Auth** — Panel delegates authentication to your app via `on_mount` hooks
- **daisyUI Theming** — 30+ themes out of the box, per-panel customization via CSS variables

## Quick Start

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_filament, "~> 0.1"},
    {:igniter, "~> 0.7"}  # for installer
  ]
end
```

Then run:

```bash
mix deps.get
mix phx_filament.install
mix phx_filament.gen.resource MyApp.Blog.Post
mix phx.server
```

Visit `http://localhost:4000/admin` to see your admin panel.

## Documentation

- [Getting Started Guide](https://hexdocs.pm/phoenix_filament/getting-started.html)
- [Resource Customization](https://hexdocs.pm/phoenix_filament/resources.html)
- [Plugin Development](https://hexdocs.pm/phoenix_filament/plugins.html)
- [Theming Guide](https://hexdocs.pm/phoenix_filament/theming.html)
- [API Reference](https://hexdocs.pm/phoenix_filament)

## Requirements

- Elixir >= 1.15
- Phoenix >= 1.7 (1.8+ recommended for daisyUI 5 out-of-the-box)
- Phoenix LiveView >= 1.0
- Ecto >= 3.11

## License

MIT — see [LICENSE](LICENSE) for details.

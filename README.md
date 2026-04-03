# PhoenixFilament

Rapid application development framework for Phoenix — declarative admin panels from Ecto schemas.

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_filament.svg)](https://hex.pm/packages/phoenix_filament)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/phoenix_filament)
[![License](https://img.shields.io/hexpm/l/phoenix_filament.svg)](https://github.com/franciscpd/phoenix-filament/blob/main/LICENSE)

---

Go from an Ecto schema to a fully functional admin interface in minutes — with a declarative, idiomatic Elixir API that feels native to the Phoenix ecosystem.

## Features

- **Declarative DSL** — Define forms and tables with `form do...end` and `table do...end` blocks
- **Zero-code CRUD** — `use PhoenixFilament.Resource` generates index, create, edit, and show pages
- **Admin Panel Shell** — Sidebar navigation, breadcrumbs, responsive layout, flash toasts
- **Dashboard Widgets** — Stats cards, Chart.js charts, tables, and custom widgets
- **Plugin System** — Extend panels with community plugins using the same API as built-in features
- **BYO Auth** — Panel delegates authentication to your app via `on_mount` hooks
- **daisyUI Theming** — 35+ themes out of the box, per-panel customization via CSS variables

## Quick Start

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_filament, "~> 0.1"},
    {:igniter, "~> 0.7"}  # required for the installer
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

Full documentation is available on [HexDocs](https://hexdocs.pm/phoenix_filament).

- [Getting Started](guides/getting-started.md)
- [Resource Customization](guides/resources.md)
- [Plugin Development](guides/plugins.md)
- [Theming Guide](guides/theming.md)

## Requirements

| Dependency | Version |
|---|---|
| Elixir | >= 1.17 |
| Phoenix | >= 1.7 (1.8+ recommended) |
| Phoenix LiveView | >= 1.0 |
| Ecto | >= 3.11 |

## License

MIT — see [LICENSE](LICENSE) for details.

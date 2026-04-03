# Phase 8: Distribution and Installer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish PhoenixFilament on Hex with Igniter-based installer (`mix phx_filament.install`), resource generator (`mix phx_filament.gen.resource`), and comprehensive ExDoc guide pages.

**Architecture:** Two Igniter Mix tasks handle AST-based code patching (idempotent, composable). EEx templates generate Panel and Resource modules. Four ExDoc guide pages cover the full developer journey. mix.exs finalized for Hex publication.

**Tech Stack:** Elixir, Igniter 0.7+, ExDoc, EEx templates

---

## File Structure

```
NEW FILES:
lib/mix/tasks/phx_filament.install.ex          # Igniter installer task
lib/mix/tasks/phx_filament.gen.resource.ex      # Igniter resource generator
priv/templates/admin.ex.eex                     # Panel module template
priv/templates/resource.ex.eex                  # Resource module template
guides/getting-started.md                       # Full tutorial
guides/resources.md                             # Resource DSL guide
guides/plugins.md                               # Plugin development guide
guides/theming.md                               # Theme customization guide
README.md                                       # Project README

MODIFIED FILES:
mix.exs                                         # Igniter dep, docs config, package files
```

---

## Task 1: Add Igniter Dependency + mix.exs Finalization

**Files:**
- Modify: `mix.exs`

- [ ] **Step 1: Add Igniter to deps and finalize mix.exs**

Read the current `mix.exs`. Make these changes:

1. Add `{:igniter, "~> 0.7", optional: true}` to deps
2. Add `docs: docs()` to the `project/0` keyword list
3. Add `files` to `package/0`
4. Add `docs/0` private function

```elixir
# In project/0, add:
docs: docs(),

# Update package/0:
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib priv guides .formatter.exs mix.exs README.md LICENSE)
  ]
end

# Add new function:
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

# In deps/0, add:
{:igniter, "~> 0.7", optional: true},
```

- [ ] **Step 2: Run mix deps.get**

Run: `mix deps.get`
Expected: Igniter and its deps resolved successfully

- [ ] **Step 3: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 4: Commit**

```
chore: add Igniter dep, finalize mix.exs for Hex publication
```

---

## Task 2: EEx Templates

**Files:**
- Create: `priv/templates/admin.ex.eex`
- Create: `priv/templates/resource.ex.eex`

- [ ] **Step 1: Create Panel module template**

```eex
# priv/templates/admin.ex.eex
defmodule <%= @panel_module %> do
  use PhoenixFilament.Panel,
    path: "/admin",
    brand_name: "<%= @brand_name %>"

  # Add your resources here:
  # resources do
  #   resource <%= @panel_module %>.PostResource,
  #     icon: "hero-document-text"
  # end

  # Add dashboard widgets:
  # widgets do
  #   widget <%= @panel_module %>.StatsWidget
  # end

  # Add community plugins:
  # plugins do
  #   plugin MyPlugin
  # end
end
```

- [ ] **Step 2: Create Resource module template**

```eex
# priv/templates/resource.ex.eex
defmodule <%= @resource_module %> do
  use PhoenixFilament.Resource,
    schema: <%= @schema %>,
    repo: <%= @repo %>
end
```

- [ ] **Step 3: Verify templates exist**

Run: `ls priv/templates/`
Expected: `admin.ex.eex  resource.ex.eex`

- [ ] **Step 4: Commit**

```
feat(installer): add EEx templates for Panel and Resource modules
```

---

## Task 3: mix phx_filament.install

**Files:**
- Create: `lib/mix/tasks/phx_filament.install.ex`

- [ ] **Step 1: Create the installer task**

```elixir
# lib/mix/tasks/phx_filament.install.ex
defmodule Mix.Tasks.PhxFilament.Install do
  @moduledoc """
  Installs PhoenixFilament admin panel in your Phoenix app.

  ## Usage

      mix phx_filament.install

  ## What it does

  1. Creates an admin Panel module at `lib/{app_web}/admin.ex`
  2. Patches `router.ex` to import and mount the panel
  3. Copies Chart.js vendor asset to `assets/vendor/`
  4. Patches `app.js` to register the Chart widget hook

  Running this task multiple times is safe — it is idempotent.
  """

  if Code.ensure_loaded?(Igniter) do
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_filament,
        example: "mix phx_filament.install",
        schema: [],
        aliases: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)
      app_name_camel = app_name |> to_string() |> Macro.camelize()
      web_module = Module.concat([app_name_camel, "Web"])
      panel_module = Module.concat(web_module, "Admin")
      brand_name = "#{app_name_camel} Admin"

      igniter
      |> create_panel_module(panel_module, web_module, brand_name)
      |> patch_router(web_module, panel_module)
      |> copy_chart_js()
      |> patch_app_js()
    end

    defp create_panel_module(igniter, panel_module, web_module, brand_name) do
      template_path = Application.app_dir(:phoenix_filament, "priv/templates/admin.ex.eex")

      panel_path =
        panel_module
        |> Module.split()
        |> Enum.map(&Macro.underscore/1)
        |> then(fn parts -> Path.join(["lib" | parts]) <> ".ex" end)

      contents =
        EEx.eval_file(template_path,
          assigns: [
            panel_module: inspect(panel_module),
            brand_name: brand_name
          ]
        )

      Igniter.create_new_file(igniter, panel_path, contents)
    end

    defp patch_router(igniter, web_module, panel_module) do
      router_module = Module.concat(web_module, "Router")

      igniter
      |> Igniter.Project.Module.find_and_update_module!(router_module, fn zipper ->
        # Add import if not present
        with {:ok, zipper} <-
               Igniter.Code.Module.move_to_use(zipper, Phoenix.Router) do
          {:ok,
           Igniter.Code.Common.add_code(zipper, """
           import PhoenixFilament.Panel.Router
           """)}
        end
      end)
    end

    defp copy_chart_js(igniter) do
      source = Application.app_dir(:phoenix_filament, "priv/static/vendor/chart.min.js")
      dest = "assets/vendor/chart.min.js"

      if File.exists?(source) do
        Igniter.copy_file(igniter, source, dest)
      else
        igniter
      end
    end

    defp patch_app_js(igniter) do
      hook_code = """
      // PhoenixFilament Chart.js Hook
      import Chart from "../vendor/chart.min.js"

      let PhxFilamentHooks = {}
      PhxFilamentHooks.PhxFilamentChart = {
        mounted() {
          const config = JSON.parse(this.el.dataset.chart)
          this.chart = new Chart(this.el, config)
        },
        updated() {
          const config = JSON.parse(this.el.dataset.chart)
          this.chart.data = config.data
          this.chart.update()
        },
        destroyed() {
          if (this.chart) this.chart.destroy()
        }
      }
      """

      Igniter.update_file(igniter, "assets/js/app.js", fn source ->
        if String.contains?(source, "PhxFilamentChart") do
          source
        else
          hook_code <> "\n" <> source
        end
      end)
    end
  else
    use Mix.Task

    @shortdoc "Installs PhoenixFilament (requires Igniter)"

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      PhoenixFilament installer requires Igniter.

      Add {:igniter, "~> 0.7"} to your deps in mix.exs and run:

          mix deps.get
          mix phx_filament.install
      """)
    end
  end
end
```

**NOTE:** The `if Code.ensure_loaded?(Igniter)` pattern provides a graceful fallback when Igniter is not installed. The task compiles either way but prints a helpful message if Igniter is missing.

**IMPORTANT about Igniter API:** The exact Igniter API calls shown above are illustrative. Igniter's actual API may differ — the implementer MUST read `hexdocs.pm/igniter` to verify the correct function names and signatures. Key functions to look up:
- `Igniter.create_new_file/3`
- `Igniter.Project.Module.find_and_update_module!/3`
- `Igniter.Code.Common.add_code/2`
- `Igniter.copy_file/3` (may not exist — check if `create_new_file` with File.read! is better)
- `Igniter.update_file/3` (for non-Elixir files like JS)

The implementer should consult the Igniter docs and adapt the API calls accordingly.

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles (may warn about unused Igniter functions if Igniter not loaded — that's fine)

- [ ] **Step 3: Commit**

```
feat(installer): add mix phx_filament.install Igniter task
```

---

## Task 4: mix phx_filament.gen.resource

**Files:**
- Create: `lib/mix/tasks/phx_filament.gen.resource.ex`

- [ ] **Step 1: Create the resource generator task**

```elixir
# lib/mix/tasks/phx_filament.gen.resource.ex
defmodule Mix.Tasks.PhxFilament.Gen.Resource do
  @moduledoc """
  Generates a PhoenixFilament resource for an Ecto schema.

  ## Usage

      mix phx_filament.gen.resource MyApp.Blog.Post
      mix phx_filament.gen.resource MyApp.Blog.Post --repo MyApp.Repo.ReadOnly

  ## What it does

  1. Creates a Resource module at `lib/{app_web}/admin/{name}_resource.ex`
  2. Registers the resource in your Panel module's `resources do...end` block

  If the Panel module doesn't have a `resources` block yet, one is created.

  ## Options

  - `--repo` — Ecto Repo module to use. Auto-detected if not specified.
  """

  if Code.ensure_loaded?(Igniter) do
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_filament,
        example: "mix phx_filament.gen.resource MyApp.Blog.Post",
        positional: [:schema],
        schema: [repo: :string],
        aliases: [r: :repo]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      schema_string = igniter.args.positional.schema
      schema_module = Module.concat([schema_string])
      schema_name = schema_module |> Module.split() |> List.last()
      resource_name = Macro.underscore(schema_name) <> "_resource"

      app_name = Igniter.Project.Application.app_name(igniter)
      app_name_camel = app_name |> to_string() |> Macro.camelize()
      web_module = Module.concat([app_name_camel, "Web"])
      panel_module = Module.concat(web_module, "Admin")
      resource_module = Module.concat(panel_module, "#{schema_name}Resource")

      repo =
        case igniter.args.options[:repo] do
          nil -> detect_repo(app_name_camel)
          repo_string -> Module.concat([repo_string])
        end

      igniter
      |> create_resource_module(resource_module, schema_module, repo)
      |> register_in_panel(panel_module, resource_module)
    end

    defp create_resource_module(igniter, resource_module, schema_module, repo) do
      template_path = Application.app_dir(:phoenix_filament, "priv/templates/resource.ex.eex")

      resource_path =
        resource_module
        |> Module.split()
        |> Enum.map(&Macro.underscore/1)
        |> then(fn parts -> Path.join(["lib" | parts]) <> ".ex" end)

      contents =
        EEx.eval_file(template_path,
          assigns: [
            resource_module: inspect(resource_module),
            schema: inspect(schema_module),
            repo: inspect(repo)
          ]
        )

      Igniter.create_new_file(igniter, resource_path, contents)
    end

    defp register_in_panel(igniter, panel_module, resource_module) do
      # Patch the Panel module to add the resource in the resources block
      # This is the most complex Igniter operation — AST manipulation of DSL blocks
      # The implementer should consult Igniter docs for the best approach
      igniter
      |> Igniter.Project.Module.find_and_update_module!(panel_module, fn zipper ->
        # Add resource to resources block
        {:ok, Igniter.Code.Common.add_code(zipper, """
        resources do
          resource #{inspect(resource_module)},
            icon: "hero-document-text"
        end
        """)}
      end)
    end

    defp detect_repo(app_name_camel) do
      Module.concat([app_name_camel, "Repo"])
    end
  else
    use Mix.Task

    @shortdoc "Generates a PhoenixFilament resource (requires Igniter)"

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      PhoenixFilament resource generator requires Igniter.

      Add {:igniter, "~> 0.7"} to your deps in mix.exs and run:

          mix deps.get
          mix phx_filament.gen.resource MyApp.Blog.Post
      """)
    end
  end
end
```

**IMPORTANT:** The `register_in_panel` function needs careful Igniter AST work to:
1. Find the Panel module
2. Check if `resources do...end` block exists
3. If yes, add the new resource inside it
4. If no, create the block with the resource

The exact Igniter API for this may require `Igniter.Code.Function` or `Igniter.Code.Common` — the implementer MUST consult Igniter docs.

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Compiles

- [ ] **Step 3: Commit**

```
feat(installer): add mix phx_filament.gen.resource Igniter task
```

---

## Task 5: README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README**

```markdown
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
- Phoenix >= 1.7
- Phoenix LiveView >= 1.0
- Ecto >= 3.11

## License

MIT — see [LICENSE](LICENSE) for details.
```

- [ ] **Step 2: Create LICENSE file if not exists**

```
# LICENSE
MIT License

Copyright (c) 2026 Francisross Soares de Oliveira

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Commit**

```
docs: add README.md and LICENSE
```

---

## Task 6: Getting-Started Guide

**Files:**
- Create: `guides/getting-started.md`

- [ ] **Step 1: Write the complete getting-started guide**

This is a comprehensive tutorial (~800 lines) covering:

1. **Prerequisites** — Phoenix 1.8 app with Ecto schema
2. **Installation** — Add dep, mix deps.get, mix phx_filament.install
3. **First Resource** — mix phx_filament.gen.resource, visit /admin
4. **Customizing Forms** — form DSL: field types, sections, columns, visible_when
5. **Customizing Tables** — table DSL: columns, formatters, filters, actions, search, sort
6. **Dashboard Widgets** — StatsOverview, Chart (Chart.js), Table, Custom
7. **Theming** — daisyUI themes, per-panel theme, dark mode, theme_switcher
8. **Authentication** — on_mount hook, session revocation via PubSub
9. **Community Plugins** — registering plugins, creating your own
10. **Next Steps** — links to other guides, API docs

Each section includes complete code examples that build on the previous section.

The implementer should write this as a real Markdown file with proper headings, code blocks with `elixir` language tags, and clear step-by-step instructions. Use the existing module documentation in `lib/phoenix_filament/` as source material for accurate API examples.

- [ ] **Step 2: Verify guide renders**

Run: `mix docs`
Expected: Docs generated, getting-started.md appears in guides section

- [ ] **Step 3: Commit**

```
docs: add comprehensive getting-started guide
```

---

## Task 7: Additional Guide Pages

**Files:**
- Create: `guides/resources.md`
- Create: `guides/plugins.md`
- Create: `guides/theming.md`

- [ ] **Step 1: Write resources.md (~400 lines)**

Covers:
- Form DSL deep dive (all field types, sections, columns, visible_when)
- Table DSL deep dive (columns, formatters, filters, actions, search, pagination)
- Changeset integration (create_changeset, update_changeset)
- Authorization (authorize/3 callback, per-action checks)
- Resource options (label, plural_label, slug, icon)
- Show page rendering
- Page titles and breadcrumbs

Use code examples from the actual `PhoenixFilament.Resource` moduledoc and test files.

- [ ] **Step 2: Write plugins.md (~300 lines)**

Covers:
- Plugin behaviour overview (register/2, boot/1)
- use PhoenixFilament.Plugin macro
- Registering navigation items (nav_item/2)
- Adding custom routes (route/3)
- Dashboard widgets from plugins
- Lifecycle hooks (handle_event, handle_info, handle_params)
- Boot-time initialization
- Testing your plugin
- @experimental stability contract

Source material: `lib/phoenix_filament/plugin.ex` moduledoc.

- [ ] **Step 3: Write theming.md (~200 lines)**

Covers:
- daisyUI themes (data-theme attribute, 30+ built-in themes)
- Per-panel theme (theme: "corporate" in Panel options)
- Dark mode (auto via prefers-color-scheme, manual via theme_switcher: true)
- CSS variable overrides (colors, fonts, spacing)
- Custom theme creation

Source material: `lib/phoenix_filament/components/theme.ex`, Phase 2 CONTEXT.md.

- [ ] **Step 4: Verify all guides render**

Run: `mix docs`
Expected: All 4 guides appear in HexDocs output

- [ ] **Step 5: Commit**

```
docs: add resource, plugin, and theming guides
```

---

## Task 8: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `mix test`
Expected: All tests pass

- [ ] **Step 2: Compile check**

Run: `mix compile --warnings-as-errors`
Expected: Clean

- [ ] **Step 3: Generate docs**

Run: `mix docs`
Expected: Docs generated with all 4 guides, module groups, no warnings

- [ ] **Step 4: Verify Hex package contents**

Run: `mix hex.build --unpack`
Expected: Package contains lib/, priv/, guides/, mix.exs, README.md, LICENSE

- [ ] **Step 5: Verify file structure**

Run: `ls lib/mix/tasks/ && ls priv/templates/ && ls guides/`
Expected:
```
lib/mix/tasks/:
phx_filament.gen.resource.ex
phx_filament.install.ex

priv/templates/:
admin.ex.eex
resource.ex.eex

guides/:
getting-started.md
plugins.md
resources.md
theming.md
```

- [ ] **Step 6: Commit**

```
docs(08): complete Phase 8 — Distribution and Installer verified
```

---

*Plan: 08-distribution-and-installer*
*Created: 2026-04-03*
*Tasks: 8*

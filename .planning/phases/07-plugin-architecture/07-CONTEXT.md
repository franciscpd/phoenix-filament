# Phase 7: Plugin Architecture - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A formal `PhoenixFilament.Plugin` behaviour contract that the framework and third-party authors use as the same extension API. Plugins declare navigation items, custom routes, dashboard widgets, and lifecycle hooks via `register/2`. Plugins initialize at runtime via optional `boot/1`. The built-in Resource and Widget systems are refactored into implicit plugins (ResourcePlugin, WidgetPlugin) that use the public Plugin behaviour — proving the contract with zero internal bypass APIs. Plugins are resolved per panel at compile time (`__before_compile__`) and booted at runtime per socket mount — adding/removing a plugin module and restarting never triggers framework recompilation.

</domain>

<decisions>
## Implementation Decisions

### Plugin Behaviour Contract
- **D-01:** Two callbacks — `register/2` (required) returns metadata map, `boot/1` (optional) receives socket and returns socket. Separation of declaration vs runtime.
- **D-02:** `register/2` signature — `register(panel :: module(), opts :: keyword()) :: map()`. Receives the panel module and per-plugin options from the `plugins do...end` DSL.
- **D-03:** `boot/1` returns Socket directly — `boot(socket :: Socket.t()) :: Socket.t()`. No `{:halt, redirect}` — plugins cannot block mount. Auth is Panel's responsibility, not plugins'.
- **D-04:** `boot/1` is `@optional_callbacks [boot: 1]` — plugins that only register metadata don't need boot.
- **D-05:** Register return map has optional keys with defaults — Plugin returns only the keys it uses. Framework merges with `%{nav_items: [], routes: [], widgets: [], hooks: []}`.
- **D-06:** Register return structure:
  - `:nav_items` — list of `%{label, path, icon, nav_group}` for sidebar entries
  - `:routes` — list of `%{path, live_view, live_action}` for custom live routes
  - `:widgets` — list of `%{module, sort, column_span}` for dashboard widgets
  - `:hooks` — list of `{stage, fun}` tuples for lifecycle hooks (`{:handle_event, &fun/3}`, `{:handle_info, &fun/2}`, `{:handle_params, &fun/3}`, `{:after_render, &fun/1}`)
- **D-07:** Hooks are automatically attached via `attach_hook/4` by Panel.Hook — plugin does not call `attach_hook` directly.

### Plugin Registration in Panel
- **D-08:** DSL block `plugins do...end` in Panel — alongside existing `resources do...end` and `widgets do...end`. Community plugins registered explicitly.
- **D-09:** Plugins accept keyword list options — `plugin MyPlugin, option: value`. Options passed as second arg to `register/2`.
- **D-10:** Declaration order determines priority — Built-in plugins (Resource, Widget) always first. Community plugins in declaration order. Nav items and hooks follow this ordering.

### Built-in Plugins (Internals-as-Plugins)
- **D-11:** ResourcePlugin implicit — When `resources do...end` block exists, Panel automatically creates and registers a `PhoenixFilament.Plugins.ResourcePlugin` with the declared resources. Developer API unchanged.
- **D-12:** WidgetPlugin implicit — When `widgets do...end` block exists, Panel automatically registers a `PhoenixFilament.Plugins.WidgetPlugin`. Developer API unchanged.
- **D-13:** Unified plugin registry — Panel's `__before_compile__` resolves ALL plugins (built-in + community), calls `register/2` on each, and merges results into unified lists:
  - `__panel__(:all_nav_items)` — merged from all plugins
  - `__panel__(:all_routes)` — merged from all plugins
  - `__panel__(:all_widgets)` — merged from all plugins
  - `__panel__(:all_hooks)` — merged from all plugins
  - `__panel__(:plugins)` — raw plugin list with modules + opts
- **D-14:** Router reads `:all_routes` — Panel.Router generates live routes from the unified route list, not from resources directly.
- **D-15:** Hook reads `:all_nav_items` and `:all_hooks` — Navigation.build_tree uses the unified nav items list. Lifecycle hooks from all plugins are attached.
- **D-16:** Dashboard reads `:all_widgets` — Dashboard widget grid uses the unified widget list.

### Plugin Developer Experience
- **D-17:** `use PhoenixFilament.Plugin` macro — Injects `@behaviour PhoenixFilament.Plugin` + helper functions: `nav_item/2`, `route/3`. Reduces boilerplate. Developer can also use bare `@behaviour` if preferred.
- **D-18:** @experimental stability contract — Plugin API marked `@experimental` in v0.1. Breaking changes allowed in minor versions. Documentation states: "Pin your phoenix_filament dependency to a specific version when using plugins."
- **D-19:** Comprehensive @moduledoc guide — Quick start, registering nav items, adding custom routes, dashboard widgets, lifecycle hooks, boot-time initialization, testing plugins, @optional_callbacks reference. Also generates HexDocs guide page.

### Claude's Discretion
- Exact struct types for nav_item, route, widget registration
- How `__before_compile__` merges plugin results (implementation detail)
- How ResourcePlugin and WidgetPlugin translate existing DSL data into plugin register() returns
- Helper function implementations (nav_item/2, route/3)
- Test strategy for plugin resolution and boot lifecycle
- How to refactor Panel.Router and Panel.Hook to read unified lists instead of direct resource/widget lists (backward-compatible transition)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints
- `.planning/REQUIREMENTS.md` — PLUG-01 through PLUG-06
- `.planning/ROADMAP.md` §Phase 7 — Goal, success criteria

### Phase 6 Panel (direct dependency)
- `.planning/phases/06-panel-shell-and-auth-hook/06-CONTEXT.md` — Panel DSL (D-01 to D-22), Router, Hook, Navigation, Layout
- `lib/phoenix_filament/panel.ex` — Panel `__using__` macro, `__panel__/1` accessors, `__before_compile__`
- `lib/phoenix_filament/panel/dsl.ex` — Current resources/widgets DSL macros
- `lib/phoenix_filament/panel/router.ex` — Router macro reads `__panel__(:resources)` — must change to `__panel__(:all_routes)`
- `lib/phoenix_filament/panel/hook.ex` — Hook reads `__panel__(:resources)` for nav — must change to `__panel__(:all_nav_items)`
- `lib/phoenix_filament/panel/navigation.ex` — `build_tree/3` receives resource list — must accept unified nav_items
- `lib/phoenix_filament/panel/dashboard.ex` — Dashboard reads `__panel__(:widgets)` — must change to `__panel__(:all_widgets)`

### Phase 1 Foundation (compile-time safety)
- `.planning/phases/01-foundation/01-CONTEXT.md` — `Macro.expand_literals/2`, compile cascade prevention
- `test/phoenix_filament/resource/cascade_test.exs` — Cascade test pattern to follow

### Technology References
- `CLAUDE.md` §Technology Stack — Phoenix LiveView 1.1, `attach_hook/4` API

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Panel` — `__using__/1`, `__before_compile__/1`, `__panel__/1` — extend with plugin resolution
- `PhoenixFilament.Panel.DSL` — `resources/1`, `widgets/1` macros — add `plugins/1`, `plugin/2` macros
- `PhoenixFilament.Panel.Hook` — `on_mount/4` — extend to boot plugins and attach plugin hooks
- `PhoenixFilament.Panel.Navigation` — `build_tree/3` — already accepts list of nav items, just change input source
- `PhoenixFilament.Panel.Router` — route generation loop — extend to include plugin routes

### Established Patterns
- Module attribute accumulation for DSL → structs (same pattern for plugins)
- NimbleOptions for option validation (can use for plugin registration validation)
- `Macro.expand_literals/2` for compile-time safety
- `__before_compile__` for generating accessor functions

### Integration Points
- Panel `__before_compile__` — where plugin resolution happens (call register/2 on each plugin, merge results)
- Panel.Hook `on_mount` — where plugin boot/1 calls happen (after panel assigns, before user code)
- Panel.Router macro — reads unified route list instead of direct resource list
- Panel.Dashboard mount — reads unified widget list

</code_context>

<specifics>
## Specific Ideas

- `resources do...end` and `widgets do...end` keep working exactly as before — the refactor is internal
- ResourcePlugin and WidgetPlugin prove the Plugin API works by being the first consumers
- Community plugins get the same capabilities as built-in plugins — no privileged internal APIs
- The `register/2` receiving panel module allows plugins to introspect panel config if needed
- Hooks in plugins use the same `attach_hook` mechanism Panel.Hook already uses

</specifics>

<deferred>
## Deferred Ideas

- Plugin dependency resolution (plugin A requires plugin B) — v0.2
- Plugin configuration validation via NimbleOptions per plugin — v0.2
- Plugin hot-reload without app restart — v0.2
- Plugin marketplace / registry — v1.0+
- Plugin middleware pipeline (before/after hooks per plugin) — v0.2
- Plugin asset bundling (JS/CSS from plugins) — v0.2

</deferred>

---

*Phase: 07-plugin-architecture*
*Context gathered: 2026-04-03*

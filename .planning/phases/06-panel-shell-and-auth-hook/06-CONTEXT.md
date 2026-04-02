# Phase 6: Panel Shell and Auth Hook - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Developers can wrap resources in an admin panel shell by declaring `use PhoenixFilament.Panel` with a `resources do...end` DSL block and adding `phoenix_filament_panel "/admin", MyApp.Admin` to their router. The panel renders a sidebar with grouped resource navigation, breadcrumbs, a top bar with brand name/logo, flash toast notifications, and a responsive daisyUI drawer layout. Authentication is delegated to the host app via configurable `plug` + `on_mount` hook — the panel never provides auth. A dashboard landing page with 4 widget types (stat, table, chart, custom) is included with a grid layout system.

</domain>

<decisions>
## Implementation Decisions

### Panel Declaration and Resource Registration
- **D-01:** DSL block syntax — `use PhoenixFilament.Panel` + `resources do...end` block listing resource modules with per-resource options (icon, nav_group, slug). Follows Phoenix Router DSL conventions.
- **D-02:** Router macro generates live routes — `phoenix_filament_panel "/admin", MyApp.Admin` in the router auto-generates all `live` routes for each registered resource (index, new, show, edit) plus the dashboard route. Zero manual route declarations.
- **D-03:** Nav group support — Resources with `nav_group: "Blog"` appear grouped under a heading in the sidebar. Without nav_group, they appear at top level. Order follows declaration order in the `resources` block.
- **D-04:** Multiple panels supported — Each panel is a separate module with its own resources, theme, and auth hook. Multiple `phoenix_filament_panel` calls in the router. Isolated from each other.
- **D-05:** Auto-derived slugs with override — Resource slug auto-derived from schema name (Post → `/posts`). Override with `slug: "team-members"` in the resource declaration.
- **D-06:** Essential panel options — `path`, `on_mount`, `plug`, `brand_name`, `logo` (URL string), `theme` (daisyUI theme name), `theme_switcher` (boolean). Footer and advanced customizations deferred to v0.2.

### Layout Shell Architecture
- **D-07:** LiveView layout via on_mount — Panel generates a `live_session` with the developer's `on_mount` and a panel layout. The `on_mount` hook injects panel assigns (resources, brand, theme) into the socket. Resources render inside `@inner_content` of the layout.
- **D-08:** daisyUI drawer for sidebar — Uses daisyUI `drawer` + `drawer-open` pattern. Desktop: sidebar permanently visible. Mobile: hamburger toggle with overlay. Zero custom JS — LiveView.JS toggle only.
- **D-09:** Auto-generated breadcrumbs — Computed from panel brand → resource plural_label → action (New/Edit/Show). Uses label/plural_label from Resource options (Phase 5 D-10/D-11). Override possible via callback in future versions.
- **D-10:** Toast flash notifications — Flash messages render as daisyUI `toast` in bottom-right corner. `alert-success` and `alert-error` variants. Auto-dismiss after ~5s via LiveView.JS transition. Position fixed, doesn't interfere with layout.
- **D-11:** Heroicons with escape hatch — Default icon format is hero-* strings (Phoenix standard). Resources without icon show first letter of label as fallback.

### Auth Hook and Session Management
- **D-12:** Belt and suspenders auth — Panel accepts both `plug` and `on_mount` in configuration. Plug protects the initial HTTP request. on_mount protects LiveView mount and reconnects. Panel injects plug into the generated scope and on_mount into the live_session.
- **D-13:** PubSub broadcast for session revocation — Panel subscribes to `"user_sessions:{user_id}"` topic on mount. When session is revoked, host app broadcasts `:session_revoked`. Panel's handle_info catches it and redirects to login.
- **D-14:** Helper function for revocation — `PhoenixFilament.Panel.revoke_sessions(pubsub, user_id)` does the broadcast. Panel auto-subscribes on mount. Developer configures `pubsub: MyApp.PubSub` on the Panel.
- **D-15:** on_mount optional with warning — Panel works without auth (useful for dev/prototyping). Logs compile-time warning when on_mount is not configured: "Panel :admin has no on_mount configured."
- **D-16:** current_user from socket assigns — Panel reads `socket.assigns.current_user` set by the developer's on_mount hook. Panel never sets or validates current_user itself.

### Dashboard and Widgets
- **D-17:** Four widget types — StatsOverview (cards with label/value/description/icon/color/sparkline), Table (reuses Table Builder), Chart (Chart.js via LiveView colocated JS hook), Custom (free-form LiveComponent).
- **D-18:** Widgets as separate modules — Each widget is a module using `use PhoenixFilament.Widget.StatsOverview`, `use PhoenixFilament.Widget.Chart`, `use PhoenixFilament.Widget.Table`, or `use PhoenixFilament.Widget.Custom`. Registered in Panel via `widgets do...end` block.
- **D-19:** Chart.js via colocated JS hook — Chart widget renders a `<canvas>` with `phx-hook="ChartWidget"`. Data passed as JSON from server. Supports line, bar, pie chart types via `chart_type/0` callback. Chart.js bundled as a dependency.
- **D-20:** Grid 12-column layout — Dashboard uses a 12-column Tailwind grid. Widgets declare `column_span: 6` (half), `12` or `:full`. Responsive by breakpoint. `sort` option controls widget ordering.
- **D-21:** Configurable polling — Widgets can declare `@polling_interval :timer.seconds(10)` for live auto-refresh. Default: no polling. Uses `Process.send_after` for periodic re-render.
- **D-22:** Custom dashboard LiveView override — Developer can pass `dashboard: MyApp.Admin.DashboardLive` to Panel for full control. Custom LiveView renders inside the panel shell (sidebar/topbar stay intact). Default: auto-generated dashboard with registered widgets.

### Claude's Discretion
- Internal implementation of the router macro (how it expands to `live` calls inside a `live_session`)
- Panel hook module structure (how assigns are injected)
- Widget LiveComponent implementation details (state management, render cycle)
- Chart.js hook implementation specifics
- Exact Tailwind classes for layout, sidebar nav items, breadcrumb styling
- How panel metadata is stored and accessed at runtime (ETS, module attributes, etc.)
- Flash auto-dismiss timing and animation approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — PANEL-01 through PANEL-08
- `.planning/ROADMAP.md` §Phase 6 — Goal, success criteria

### Phase 5 Resource Abstraction (direct dependency)
- `.planning/phases/05-resource-abstraction/05-CONTEXT.md` — Resource IS the LiveView (D-01), live_action pattern (D-02), routes (D-04), current_user from assigns (D-09), labels/breadcrumbs auto-derived (D-10/D-11)
- `lib/phoenix_filament/resource.ex` — Resource `__using__` macro, LiveView callback injection, `__resource__/1` accessors

### Phase 2 Component Library and Theming (dependency)
- `.planning/phases/02-component-library-and-theming/02-CONTEXT.md` — daisyUI theme palette (D-07), per-panel theme (D-08), dark mode toggle (D-09), modal portals (D-12)

### Phase 1 Foundation (dependency)
- `.planning/phases/01-foundation/01-CONTEXT.md` — Flat-by-domain namespace `panel/` (D-05), compile-time safety patterns

### Phase 4 Table Builder (dependency for table widget)
- `.planning/phases/04-table-builder/04-CONTEXT.md` — TableLive API
- `lib/phoenix_filament/table/table_live.ex` — TableLive LiveComponent

### Technology References
- `CLAUDE.md` §Technology Stack — Phoenix LiveView 1.1 (colocated JS hooks), daisyUI 5, Tailwind v4
- FilamentPHP dashboard/widget docs — https://filamentphp.com/docs/3.x/panels/dashboard (reference architecture)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Resource` — Already a LiveView with mount/handle_params/render. Panel layout wraps this via live_session layout.
- `PhoenixFilament.Resource.Options` — NimbleOptions schema. Panel will need its own NimbleOptions for panel-level config.
- `PhoenixFilament.Resource.Lifecycle` — init_assigns, apply_action patterns. Panel hook will follow similar assign-injection pattern.
- `PhoenixFilament.Table.TableLive` — LiveComponent for tables. Reused directly by Table widget on dashboard.
- `PhoenixFilament.Components.Modal` — Modal component. Potentially used for dashboard filter modal.
- `PhoenixFilament.Components` — All UI primitives (buttons, badges, inputs) available for dashboard widgets.

### Established Patterns
- `Macro.expand_literals/2` for compile-time safety (Phase 1) — Panel macro must follow same pattern
- Module attribute accumulation for DSL → structs — Panel `resources do...end` will use same pattern
- NimbleOptions for option validation — Panel options validated same way as Resource options
- LiveComponent for stateful UI (TableLive) — Widgets will be LiveComponents following same pattern
- `send(self(), {:table_action, type, id})` for event delegation — Widgets may use similar message passing

### Integration Points
- Router — Panel macro generates `live_session` + `live` routes in the Phoenix router
- on_mount — Panel hook injected via `live_session` on_mount list
- Layout — Panel layout rendered via `live_session` layout option
- Resource — Resources render inside panel layout's `@inner_content`
- PubSub — Session revocation broadcasts via Phoenix.PubSub (host app's PubSub module)

</code_context>

<specifics>
## Specific Ideas

- Follow FilamentPHP's widget architecture closely — 4 widget types, module-per-widget, grid layout, polling
- daisyUI drawer gives responsive sidebar for free — no custom CSS needed
- Chart.js via LiveView 1.1 colocated hooks is the cleanest integration path
- Multiple panels from day one forces clean isolation architecture
- Belt and suspenders auth (plug + on_mount) is the most robust pattern for Phoenix LiveView apps

</specifics>

<deferred>
## Deferred Ideas

- Widget dashboard filters (global date range form filtering all widgets) — v0.2
- Widget lazy loading — v0.2
- Sidebar collapse/expand state persistence — v0.2
- User menu dropdown in topbar — v0.2
- Footer customization — v0.2
- Custom pages per panel (non-resource pages) — v0.2
- Widget header/footer on Resource list pages — v0.2
- Breadcrumb override callback — v0.2

</deferred>

---

*Phase: 06-panel-shell-and-auth-hook*
*Context gathered: 2026-04-02*

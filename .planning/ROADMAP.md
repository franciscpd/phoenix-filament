# Roadmap: PhoenixFilament

## Overview

PhoenixFilament is built bottom-up following a strict dependency-driven layer order. Foundation provides Ecto introspection and config primitives consumed by all upper layers. Component Library and Theming establish every UI primitive and the CSS variable theming system. Form Builder and Table Builder are then built as fully standalone, independently testable subsystems. Resource binds both together against an Ecto schema to generate CRUD pages. Panel adds routing, navigation, and the auth hook to make resources accessible as a coherent admin UI. Plugin Architecture formalizes the extension API and registers the built-in Resource system as a first-class plugin, proving the API before external authors use it. Distribution closes the loop with the Igniter-based installer and Hex publication, so a developer can go from `mix phx.new` to a working admin panel with a single command.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Hex package scaffold, Ecto introspection helpers, runtime DSL infrastructure, and compile-time safety patterns
- [ ] **Phase 2: Component Library and Theming** - All LiveView UI primitives (inputs, buttons, badges, modals, cards) styled with daisyUI 5 and Tailwind v4 CSS variable theming
- [ ] **Phase 3: Form Builder** - Standalone declarative form DSL with plain field structs, Ecto changeset integration, real-time validation, and conditional visibility
- [ ] **Phase 4: Table Builder** - Standalone declarative table DSL with LiveView streams, server-side sort/pagination/search/filters, and URL-persisted state
- [ ] **Phase 5: Resource Abstraction** - `use PhoenixFilament.Resource` macro binding Form and Table to an Ecto schema with auto-generated CRUD pages and thin event delegation
- [ ] **Phase 6: Panel Shell and Auth Hook** - Admin panel routing macro, sidebar navigation, breadcrumbs, responsive layout, BYO auth hook, and flash notifications
- [ ] **Phase 7: Plugin Architecture** - Runtime plugin behaviour contract, per-panel plugin registry, built-in Resource system registered as a plugin, and plugin developer guide
- [ ] **Phase 8: Distribution and Installer** - Hex package publication, `mix phx_filament.install` Igniter generator, and getting-started documentation

## Phase Details

### Phase 1: Foundation
**Goal**: The Hex package is scaffolded with a correct supervision tree, and the runtime DSL infrastructure is in place — Ecto schema introspection, config reading, and compile-time delegation patterns — so every upper layer has stable primitives to build on.
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04
**Success Criteria** (what must be TRUE):
  1. The package compiles as a dependency in a blank `mix phx.new` app with no warnings
  2. `PhoenixFilament.Schema.fields/1` returns typed field metadata from any Ecto schema module at runtime without triggering recompilation of the caller
  3. `use PhoenixFilament.Resource` injects the DSL macro blocks without causing compile-time cascades when the referenced schema changes (validated by touching the schema and observing no dependent module recompiles)
  4. Field and column definitions are plain structs (not macro-generated artifacts) and can be inspected in IEx at runtime
**Plans**: TBD

### Phase 2: Component Library and Theming
**Goal**: Every UI primitive required by Form Builder, Table Builder, and Panel exists as a stateless LiveView function component, styled with daisyUI 5 semantic classes and a Tailwind v4 CSS variable theme that can be overridden per-panel.
**Depends on**: Phase 1
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04, COMP-05, COMP-06, COMP-07, COMP-08, COMP-09, COMP-10, COMP-11, COMP-12, THEME-01, THEME-02, THEME-03, THEME-04
**Success Criteria** (what must be TRUE):
  1. A developer can render any component (text input, select, checkbox, date picker, button, badge, modal, card) in a plain LiveView with no PhoenixFilament panel configured
  2. The default theme produces a professional appearance using daisyUI 5 out of the box with no additional CSS
  3. Switching to dark mode applies automatically via CSS variables without any JavaScript or LiveView round-trip
  4. A developer can override brand colors and fonts by setting CSS variables in their host app stylesheet without touching framework source
  5. No Tailwind class names are constructed via string interpolation anywhere in the component library (safeguarding against Tailwind purging)
**Plans**: TBD
**UI hint**: yes

### Phase 3: Form Builder
**Goal**: Developers can define forms declaratively using a `form do ... end` DSL block where field types are plain data structs. Forms integrate with Ecto changesets, display inline field-level errors, support real-time validation, conditional field visibility, and layout sections — all as a standalone subsystem with no Panel dependency.
**Depends on**: Phase 2
**Requirements**: FORM-01, FORM-02, FORM-03, FORM-04, FORM-05, FORM-06, FORM-07
**Success Criteria** (what must be TRUE):
  1. A developer can render a working form in a plain LiveView by defining a `form do ... end` block and passing a changeset — no admin panel or resource module needed
  2. Submitting the form calls the declared changeset function and renders field-level error messages inline beneath the relevant inputs
  3. Separate `create_changeset` and `update_changeset` functions can be declared and the correct one is called based on whether the record is new or existing
  4. Typing in a field and moving focus triggers live validation and shows errors without a page reload
  5. A field with `visible_when` set shows or hides instantly when the controlling field value changes, without a server round-trip
**Plans**: TBD
**UI hint**: yes

### Phase 4: Table Builder
**Goal**: Developers can define tables declaratively using a `table do ... end` DSL block where columns are plain data structs. Tables render using LiveView streams, support server-side sort, pagination, global text search, and typed filters, and preserve all state in URL params — all as a standalone subsystem with no Panel dependency.
**Depends on**: Phase 2
**Requirements**: TABLE-01, TABLE-02, TABLE-03, TABLE-04, TABLE-05, TABLE-06, TABLE-07, TABLE-08, TABLE-09, TABLE-10
**Success Criteria** (what must be TRUE):
  1. A developer can render a working paginated table in a plain LiveView by defining a `table do ... end` block and pointing it at an Ecto repo — no admin panel or resource module needed
  2. Clicking a sortable column header re-orders the table and a sort indicator appears; clicking again reverses the order
  3. Typing in the search box filters results server-side and the URL updates to reflect the current search term, which persists across page reloads
  4. Applying a select filter or boolean filter narrows results and the active filter state is reflected in the URL
  5. Row action buttons (view, edit, delete) appear per row; delete triggers a confirmation dialog before the record is removed
  6. Loading 10,000 records does not cause memory growth in the LiveView process because rows are rendered via streams and never held in full in socket assigns
**Plans**: TBD
**UI hint**: yes

### Phase 5: Resource Abstraction
**Goal**: Developers can generate a fully functional CRUD admin resource from an Ecto schema by writing a single module with `use PhoenixFilament.Resource`. The resource auto-discovers schema fields, generates sensible defaults for form and table, allows full DSL customization, provides standard CRUD operations against an Ecto repo, and delegates all LiveView event handling through thin delegation to avoid compile-time cascades.
**Depends on**: Phase 3, Phase 4
**Requirements**: RES-01, RES-02, RES-03, RES-04, RES-05, RES-06
**Success Criteria** (what must be TRUE):
  1. Writing `use PhoenixFilament.Resource, schema: MyApp.Blog.Post, repo: MyApp.Repo` in an empty module generates working index, create, edit, and show pages with no additional code
  2. The auto-generated form and table show all Ecto schema fields with sensible input types inferred from field types (string → text input, boolean → checkbox, etc.)
  3. A developer can override any column or field by adding a `form do ... end` or `table do ... end` block to the resource module, with the custom definition replacing the auto-generated default
  4. Touching the Ecto schema file does not trigger recompilation of any resource module that uses it (validated by observing Mix compile output)
  5. Every `handle_event` callback in the generated CRUD pages calls `authorize!/3` before performing a write operation, not only at LiveView mount
  6. The delete confirmation dialog appears before any record is destroyed
**Plans**: TBD

### Phase 6: Panel Shell and Auth Hook
**Goal**: Developers can wrap resources in an admin panel shell by declaring `use PhoenixFilament.Panel` and adding a `phoenix_filament_panel` router scope. The panel renders a sidebar with resource navigation, breadcrumbs, a top bar, flash notifications, and a responsive layout. Authentication is delegated to the host app via a configurable `on_mount` hook — the panel never provides auth.
**Depends on**: Phase 5
**Requirements**: PANEL-01, PANEL-02, PANEL-03, PANEL-04, PANEL-05, PANEL-06, PANEL-07, PANEL-08
**Success Criteria** (what must be TRUE):
  1. Adding `phoenix_filament_panel "/admin"` to a Phoenix router and defining a panel module with one resource registers live routes for that resource's CRUD pages with no manual route declarations
  2. The sidebar lists all registered resources with their labels and icons; the active resource link is visually highlighted
  3. Configuring `on_mount: {MyApp.Auth, :require_admin}` on the panel causes unauthenticated requests to be redirected to the host app's login page without any PhoenixFilament auth code
  4. Revoking a user's admin session broadcasts a disconnect to their live socket, terminating active admin sessions in real time
  5. The sidebar collapses to a hamburger menu on mobile viewports without any JavaScript beyond LiveView's built-in JS commands
  6. Flash success and error messages appear after every CRUD operation and dismiss automatically
**Plans**: TBD
**UI hint**: yes

### Phase 7: Plugin Architecture
**Goal**: A formal plugin behaviour contract exists so that the framework itself and third-party authors use the same extension API. The built-in Resource system is registered as a plugin, proving the contract. Plugins are resolved at runtime per socket mount — not at compile time — so adding or removing plugins never triggers framework recompilation.
**Depends on**: Phase 6
**Requirements**: PLUG-01, PLUG-02, PLUG-03, PLUG-04, PLUG-05, PLUG-06
**Success Criteria** (what must be TRUE):
  1. A developer can create a community plugin module implementing `PhoenixFilament.Plugin` behaviour and register it in a panel declaration without modifying any framework source
  2. The built-in resource system is implemented entirely using the public `PhoenixFilament.Plugin` behaviour — no internal bypass APIs
  3. Adding or removing a plugin module and restarting the app does not trigger recompilation of any framework module
  4. A plugin can register navigation items, custom routes, and custom components that appear in the panel alongside built-in resources
  5. The plugin developer guide documents all `@optional_callbacks` and marks the plugin API as `@experimental` with a clear stability contract
**Plans**: TBD

### Phase 8: Distribution and Installer
**Goal**: PhoenixFilament is published on Hex and a developer can go from a blank `mix phx.new` app to a working admin panel by running `mix phx_filament.install` with zero manual file edits. Getting-started documentation guides the complete flow.
**Depends on**: Phase 7
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04
**Success Criteria** (what must be TRUE):
  1. `mix phx_filament.install` on a blank `mix phx.new` app patches `router.ex`, imports required CSS/JS, and creates an initial panel module — the resulting app compiles and renders the admin panel without any manual edits
  2. Running the installer twice on the same app is idempotent — no duplicate imports, routes, or modules are created
  3. The package is available on hex.pm as `phoenix_filament` and `mix deps.get` resolves it in a fresh project
  4. Following the getting-started documentation from "installation" through "first resource" produces a working admin page for a user-defined Ecto schema
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/TBD | Not started | - |
| 2. Component Library and Theming | 0/TBD | Not started | - |
| 3. Form Builder | 0/TBD | Not started | - |
| 4. Table Builder | 0/TBD | Not started | - |
| 5. Resource Abstraction | 0/TBD | Not started | - |
| 6. Panel Shell and Auth Hook | 0/TBD | Not started | - |
| 7. Plugin Architecture | 0/TBD | Not started | - |
| 8. Distribution and Installer | 0/TBD | Not started | - |

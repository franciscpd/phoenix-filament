# Requirements: PhoenixFilament

**Defined:** 2026-03-31
**Core Value:** Developers can go from an Ecto schema to a fully functional, beautiful admin interface in minutes — with a declarative, idiomatic Elixir API that feels native to the Phoenix ecosystem.

## v1 Requirements

Requirements for v0.1.0 release. Each maps to roadmap phases.

### Foundation

- [ ] **FOUND-01**: Mix project structured as a proper Hex package with correct supervision tree
- [ ] **FOUND-02**: Core macro framework provides `use PhoenixFilament.Resource` with declarative DSL blocks (form, table)
- [ ] **FOUND-03**: Field/column definitions are plain data structs evaluated at runtime (not compile-time macros)
- [ ] **FOUND-04**: Macro delegation pattern prevents compile-time dependency cascades (thin delegation via `Macro.expand_literals/2`)

### Component Library

- [ ] **COMP-01**: Text input component with label, placeholder, error display, and disabled state
- [ ] **COMP-02**: Textarea component with configurable rows
- [ ] **COMP-03**: Number input component with min/max/step support
- [ ] **COMP-04**: Select component with static options and association-backed options
- [ ] **COMP-05**: Checkbox/toggle component for boolean fields
- [ ] **COMP-06**: Date and datetime picker components
- [ ] **COMP-07**: Hidden field component
- [ ] **COMP-08**: Button component with variants (primary, secondary, danger) and loading state
- [ ] **COMP-09**: Badge component with color variants
- [ ] **COMP-10**: Modal component using LiveView portals for proper z-index/overflow handling
- [ ] **COMP-11**: Card component for content grouping
- [ ] **COMP-12**: All components styled with Tailwind CSS v4 using CSS variable theming (no Tailwind class interpolation)

### Theming

- [ ] **THEME-01**: Default theme with professional appearance (leveraging daisyUI 5 + Tailwind v4)
- [ ] **THEME-02**: Theme customization via CSS variables (colors, fonts, spacing)
- [ ] **THEME-03**: Light and dark mode support via CSS variables
- [ ] **THEME-04**: Theme can be configured per-panel

### Form Builder

- [ ] **FORM-01**: Declarative form definition via `form do ... end` DSL block
- [ ] **FORM-02**: Form renders fields based on field type definitions (text_input, select, checkbox, etc.)
- [ ] **FORM-03**: Full Ecto changeset integration — form submits through changeset, displays field-level errors inline
- [ ] **FORM-04**: Support for separate create and update changeset functions
- [ ] **FORM-05**: Form layout support (sections, columns/grid)
- [ ] **FORM-06**: LiveView real-time validation on blur/change
- [ ] **FORM-07**: Field visibility can be conditional (show/hide based on other field values)

### Table Builder

- [ ] **TABLE-01**: Declarative table definition via `table do ... end` DSL block
- [ ] **TABLE-02**: Configurable columns with label, formatting callback, and show/hide
- [ ] **TABLE-03**: Server-side sorting (click column headers, default sort configurable)
- [ ] **TABLE-04**: Server-side pagination with configurable page sizes (25/50/100)
- [ ] **TABLE-05**: Global text search across configurable fields
- [ ] **TABLE-06**: Empty state display when no records match
- [ ] **TABLE-07**: Table uses LiveView streams for memory-efficient rendering
- [ ] **TABLE-08**: Row actions (view, edit, delete) with confirmation for destructive actions
- [ ] **TABLE-09**: Table filters (select filter, boolean filter, date range filter)
- [ ] **TABLE-10**: Filter and pagination state preserved in URL params

### Resource

- [ ] **RES-01**: `use PhoenixFilament.Resource` generates index, create, edit, and show pages from Ecto schema
- [ ] **RES-02**: Resource auto-discovers schema fields and generates sensible defaults for form and table
- [ ] **RES-03**: Resource allows full customization of form and table definitions via DSL
- [ ] **RES-04**: Resource provides standard CRUD operations (list, get, create, update, delete) with Ecto repo integration
- [ ] **RES-05**: Resource supports custom page titles, breadcrumbs, and navigation labels
- [ ] **RES-06**: Delete action includes confirmation dialog

### Panel

- [ ] **PANEL-01**: Admin panel shell with sidebar navigation, top bar, and content area
- [ ] **PANEL-02**: Sidebar shows registered resources with icons and labels, with active state highlighting
- [ ] **PANEL-03**: BYO authentication via configurable `on_mount` hook — panel checks auth, does not provide it
- [ ] **PANEL-04**: Dashboard page as panel landing page with customizable layout
- [ ] **PANEL-05**: Flash notifications for CRUD operations (success, error messages)
- [ ] **PANEL-06**: Responsive layout — sidebar collapses on mobile
- [ ] **PANEL-07**: Panel defined via router macro (`phoenix_filament_panel`) inside a scope
- [ ] **PANEL-08**: Breadcrumb navigation on all pages

### Plugin Architecture

- [ ] **PLUG-01**: Plugin behaviour with `register/1` and `boot/1` callbacks
- [ ] **PLUG-02**: Plugin registration system per panel (each panel declares its plugins)
- [ ] **PLUG-03**: Plugins resolved at runtime (on_mount), not compile-time — avoids recompilation cascades
- [ ] **PLUG-04**: Built-in Resource system registered as a plugin (internals-as-plugins pattern)
- [ ] **PLUG-05**: Plugin can register navigation items, routes, and components
- [ ] **PLUG-06**: Plugin developer documentation with guide on creating community plugins

### Distribution

- [ ] **DIST-01**: Published as Hex package (`phoenix_filament`)
- [ ] **DIST-02**: `mix phx_filament.install` generator using Igniter for automated setup
- [ ] **DIST-03**: Installer configures router, adds CSS/JS dependencies, creates initial admin panel module
- [ ] **DIST-04**: Getting started documentation (installation, first resource, customization)

## v2 Requirements

Deferred to future releases. Tracked but not in current roadmap.

### Advanced Fields

- **AFIELD-01**: File upload / image upload field
- **AFIELD-02**: Rich text / Markdown editor field
- **AFIELD-03**: Repeater field (nested collections)
- **AFIELD-04**: Color picker field
- **AFIELD-05**: Tags input field
- **AFIELD-06**: Key-value pairs field

### Advanced Features

- **AFEAT-01**: Association/relation fields (belongs_to, has_many inline editing)
- **AFEAT-02**: Relation managers (manage related records from parent resource)
- **AFEAT-03**: Bulk actions on table rows
- **AFEAT-04**: Global search across all resources
- **AFEAT-05**: Dashboard widgets (stats, charts, recent activity)
- **AFEAT-06**: Infolists (read-only detail view builder)
- **AFEAT-07**: Notification system (in-app notifications)
- **AFEAT-08**: Navigation groups (collapsible sidebar sections)
- **AFEAT-09**: Basic authorization (policy-based access control per resource)
- **AFEAT-10**: Export to CSV/Excel

### Infrastructure

- **INFRA-01**: Multi-tenancy support
- **INFRA-02**: Localization/i18n support
- **INFRA-03**: Activity log / audit trail

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Built-in authentication | Users bring their own auth — avoids ecosystem conflict |
| Dead view support | 100% LiveView — simplifies architecture, enables real-time features |
| Multi-tenancy | Extremely high complexity, defer to v0.3.0+ |
| Code generation (scaffold-style) | Loses framework upgrade benefits — framework approach preferred |
| Mobile native app | Web-first, Phoenix LiveView handles responsive |
| OAuth/social login | Auth is BYO, not our responsibility |
| Database-specific features | Must be database-agnostic (PostgreSQL, MySQL, SQLite) |
| Notification inbox UI | Complex feature, defer to v0.2.0+ |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Pending |
| FOUND-02 | Phase 1 | Pending |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Pending |
| COMP-01 | Phase 2 | Pending |
| COMP-02 | Phase 2 | Pending |
| COMP-03 | Phase 2 | Pending |
| COMP-04 | Phase 2 | Pending |
| COMP-05 | Phase 2 | Pending |
| COMP-06 | Phase 2 | Pending |
| COMP-07 | Phase 2 | Pending |
| COMP-08 | Phase 2 | Pending |
| COMP-09 | Phase 2 | Pending |
| COMP-10 | Phase 2 | Pending |
| COMP-11 | Phase 2 | Pending |
| COMP-12 | Phase 2 | Pending |
| THEME-01 | Phase 2 | Pending |
| THEME-02 | Phase 2 | Pending |
| THEME-03 | Phase 2 | Pending |
| THEME-04 | Phase 2 | Pending |
| FORM-01 | Phase 3 | Pending |
| FORM-02 | Phase 3 | Pending |
| FORM-03 | Phase 3 | Pending |
| FORM-04 | Phase 3 | Pending |
| FORM-05 | Phase 3 | Pending |
| FORM-06 | Phase 3 | Pending |
| FORM-07 | Phase 3 | Pending |
| TABLE-01 | Phase 4 | Pending |
| TABLE-02 | Phase 4 | Pending |
| TABLE-03 | Phase 4 | Pending |
| TABLE-04 | Phase 4 | Pending |
| TABLE-05 | Phase 4 | Pending |
| TABLE-06 | Phase 4 | Pending |
| TABLE-07 | Phase 4 | Pending |
| TABLE-08 | Phase 4 | Pending |
| TABLE-09 | Phase 4 | Pending |
| TABLE-10 | Phase 4 | Pending |
| RES-01 | Phase 5 | Pending |
| RES-02 | Phase 5 | Pending |
| RES-03 | Phase 5 | Pending |
| RES-04 | Phase 5 | Pending |
| RES-05 | Phase 5 | Pending |
| RES-06 | Phase 5 | Pending |
| PANEL-01 | Phase 6 | Pending |
| PANEL-02 | Phase 6 | Pending |
| PANEL-03 | Phase 6 | Pending |
| PANEL-04 | Phase 6 | Pending |
| PANEL-05 | Phase 6 | Pending |
| PANEL-06 | Phase 6 | Pending |
| PANEL-07 | Phase 6 | Pending |
| PANEL-08 | Phase 6 | Pending |
| PLUG-01 | Phase 7 | Pending |
| PLUG-02 | Phase 7 | Pending |
| PLUG-03 | Phase 7 | Pending |
| PLUG-04 | Phase 7 | Pending |
| PLUG-05 | Phase 7 | Pending |
| PLUG-06 | Phase 7 | Pending |
| DIST-01 | Phase 8 | Pending |
| DIST-02 | Phase 8 | Pending |
| DIST-03 | Phase 8 | Pending |
| DIST-04 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 61 total (note: header previously said 56 — recount is 61)
- Mapped to phases: 61
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-31*
*Last updated: 2026-03-31 — traceability filled by roadmap creation*

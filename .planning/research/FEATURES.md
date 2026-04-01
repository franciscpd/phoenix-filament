# Feature Landscape

**Domain:** Admin Panel Framework for Phoenix/LiveView (FilamentPHP equivalent for Elixir)
**Researched:** 2026-03-31
**Overall Confidence:** HIGH — cross-referenced FilamentPHP v3 docs, Backpex, Kaffy, ActiveAdmin, Django Admin, and Elixir ecosystem evaluations

---

## Reference Frameworks Surveyed

| Framework | Language/Stack | Stars | Status |
|-----------|---------------|-------|--------|
| FilamentPHP v3 | PHP/Laravel/Livewire | 21K+ | Active, dominant |
| ActiveAdmin | Ruby/Rails | 9K+ | Active |
| Django Admin | Python/Django | (built-in) | Mature, stable |
| Kaffy | Elixir/Phoenix | 1.4K | Active, best current Elixir option |
| Backpex | Elixir/Phoenix/LiveView | ~500 | Active, newer |
| Torch | Elixir/Phoenix | 1.2K | Active but limited |
| ex_admin | Elixir/Phoenix | 1.2K | Abandoned (2016) |
| live_admin | Elixir/Phoenix/LiveView | 295 | Active but immature |

---

## Table Stakes

Features users expect in any admin panel framework. Missing = product feels incomplete and users leave.

### 1. CRUD Resource Abstraction
**Why Expected:** Every admin framework since Django Admin (2005) offers this. Users arrive expecting "give me a schema, get me a panel."
**Complexity:** High (framework foundation — everything builds on this)
**Notes:** Must cover Create, Read (list + detail), Update, Delete. The resource class/module is the primary DX touchpoint — its ergonomics determine whether the framework feels good or bad. FilamentPHP, ActiveAdmin, Django Admin, and Kaffy all make this the central concept.

### 2. Declarative Table Builder
**Why Expected:** List/index view is the most-used page in any admin. Users need sortable columns, pagination, and at minimum text-based search out of the box.
**Complexity:** High
**Required sub-features:**
- Configurable columns (show/hide, label, formatting)
- Default sort + user-controlled sort (click column header)
- Server-side pagination (25/50/100 per page)
- At least one search strategy (global text search across configurable fields)
- Empty state handling
**Notes:** Pagination UX best practice: default 25 rows, preserve page/filter state in URL params. When filters change, reset to page 1.

### 3. Declarative Form Builder
**Why Expected:** Create and edit pages require forms. Every admin panel provides this. The quality of the form builder is the #1 DX differentiator.
**Complexity:** High
**Required field types for v0.1.0:**
- Text input (single line)
- Textarea (multi-line)
- Number input
- Select (static options + association-backed)
- Checkbox / Toggle (boolean)
- Date / datetime picker
- Hidden field
**Deferred to later versions:**
- File upload / image upload
- Rich text / Markdown editor
- Repeater (nested collections)
- Color picker
- Tags input
- Key-value pairs
**Notes:** Form must integrate with Ecto changesets for validation. Errors should surface inline next to fields. FilamentPHP ships 18+ field types — start with 7-8 essential ones and establish a clean field extension API.

### 4. Ecto Changeset Integration
**Why Expected:** Elixir-specific table stake. Forms without changeset validation are not usable in practice. All Elixir admin frameworks (Kaffy, Backpex) integrate with changesets.
**Complexity:** Medium
**Notes:** Must call the correct changeset function, display field-level errors from the changeset, and support custom changeset functions per operation (e.g., different changeset for create vs. update).

### 5. Navigation Shell (Sidebar + Layout)
**Why Expected:** Users expect a framed admin UI with sidebar navigation listing resources, not raw pages. This is the "panel" in admin panel.
**Complexity:** Medium
**Required:**
- Sidebar with resource links (icon + label)
- Active state highlighting
- Responsive collapse (mobile)
- Top bar with user context (name/avatar, sign-out link)
- Breadcrumb navigation
- Page title area
**Notes:** Navigation groups (collapsible sections in sidebar) are a differentiator, not table stakes for v0.1.0.

### 6. Authentication Integration (BYO Auth)
**Why Expected:** Admin panels must be gated. However, users bring their own auth in the Elixir ecosystem (phx.gen.auth, Guardian, Pow). The framework must provide a pluggable middleware hook, not a built-in auth system.
**Complexity:** Low-Medium (hook is simple; documentation is the work)
**Notes:** A `Plug`-based or `on_mount` hook that checks if the current user is authenticated/authorized to access the admin. Must work with `phx.gen.auth` output with zero friction.

### 7. Basic Authorization (Resource-Level Access Control)
**Why Expected:** Not every admin user should see/do everything. At minimum, a hook to restrict which resources are visible and whether create/edit/delete are permitted.
**Complexity:** Medium
**Notes:** MVP implementation: a callback/function in the resource module that returns true/false. Full policy-based RBAC is a differentiator. FilamentPHP uses Laravel policies; Backpex uses pattern-matching based authorization.

### 8. Install Generator (`mix phx_filament.install`)
**Why Expected:** Developers expect a one-command setup. Without this, adoption friction is too high. FilamentPHP's `php artisan filament:install` is a key reason for its adoption. Torch (the Elixir generator) shows this pattern works in the ecosystem.
**Complexity:** Medium
**Notes:** Must inject config into the host app, add routes, set up layout, and provide a smoke test. The installer is part of the product — a confusing install experience kills adoption.

### 9. Delete with Confirmation
**Why Expected:** Any destructive action must be confirmed. This is so universal it's invisible — users notice its absence immediately.
**Complexity:** Low
**Notes:** A modal confirmation dialog before deletion. "Are you sure?" with record name displayed. This is the simplest action workflow and the foundation for the broader actions system.

### 10. Flash/Toast Notifications for CRUD Outcomes
**Why Expected:** After creating, updating, or deleting a record, users need feedback. Silent success or failure is confusing.
**Complexity:** Low
**Notes:** Success/error flash messages or toast notifications after form submission. Can piggyback on Phoenix's built-in flash system initially. Full notifications system (persistent, dismissable, real-time) is deferred to v0.2.0+.

---

## Differentiators

Features that set a framework apart. Not universally expected, but deliver significant competitive value when present.

### 1. Plugin Architecture with First-Party Plugin API
**Value Proposition:** Community-extensible ecosystem is what made FilamentPHP dominant over competitors. Backpack for Laravel and RailsAdmin failed partly because extending them was painful. Building PhoenixFilament's internals as plugins forces good API boundaries and enables community growth early.
**Complexity:** High
**Notes:** Core principle: the same API available to plugin authors must be what the framework itself uses. This is a non-negotiable architectural commitment per PROJECT.md. FilamentPHP validates this approach — it now has 300+ community plugins.
**Dependency:** Requires stable resource, form, and table APIs first.

### 2. Real-Time Features via LiveView
**Value Proposition:** LiveView enables features that would require WebSocket plumbing in other stacks — live search (instant results as you type), live form validation, live record counts — for free. This is a genuine differentiator vs. FilamentPHP which requires Livewire workarounds.
**Complexity:** Low-Medium (leverages what LiveView gives you)
**Notes:** Live validation (validate changeset on change, not just on submit), instant search (debounced), and live action feedback are the highest-value quick wins. Real-time collaborative editing and multi-user locking are out of scope.

### 3. Association/Relation Management
**Value Proposition:** Real data has relationships. BelongsTo selects in forms and HasMany sub-tables on edit pages are what make an admin actually usable for real applications. ActiveAdmin, Django Admin, and FilamentPHP all provide this — their absence in Kaffy/Torch is a primary criticism.
**Complexity:** High
**Notes:**
- BelongsTo: select field backed by a live query of the related schema
- HasMany inline table on edit page (relation manager concept from FilamentPHP)
- Defer: ManyToMany, polymorphic, through associations to v0.2.0+
**Dependency:** Requires stable form builder and table builder.

### 4. Column/Field Type Extensibility
**Value Proposition:** The built-in field and column types are never enough. A clean extension point lets users define custom field types without forking the framework.
**Complexity:** Medium
**Notes:** Custom field = a module implementing a behaviour with `render/2` and optional `form_component/1`. This is the foundation that enables the plugin ecosystem.

### 5. Theming via Tailwind CSS v4 CSS Variables
**Value Proposition:** White-label admin panels are common. Developers want to match brand colors without rebuilding every component. Tailwind v4's CSS variable approach (semantic tokens) is the modern correct solution.
**Complexity:** Medium
**Notes:** A single `:root` block of CSS variables (primary color, sidebar background, text colors, border radius) that changes the entire admin appearance. Dark mode support via CSS `prefers-color-scheme` and/or a class toggle. Do NOT couple theming to Tailwind config compilation — runtime CSS variables are essential.
**Dependency:** Requires stable component library.

### 6. Global Search
**Value Proposition:** FilamentPHP's global search (search across all resources from a single input) is cited as a major productivity feature. It lets power users navigate without clicking through menus.
**Complexity:** Medium
**Notes:** A search bar in the top navigation that queries configured resources. Each resource opts-in with a `searchable_attributes` or similar declaration. Results grouped by resource type. Deferred to v0.2.0 if scope is tight.

### 7. Table Filters (Beyond Text Search)
**Value Proposition:** Text search finds records by name; filters narrow by category, status, date range. Django Admin and ActiveAdmin treat filters as first-class. Kaffy has them; Torch is praised specifically for its filtering system. This is where admin panels become genuinely useful for operations work.
**Complexity:** Medium
**Notes:**
- Select filters (filter by enum/status value)
- Boolean filters (show only active, show only deleted)
- Date range filters
- All filters composable (multiple active simultaneously)
**Dependency:** Requires table builder.

### 8. Bulk Actions
**Value Proposition:** Operating on 1 record at a time is fine for edit; for operations like "archive all records from 2023" it's unusable. Bulk actions with checkboxes are expected by power users.
**Complexity:** Medium
**Notes:** Checkbox column in table, "select all on page" and "select all matching query" options, action applied to selected records. FilamentPHP and ActiveAdmin both provide this. Kaffy has limitations here (single-item custom actions but not multi-item). Start with delete bulk action as proof of concept.
**Dependency:** Requires table builder and actions foundation.

### 9. Resource Actions (Row Actions + Header Actions)
**Value Proposition:** Beyond CRUD, every application has custom operations — "send welcome email", "mark as paid", "export CSV". An actions system lets developers declare these without writing controller boilerplate.
**Complexity:** Medium-High
**Notes:** FilamentPHP's unified actions API (same API for table row actions, form header actions, modal confirmation actions) is praised as a major DX win. For v0.1.0, start with edit/delete/view row actions built-in, provide a simple hook for custom actions. Full actions system with modals and extra form fields is v0.2.0+.
**Dependency:** Requires resource and table builder.

### 10. Soft Delete Support
**Value Proposition:** Many applications use soft deletes (Paranoia pattern in Rails, built into Ecto via `deleted_at` field). An admin panel that permanently deletes soft-deletable records is dangerous. Supporting the pattern is a quality signal.
**Complexity:** Low-Medium
**Notes:** If a schema has a `deleted_at` field, the resource should offer: restore action, force delete action, and a filter to show/hide deleted records. This is a common Ecto pattern. FilamentPHP provides this out of the box.

---

## Anti-Features

Features to deliberately NOT build in v0.1.0. These waste time, add complexity, and distract from core value.

### 1. Built-In Authentication System
**Why Avoid:** The Elixir ecosystem has `phx.gen.auth`, Guardian, Pow, and Assent. Each project has already made this choice. Bundling auth creates conflict with existing setups, forces a specific user schema, and massively increases scope. FilamentPHP added their own auth panel and it created endless "how do I use my existing auth with Filament" questions.
**What to Do Instead:** Document 3 integration patterns (phx.gen.auth, Guardian, custom Plug). Provide a dead-simple `on_mount` hook that delegates to the host app.

### 2. Notifications/Inbox System
**Why Avoid:** A real-time notification inbox (persistent notifications, read/unread state, notification preferences) is a product unto itself. It requires database tables, background jobs, and significant UI work. The payoff is not proportional to the effort at v0.1.0.
**What to Do Instead:** Flash messages and toast notifications for immediate action feedback. Upgrade path to a notifications plugin in v0.2.0+.

### 3. Dashboard Widget Builder
**Why Avoid:** Chart widgets, stats cards, trend lines — these require data aggregation queries, charting libraries (or server-side SVG), and a layout system. Projects almost always have bespoke dashboard requirements. A generic widget system that's flexible enough to be useful is expensive to build.
**What to Do Instead:** Provide a blank dashboard page with clear extension points. Document how to add custom LiveView components to the dashboard slot. Let the community build chart plugins.

### 4. Multi-Tenancy
**Why Avoid:** Tenant scoping touches every query, every resource, every action. Building it in at v0.1.0 requires every API to carry a tenant context. The complexity is too high and the use cases too varied (schema-per-tenant vs. row-level vs. subdomain routing).
**What to Do Instead:** Design query customization hooks (custom `list_query/1`, `get_record/2` callbacks) in a way that doesn't block a future multi-tenancy plugin from using them.

### 5. Dead View (Non-LiveView) Support
**Why Avoid:** Supporting both LiveView and controller/template renders doubles the component surface area and prevents leveraging LiveView's real-time capabilities as a differentiator. Backpex has already proven the LiveView-only approach works.
**What to Do Instead:** 100% LiveView. Document the LiveView version requirement clearly in installation guide.

### 6. Code Generation (Torch-style)
**Why Avoid:** Torch generates Phoenix controllers and templates that you then own and maintain. This is fundamentally different from a runtime framework — you lose automatic updates, theming, and the admin's visual consistency as you customize generated code. Generated code is a one-time scaffold, not a framework.
**What to Do Instead:** Runtime framework pattern (resource modules declare intent, framework renders UI). This is the FilamentPHP/ActiveAdmin/Django Admin model — and it's what gives those frameworks their power to ship upgrades to all users simultaneously.

### 7. Complex Import/Export System
**Why Avoid:** CSV/Excel import with validation, conflict resolution, row-by-row error reporting, and progress tracking is a significant feature. Export is simpler but format variety (CSV, XLSX, JSON, XML) and large-dataset chunking add complexity.
**What to Do Instead:** In v0.1.0, document how to add a custom action that triggers a CSV export using Elixir's built-in CSV capabilities. Full import/export plugin in v0.2.0+.

### 8. Infolist (Read-Only Detail View) as a Separate Concept
**Why Avoid:** FilamentPHP's separation of "edit form" from "view infolist" adds a parallel system (separate layouts, separate entry types, separate customization) for what is essentially a read-only version of the edit page. At v0.1.0, this doubles the surface area for marginal benefit — most admins use the edit page as the detail view anyway.
**What to Do Instead:** The edit/update page serves as the detail view. Add a read-only mode flag to the form builder in v0.2.0+ if demand validates it.

### 9. Workflow / Approval / Maker-Checker
**Why Avoid:** Enterprise workflow features (submit for approval, reviewer queue, audit trail with notes, change tracking with diff views) are a distinct product. Some users of Backpex have requested this — it was explicitly called out as a missing feature. It's missing because it's genuinely out of scope for a general-purpose admin framework.
**What to Do Instead:** Design the actions API to be hook-friendly so a workflow plugin can intercept create/update/delete operations in the future.

### 10. Configuration-File-Only API (Kaffy's Approach)
**Why Avoid:** Kaffy's config.exs-based configuration is quick to start but hits walls fast. You can't co-locate business logic with the admin declaration, IDE support is poor, and complex customizations require jumping between files. Django Admin moved beyond this; FilamentPHP chose class-based resources for this reason.
**What to Do Instead:** Module-based DSL (macro-based resource modules). Keeps configuration close to the code, enables function definitions inline, and supports IDE autocomplete.

---

## Feature Dependencies

```
BYO Auth Hook
  └── Navigation Shell (must know current user for top bar)
      └── Resource Abstraction (resources appear in nav)
          ├── Table Builder
          │   ├── Pagination
          │   ├── Sorting
          │   ├── Text Search
          │   ├── Table Filters (differentiator)
          │   ├── Bulk Actions (differentiator)
          │   └── Row Actions
          │       └── Delete with Confirmation
          │           └── Flash Notifications
          ├── Form Builder
          │   ├── Ecto Changeset Integration
          │   ├── Field Types (Text, Select, Boolean, Date, etc.)
          │   └── Association Fields (differentiator)
          │       └── Relation Managers (differentiator)
          └── Authorization Hook
              └── Resource-level access control

Plugin Architecture
  └── Requires stable Resource, Form, Table APIs (depends on all the above)

Theming System
  └── Requires stable Component Library (parallel track)

Install Generator
  └── Requires working Navigation Shell + Resource Abstraction
```

---

## MVP Recommendation for v0.1.0

### Must Ship (Table Stakes)

1. **Resource abstraction** — module-based DSL, auto-generated CRUD routes
2. **Table builder** — columns, sort, pagination, text search
3. **Form builder** — 7-8 core field types, changeset integration, inline errors
4. **Navigation shell** — sidebar with resource links, breadcrumbs, top bar
5. **Auth integration hook** — `on_mount` callback, documented phx.gen.auth integration
6. **Basic authorization** — per-resource `can_access?/1` callback
7. **Delete with confirmation** — modal confirm dialog
8. **Flash notifications** — success/error after CRUD operations
9. **Install generator** — `mix phx_filament.install`
10. **Core component library** — buttons, inputs, badges, modals, cards

### Ship in v0.1.0 for Competitive Differentiation

11. **Plugin architecture** — even if no plugins ship yet, the API must exist
12. **Table filters** — select + boolean filters (text search alone is insufficient for real use)
13. **Tailwind v4 theming** — CSS variable override system

### Defer to v0.2.0+

- Row actions beyond edit/delete (custom actions system)
- Bulk actions
- Relation managers (HasMany sub-tables)
- Association fields (BelongsTo select backed by live query)
- Global search
- Dashboard widgets
- Notifications inbox
- Infolist / read-only detail view
- Soft delete support
- File upload field
- Rich text / Markdown editor
- Multi-tenancy

---

## Why Filament Won (Lessons for PhoenixFilament)

FilamentPHP became dominant in the Laravel ecosystem because of:

1. **Free and open source** — Nova charges per project; Backpack has tiered pricing
2. **Fluent, autocomplete-friendly DSL** — make commands + IDE support
3. **LiveView-equivalent (Livewire)** — no JavaScript to write
4. **Plugin ecosystem that compounds** — 300+ plugins by 2024
5. **Convention over configuration with escape hatches** — easy default path, custom path always available
6. **Community content** — tutorials, screencasts, blog posts drove adoption

The Elixir/Phoenix ecosystem currently lacks a comparable option. Kaffy is the closest but is config-file based (hitting DX ceiling), Backpex is newer and module-based but has limited adoption and fewer features. The gap is real and validated.

---

## Sources

- [FilamentPHP Documentation — Resources](https://filamentphp.com/docs/3.x/panels/resources/getting-started) — HIGH confidence
- [FilamentPHP Documentation — Form Fields](https://filamentphp.com/docs/3.x/forms/fields/getting-started) — HIGH confidence
- [FilamentPHP Documentation — Table Columns](https://filamentphp.com/docs/3.x/tables/columns/getting-started) — HIGH confidence
- [FilamentPHP Documentation — Relation Managers](https://filamentphp.com/docs/3.x/panels/resources/relation-managers) — HIGH confidence
- [Backpex GitHub Repository](https://github.com/naymspace/backpex) — HIGH confidence
- [Backpex Elixir Forum Thread](https://elixirforum.com/t/backpex-a-highly-customizable-admin-panel-for-phoenix-liveview-applications/64314) — HIGH confidence
- [Kaffy GitHub Repository](https://github.com/aesmail/kaffy) — HIGH confidence
- [Elixir Toolbox — Phoenix Admin Interfaces](https://elixir-toolbox.dev/projects/phoenix/phx_admin_interfaces) — MEDIUM confidence
- [Elixir Merge — Evaluation of Phoenix Admin Frameworks](https://elixirmerge.com/p/evaluation-of-phoenix-admin-frameworks-for-elixir) — MEDIUM confidence
- [BetterStack — RailsAdmin vs ActiveAdmin](https://betterstack.com/community/guides/scaling-ruby/railsadmin-vs-activeadmin/) — MEDIUM confidence
- [Django Admin Documentation](https://docs.djangoproject.com/en/5.1/ref/contrib/admin/) — HIGH confidence
- [Data Table UX Best Practices — Pencil & Paper](https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-data-tables) — MEDIUM confidence
- [Filament — Honest Review (Dev.to)](https://dev.to/tonegabes/how-filament-saved-or-complicated-my-admin-panel-an-honest-review-156b) — MEDIUM confidence
- [Backpex Phoenix Admin Panel — James Carr Blog](https://james-carr.org/posts/2024-08-27-phoenix-admin-with-backpex/) — MEDIUM confidence

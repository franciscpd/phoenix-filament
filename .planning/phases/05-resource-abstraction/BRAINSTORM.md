# Phase 5: Resource Abstraction — Design Spec

**Date:** 2026-04-02
**Status:** Approved
**Approach:** Thin Delegation — Resource injects minimal LiveView callbacks that delegate to specialized modules (Lifecycle, CRUD, Authorize, Renderer)

## Overview

Phase 5 makes `use PhoenixFilament.Resource` turn the module into a fully functional LiveView with CRUD pages. The Resource macro injects `use Phoenix.LiveView` and thin callbacks in `__before_compile__` that delegate to internal modules. A developer can go from `use PhoenixFilament.Resource, schema: Post, repo: Repo` to working index, create, edit, and show pages with zero additional code.

## Architecture

```
Resource Module (developer writes)
  │
  ├─ use PhoenixFilament.Resource  (macro injects LiveView + thin callbacks)
  │    ├─ use Phoenix.LiveView
  │    ├─ __resource__/1 accessors (existing)
  │    └─ __before_compile__ injects:
  │         mount/3        → Lifecycle.mount/4
  │         handle_params/3 → Lifecycle.handle_params/4
  │         handle_event/3  → Lifecycle.handle_event/4
  │         handle_info/2   → Lifecycle.handle_info/3
  │         render/1        → Renderer.render/1
  │
  ├─ form do...end  (DSL, existing)
  ├─ table do...end (DSL, existing)
  └─ def authorize/3 (optional callback)

Internal Modules:
  Lifecycle  — mount, apply_action per live_action, changeset setup
  CRUD       — list, get!, create, update, delete (pure Ecto operations)
  Authorize  — authorize!/4 wrapper (calls resource's authorize/3 if defined)
  Renderer   — render/1 composing TableLive + form_builder + modal + show detail
```

## Module Structure

```
lib/phoenix_filament/resource/
├── options.ex         # NimbleOptions (EXTEND: create_changeset, update_changeset)
├── defaults.ex        # Auto-discovery (existing, unchanged)
├── dsl.ex             # DSL macros (existing, unchanged)
├── lifecycle.ex       # NEW: mount, handle_params, handle_event, handle_info
├── renderer.ex        # NEW: render/1 composing form_builder + TableLive + show
├── crud.ex            # NEW: create, update, delete operations
└── authorize.ex       # NEW: authorize!/4 + UnauthorizedError
```

Plus modification of:
- `lib/phoenix_filament/resource.ex` — add `use Phoenix.LiveView`, inject thin callbacks

## NimbleOptions Extension

New options added to `resource/options.ex`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `create_changeset` | `{:fun, 2}` | `nil` | Function `(struct, params) → changeset` for create. Default: `schema.changeset/2` |
| `update_changeset` | `{:fun, 2}` | `nil` | Function `(record, params) → changeset` for update. Default: `schema.changeset/2` |

When `nil`, the Resource falls back to `schema.changeset/2` (convention over configuration).

## Lifecycle Module

Manages LiveView state transitions per `live_action`:

| live_action | apply_action does | Assigns set |
|-------------|-------------------|-------------|
| `:index` | Sets page title, passes params for TableLive | `page_title`, `params` |
| `:new` | Builds empty changeset via create_changeset fn | `page_title`, `form`, `changeset_fn`, `record: nil` |
| `:edit` | Loads record by id, builds changeset via update_changeset fn | `page_title`, `form`, `changeset_fn`, `record` |
| `:show` | Loads record by id | `page_title`, `record` |

**Event handling:**

| Event | Flow |
|-------|------|
| `"validate"` | Rebuild changeset from params → `assign(:form, to_form(changeset))` |
| `"save"` (new) | `authorize!(:create, nil, user)` → `CRUD.create` → flash + push_patch to index |
| `"save"` (edit) | `authorize!(:update, record, user)` → `CRUD.update` → flash + push_patch to index |
| `{:table_action, :view, id}` | `push_navigate` to show path |
| `{:table_action, :edit, id}` | `push_patch` to edit path |
| `{:table_action, :delete, id}` | `authorize!(:delete, record, user)` → `CRUD.delete` → flash + stay on index |
| `{:table_patch, params}` | `push_patch` with new URL params |

## CRUD Module

Pure functions for Ecto operations:

```elixir
CRUD.create(schema, repo, changeset_fn, params) → {:ok, record} | {:error, changeset}
CRUD.update(record, repo, changeset_fn, params) → {:ok, record} | {:error, changeset}
CRUD.delete(record, repo) → {:ok, record} | {:error, changeset}
CRUD.get!(schema, repo, id) → record (raises on not found)
```

No LiveView dependency. Testable with real Ecto Repo in sandbox.

## Authorization Module

```elixir
Authorize.authorize!(resource_module, action, record, user)
# If resource defines authorize/3 → calls it
# If not defined → allows (noop)
# Returns :ok or raises UnauthorizedError
```

Called before EVERY write operation (create, update, delete) — not just at mount. This satisfies success criterion #5.

**User source:** `socket.assigns[:current_user]` — set by Panel auth hook (Phase 6) or developer's `on_mount`.

## Renderer Module

Composes existing components based on `live_action`:

| live_action | Renders |
|-------------|---------|
| `:index` | `<h1>` title + `TableLive` LiveComponent (with columns, actions, filters, params) |
| `:new` | `:index` + modal overlay with `form_builder/1` (empty form, phx-change="validate" phx-submit="save") |
| `:edit` | `:index` + modal overlay with `form_builder/1` (pre-filled form) |
| `:show` | `<h1>` title + read-only record detail + Back link |

**Modal for create/edit:** Renders on top of the index table. `on_cancel` patches back to index URL. Same UX as `phx.gen.live`.

**Show page:** Simple read-only display of record fields. Uses column labels for field names, `to_string` for values. Basic for v0.1 — full infolist in v0.2.

## Thin Callbacks (injected by __before_compile__)

```elixir
# What gets injected into the Resource module:

def mount(params, session, socket) do
  PhoenixFilament.Resource.Lifecycle.mount(__MODULE__, params, session, socket)
end

def handle_params(params, uri, socket) do
  PhoenixFilament.Resource.Lifecycle.handle_params(__MODULE__, params, uri, socket)
end

def handle_event(event, params, socket) do
  PhoenixFilament.Resource.Lifecycle.handle_event(__MODULE__, event, params, socket)
end

def handle_info(msg, socket) do
  PhoenixFilament.Resource.Lifecycle.handle_info(__MODULE__, msg, socket)
end

def render(assigns) do
  PhoenixFilament.Resource.Renderer.render(assigns)
end
```

Each callback passes `__MODULE__` so the internal modules can read `__resource__/1` accessors and check for `authorize/3` callback.

## Compile-Time Safety

Phase 1's `Macro.expand_literals/2` already prevents compile-time cascades. Phase 5 must NOT introduce new compile-time dependencies:

- Lifecycle, CRUD, Authorize, Renderer are all runtime modules — no compile-time dependency on schema
- The thin callbacks in `__before_compile__` call functions (not macros) on runtime modules
- Existing cascade_test.exs continues to validate this

## Testing Strategy

```
test/phoenix_filament/resource/
├── lifecycle_test.exs    # apply_action assigns, page titles, changeset setup
├── crud_test.exs         # create/update/delete (needs Ecto Sandbox — basic or deferred)
├── authorize_test.exs    # authorize!/4 with/without callback, error raising
├── renderer_test.exs     # HTML rendering for index/new/edit/show layouts
└── options_test.exs      # NimbleOptions: changeset options validation
```

**Testable without DB:**
- Lifecycle: verify assigns set correctly per action (mock socket)
- Authorize: verify callback invocation, error raising, default allow
- Renderer: `rendered_to_string/1` for HTML structure
- Options: NimbleOptions validation

**Needs Ecto Sandbox:**
- CRUD: basic create/update/delete tests (deferred if no test DB setup)

## Success Criteria Mapping

| # | Criterion | How Satisfied |
|---|-----------|---------------|
| 1 | Zero-code CRUD pages | `use PhoenixFilament.Resource, schema: Post, repo: Repo` → LiveView with index/create/edit/show |
| 2 | Auto-discover fields with sensible types | `Resource.Defaults` (Phase 1) already does this → form_schema and table_columns |
| 3 | Override via DSL | `form do...end` and `table do...end` already work (Phases 1/3/4) |
| 4 | No compile-time cascade | `Macro.expand_literals/2` + thin delegation (no macro-generated code depends on schema) |
| 5 | authorize!/3 on every write | Authorize module called before create, update, delete in handle_event |
| 6 | Delete confirmation dialog | TableLive already has delete modal (Phase 4) → sends {:table_action, :delete, id} |

## Deferred

- Separate page mode (`form_mode: :page`) — v0.2+
- Full infolist for show page — v0.2+
- Custom pages per resource — v0.2+
- Nested resources — v0.2+
- Soft delete support — v0.2+

---

*Phase: 05-resource-abstraction*
*Design approved: 2026-04-02*

# Phase 5: Resource Abstraction - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

`use PhoenixFilament.Resource` makes the Resource module itself a LiveView that generates CRUD pages (index, create, edit, show) from an Ecto schema. The Resource auto-discovers fields, provides standard CRUD operations against the Repo, allows DSL customization of form and table, supports create/update changesets, optional per-action authorization, auto-derived page titles and breadcrumbs, and delete confirmation — all following the idiomatic Phoenix `live_action` pattern (not FilamentPHP's separate page classes).

</domain>

<decisions>
## Implementation Decisions

### CRUD LiveView Pages
- **D-01:** Resource IS the LiveView — `use PhoenixFilament.Resource` injects `use Phoenix.LiveView` plus `mount/3`, `handle_params/3`, `handle_event/3`, `handle_info/2`, and `render/1`. Developer routes directly to the Resource module. Zero extra modules to create.
- **D-02:** Single LiveView with `live_action` — follows idiomatic Phoenix pattern (like `phx.gen.live`). Actions: `:index`, `:new`, `:edit`, `:show`. NOT separate page modules like FilamentPHP — `live_action` is the Elixir way.
- **D-03:** Create/Edit forms open as modal over the table — `:new` and `:edit` live_actions render the form in a modal on top of the index table. `:show` navigates to a separate view. Matches `phx.gen.live` UX pattern.
- **D-04:** Routes follow Phoenix convention — `/posts` (index), `/posts/new` (create modal), `/posts/:id/edit` (edit modal), `/posts/:id` (show). Developer declares these in their router.

### Changeset Integration
- **D-05:** Changeset functions declared as NimbleOptions — `create_changeset: &Post.create_changeset/2`, `update_changeset: &Post.update_changeset/2`. Default: looks for `schema.changeset/2` for both. Resource selects the correct changeset based on live_action (:new vs :edit).
- **D-06:** Form receives the changeset-built `@form` — Resource calls the changeset function, converts to `to_form/1`, and passes to `form_builder/1`. Form Builder remains changeset-agnostic (Phase 3 decision confirmed).

### Authorization
- **D-07:** Optional `authorize/3` callback on Resource — `def authorize(action, record, user)` returns `:ok` or `{:error, reason}`. Default: always allows (no authorization). Framework calls it before every write operation (create, update, delete).
- **D-08:** Authorization enforced on every write event — not just at mount. `handle_event("save", ...)` and `handle_event("delete", ...)` both call `authorize!/3` before executing. Unauthorized → flash error, no operation.
- **D-09:** User comes from socket assigns — `socket.assigns.current_user`. Set by the Panel auth hook (Phase 6) or by the developer's `on_mount`. Resource does not provide auth — it only checks authorization.

### Page Titles + Navigation
- **D-10:** NimbleOptions + auto-derive — `label` and `plural_label` already exist in Resource options. Page titles auto-derived: "Posts" (index), "New Post" (create), "Edit Post" (edit). Breadcrumbs auto-generated from label + action.
- **D-11:** All navigation metadata overridable — custom label, plural_label, icon via NimbleOptions. Breadcrumbs auto-computed but can be overridden in future versions.

### Compile-Time Safety
- **D-12:** `Macro.expand_literals/2` already in place (Phase 1) — touching the Ecto schema does NOT recompile the Resource module. This is already validated by cascade_test.exs. Phase 5 must not introduce new compile-time dependencies.

### Claude's Discretion
- Exact LiveView callbacks injected by the macro (mount, handle_params, handle_event, render)
- How the Resource render/1 composes form_builder and TableLive components
- How delete confirmation integrates with TableLive's existing modal
- Show page rendering (read-only field display)
- Flash message patterns for CRUD success/error

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints
- `.planning/REQUIREMENTS.md` — RES-01 through RES-06
- `.planning/ROADMAP.md` §Phase 5 — Goal, success criteria

### Phase 1 Foundation (dependency)
- `lib/phoenix_filament/resource.ex` — Existing `__using__/1` macro, `__resource__/1` accessors, NimbleOptions
- `lib/phoenix_filament/resource/options.ex` — Current NimbleOptions schema (needs extension for changesets)
- `lib/phoenix_filament/resource/defaults.ex` — Auto-discovery (schema → fields/columns)
- `lib/phoenix_filament/resource/dsl.ex` — form/table DSL macros

### Phase 3 Form Builder (dependency)
- `lib/phoenix_filament/form/form_builder.ex` — `form_builder/1` component API
- `.planning/phases/03-form-builder/03-CONTEXT.md` — Form is changeset-agnostic (D-09)

### Phase 4 Table Builder (dependency)
- `lib/phoenix_filament/table/table_live.ex` — `TableLive` LiveComponent API (schema, repo, columns, params, actions, filters)
- `.planning/phases/04-table-builder/04-CONTEXT.md` — Table sends {:table_action, type, id} to parent

### Technology Stack
- `CLAUDE.md` §Technology Stack — Phoenix LiveView 1.1, Ecto, Macro.expand_literals/2

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Resource` — already has `__using__/1` with NimbleOptions, `__before_compile__/1` with `__resource__/1` accessors. Phase 5 extends this significantly.
- `PhoenixFilament.Resource.Options` — NimbleOptions schema. Needs new options: `create_changeset`, `update_changeset`.
- `PhoenixFilament.Resource.Defaults` — `form_fields/1` and `table_columns/1` auto-discovery. Already used by `__resource__(:form_schema)` and `__resource__(:table_columns)`.
- `PhoenixFilament.Form.FormBuilder` — `form_builder/1` accepts form + schema + phx-change/submit.
- `PhoenixFilament.Table.TableLive` — LiveComponent accepts schema, repo, columns, params, actions, filters. Sends `{:table_action, type, id}` and `{:table_patch, params}` to parent.
- `PhoenixFilament.Components.Modal` — `modal/1` for delete confirmation.

### Established Patterns
- `Macro.expand_literals/2` for compile-time safety (Phase 1)
- Module attribute accumulation for DSL → structs
- Function component pattern for form_builder
- LiveComponent pattern for table (owns query/stream state)
- `send(self(), {:table_action, type, id})` for action delegation

### Integration Points
- Resource will inject `use Phoenix.LiveView` and LiveView callbacks
- Resource will compose `form_builder/1` for create/edit modal and `TableLive` for index
- Resource handles `{:table_action, type, id}` from TableLive
- Resource handles `{:table_patch, params}` from TableLive for URL sync
- Phase 6 (Panel) will route to Resource modules and provide layout/auth

</code_context>

<specifics>
## Specific Ideas

- Zero-code CRUD is the headline: `use PhoenixFilament.Resource, schema: Post, repo: Repo` → working admin pages
- Follow `phx.gen.live` patterns closely — any Phoenix developer should recognize the structure
- Create/edit as modal over table is the standard Phoenix admin UX
- Authorization is opt-in — no auth by default, add `authorize/3` when needed

</specifics>

<deferred>
## Deferred Ideas

- Separate page mode (form_mode: :page) — v0.2+
- Show page with read-only fields (infolist pattern) — basic version in v0.1, full in v0.2+
- Custom pages per resource (like FilamentPHP getPages) — v0.2+
- Nested resources / parent-child relationships — v0.2+
- Activity log / audit trail per resource — v0.2+

</deferred>

---

*Phase: 05-resource-abstraction*
*Context gathered: 2026-04-02*

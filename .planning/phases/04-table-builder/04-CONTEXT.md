# Phase 4: Table Builder - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Standalone declarative table system using a LiveComponent that manages its own Ecto queries, LiveView streams, server-side sort/pagination/search/filters, row actions with delete confirmation modal, and URL-persisted state — all without Panel or Resource dependency. The `table do...end` DSL defines columns, filters, and actions. The LiveComponent receives schema, repo, and column config and handles everything internally.

</domain>

<decisions>
## Implementation Decisions

### Table LiveView Integration
- **D-01:** Table Builder is a **LiveComponent** (not function component) — it needs its own state for pagination, sort, stream, search, and filters. Justified departure from the function component pattern used in Form Builder.
- **D-02:** Table queries DB internally — receives `schema`, `repo`, and optional `base_query`. Builds Ecto query from params (sort, page, search, filters), executes via Repo, streams results. Parent only provides config, not data.
- **D-03:** Uses LiveView streams for memory-efficient rendering — rows are never held in full in socket assigns. Meets success criterion #6 (10k rows, no memory growth).

### Sort + Pagination + URL State
- **D-04:** Flat query params — `?sort=title&dir=asc&page=2&per_page=25&search=hello&filter[status]=draft`. Standard, bookmarkable, human-readable.
- **D-05:** Page sizes configurable via DSL — developer specifies allowed sizes (e.g., `page_sizes: [10, 25, 50, 100]`). Default: `[25, 50, 100]`.
- **D-06:** Sort direction toggle — clicking sortable column header toggles asc/desc. Sort indicator (arrow) shows current direction.

### Row Actions
- **D-07:** `actions do...end` block in table DSL — declares action buttons per row. Each action has a type atom, optional label, and optional `confirm:` text.
- **D-08:** Delete confirmation via Phase 2 modal component — delete action opens modal with confirm/cancel. Uses existing `modal/1` with `show`/`on_cancel` pattern.
- **D-09:** Actions send messages to parent — `send(self(), {:table_action, :edit, id})`. Parent handles navigation/deletion. Table doesn't know about routes or repos for actions.

### Filters System
- **D-10:** `filters do...end` block in table DSL — typed filter declarations: `select_filter`, `boolean_filter`, `date_filter`. Each specifies field, type, and options.
- **D-11:** Configurable filter composition — developer can choose AND/OR per filter for composing with search. Default: AND.
- **D-12:** Filter state in URL params — `filter[status]=draft&filter[published]=true`. Persists across page reloads.

### Empty State
- **D-13:** daisyUI alert with optional CTA — styled empty state with message and optional action button. Customizable via `empty_message`, `empty_action_label`, `empty_action_event` attrs.

### Search
- **D-14:** `searchable: true` on columns — columns marked searchable are included in ILIKE search. Search input auto-appears when any column is searchable.
- **D-15:** ILIKE search with debounce — search queries use `ILIKE '%term%'` across all searchable columns (OR). Debounced on the client to avoid excessive queries.

### Column Formatting
- **D-16:** `format:` callback in column opts — `format: fn value, row -> ... end` for custom cell rendering. Built-in shorthand: `badge: true` auto-renders status badge.

### Claude's Discretion
- Ecto query composition internals (how sort/filter/search/pagination compose into a single query)
- LiveComponent lifecycle (update/handle_event/handle_params)
- Stream reset strategy on sort/filter/search change
- Debounce timing for search (300ms typical)
- Exact daisyUI classes for table, pagination, and filters UI

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Specification
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — TABLE-01 through TABLE-10
- `.planning/ROADMAP.md` §Phase 4 — Goal, success criteria, dependency info

### Phase 1 Foundation (dependency)
- `lib/phoenix_filament/column.ex` — `%Column{}` struct (name, label, opts)
- `lib/phoenix_filament/resource/dsl.ex` — Existing `table/1` macro and `column/2` in TableColumns

### Phase 2 Components (dependency)
- `lib/phoenix_filament/components/button.ex` — Button for actions
- `lib/phoenix_filament/components/badge.ex` — Badge for status columns
- `lib/phoenix_filament/components/modal.ex` — Modal for delete confirmation
- `lib/phoenix_filament/components/input.ex` — Select for filters, text_input for search

### Phase 3 Form Builder (pattern reference)
- `lib/phoenix_filament/form/form_builder.ex` — Function component pattern (for contrast — table uses LiveComponent)
- `lib/phoenix_filament/resource/dsl.ex` — Push/pop context pattern for nested DSL blocks

### Technology Stack
- `CLAUDE.md` §Technology Stack — Phoenix LiveView 1.1 streams, Ecto query DSL

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Column` — struct with name, label, opts. Table Builder reads columns from `__resource__(:table_columns)` or direct attrs
- `PhoenixFilament.Components.Badge` — `badge/1` for status column rendering
- `PhoenixFilament.Components.Button` — `button/1` for action buttons
- `PhoenixFilament.Components.Modal` — `modal/1` for delete confirmation
- `PhoenixFilament.Components.Input` — `select/1` for filter dropdowns, `text_input/1` for search
- `PhoenixFilament.Naming.humanize/1` — label humanization

### Established Patterns
- Push/pop context in DSL macros (Phase 3) — reuse for `actions do...end` and `filters do...end` blocks
- Module attribute accumulation for DSL → structs
- daisyUI semantic classes + inline class lists
- `@grid_classes` static map pattern for avoiding Tailwind interpolation

### Integration Points
- Phase 5 (Resource) will instantiate TableBuilder LiveComponent with `__resource__(:table_columns)` and schema/repo
- The existing `table do...end` DSL macro (Phase 1) accumulates `%Column{}` structs — needs extension for actions and filters
- Parent LiveView receives `{:table_action, action, id}` messages for navigation/deletion

</code_context>

<specifics>
## Specific Ideas

- Table should feel like a "drop-in" — pass schema + repo and get a working paginated, sortable, searchable table
- LiveComponent is the right choice here (unlike Form Builder) because table needs to own its query/stream state
- ILIKE search is good enough for v0.1 — full-text search deferred
- Row actions use the existing modal from Phase 2 for delete confirmation

</specifics>

<deferred>
## Deferred Ideas

- Full-text search (pg_trgm or tsvector) — v0.2+
- Bulk actions (select multiple rows + batch operation) — v0.2+
- Column reordering / hide-show toggle — v0.2+
- Export to CSV/Excel — v0.2+
- Inline row editing — v0.2+
- Multi-table per page (namespaced params) — v0.2+

</deferred>

---

*Phase: 04-table-builder*
*Context gathered: 2026-04-01*

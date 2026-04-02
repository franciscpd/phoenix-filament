# Phase 4: Table Builder — Design Spec

**Date:** 2026-04-01
**Status:** Approved
**Approach:** Three-Layer Architecture — QueryBuilder (pure functions) + TableLive (LiveComponent) + TableRenderer (function components)

## Overview

Phase 4 delivers a standalone declarative table system. A LiveComponent (`TableLive`) manages Ecto queries, LiveView streams, and user interactions (sort, search, filter, paginate). It delegates query composition to a pure-function `QueryBuilder` module and HTML rendering to stateless `TableRenderer` function components. All table state is persisted in URL params. Row actions send messages to the parent LiveView. Delete confirmation uses the Phase 2 modal component.

## Architecture

```
Three Layers:

1. QueryBuilder (pure functions)
   params + schema + columns + filters → {Ecto.Query, meta}
   Testable without LiveView or DB

2. TableLive (LiveComponent)
   Lifecycle: update → QueryBuilder.build → Repo.all → stream
   Events: sort, search, filter, page, row_action → push_patch → re-query
   
3. TableRenderer (function components)
   Stateless HTML: table headers, rows, pagination, search, filters, empty state, actions
```

**Data flow:**
1. Parent LiveView passes `params` (from `handle_params`) to TableLive
2. TableLive calls `QueryBuilder.build/5` → `{query, meta}`
3. Executes paged query via Repo → stream reset + stream insert for each row
4. User events (sort/search/filter/page) → `push_patch` with new URL params → parent re-renders → TableLive `update/2` re-queries
5. Row actions → `send(self(), {:table_action, type, id})` to parent

## Module Structure

```
lib/phoenix_filament/table/
├── query_builder.ex       # Pure functions: params → Ecto.Query + meta
├── table_live.ex          # LiveComponent: lifecycle, events, stream
├── table_renderer.ex      # Function components: header, rows, pagination, etc.
├── action.ex              # %Action{} struct
├── filter.ex              # %Filter{} struct
└── params.ex              # URL param parsing/encoding helpers
```

Plus DSL extension:
```
lib/phoenix_filament/resource/dsl.ex  # Add actions/1 and filters/1 blocks
lib/phoenix_filament/resource.ex      # Add :table_actions, :table_filters accessors
```

## Data Structures

### %Action{} Struct

```elixir
defmodule PhoenixFilament.Table.Action do
  defstruct [:type, :label, :confirm, :icon]
  @type t :: %__MODULE__{
    type: atom(),         # :view, :edit, :delete, or custom
    label: String.t(),    # Button text (auto-humanized from type if nil)
    confirm: String.t() | nil,  # Confirmation message (triggers modal)
    icon: String.t() | nil      # Optional icon name
  }
end
```

### %Filter{} Struct

```elixir
defmodule PhoenixFilament.Table.Filter do
  defstruct [:type, :field, :label, :options, composition: :and]
  @type t :: %__MODULE__{
    type: :select | :boolean | :date_range,
    field: atom(),
    label: String.t(),
    options: list() | nil,     # For :select type
    composition: :and | :or    # How this filter composes with others
  }
end
```

## QueryBuilder

Pure-function module that composes Ecto queries from table params.

```elixir
defmodule PhoenixFilament.Table.QueryBuilder do
  # Main entry point
  def build(schema, repo, params, columns, filters) do
    searchable = columns |> Enum.filter(&Keyword.get(&1.opts, :searchable, false))

    query =
      schema
      |> apply_search(params, searchable)
      |> apply_filters(params, filters)
      |> apply_sort(params, columns)

    total = repo.aggregate(query, :count)
    page_params = parse_pagination(params)
    paged_query = apply_pagination(query, page_params)

    meta = %{
      total: total,
      page: page_params.page,
      per_page: page_params.per_page,
      total_pages: ceil(total / page_params.per_page)
    }

    {paged_query, meta}
  end
end
```

**Query composition details:**

| Function | What It Does | Ecto |
|----------|-------------|------|
| `apply_search/3` | ILIKE across searchable columns (OR) | `dynamic([r], ilike(r.title, ^"%term%") or ilike(r.body, ^"%term%"))` |
| `apply_filters/3` | WHERE clauses per active filter (AND/OR configurable) | `where([r], r.status == ^"draft")` |
| `apply_sort/3` | ORDER BY validated sortable column | `order_by([r], [{^dir, ^col}])` |
| `apply_pagination/2` | LIMIT + OFFSET | `limit(^per_page) \|> offset(^offset)` |

**Two DB calls:** One `aggregate(:count)` for total (pagination needs it), one paged query for data. The count query excludes limit/offset.

## TableLive (LiveComponent)

### Required Attrs (from parent)

| Attr | Type | Description |
|------|------|-------------|
| `id` | `:string` | Required for LiveComponent |
| `schema` | `:atom` | Ecto schema module |
| `repo` | `:atom` | Ecto repo module |
| `columns` | `:list` | `[%Column{}]` |
| `params` | `:map` | URL params from parent's `handle_params` |

### Optional Attrs

| Attr | Type | Default | Description |
|------|------|---------|-------------|
| `actions` | `:list` | `[]` | `[%Action{}]` row actions |
| `filters` | `:list` | `[]` | `[%Filter{}]` filter declarations |
| `page_sizes` | `:list` | `[25, 50, 100]` | Allowed page sizes |
| `base_query` | `:any` | `nil` | Pre-scoped Ecto query |
| `empty_message` | `:string` | `"No records found"` | Empty state message |
| `empty_action_label` | `:string` | `nil` | Optional CTA button label |
| `empty_action_event` | `:string` | `nil` | Event sent when CTA clicked |

### Event Handling

| Event | Params | Action |
|-------|--------|--------|
| `sort` | `%{"column" => col}` | Toggle direction if same col, else asc. Push patch. |
| `search` | `%{"search" => term}` | Reset to page 1. Push patch. Debounced on client. |
| `filter` | `%{"filter" => map}` | Reset to page 1. Push patch. |
| `change_page` | `%{"page" => n}` | Push patch with new page. |
| `change_per_page` | `%{"per_page" => n}` | Reset to page 1. Push patch. |
| `row_action` | `%{"action" => type, "id" => id}` | If delete with confirm → show modal. Else → send to parent. |
| `confirm_delete` | `%{"id" => id}` | Send `{:table_action, :delete, id}` to parent. Close modal. |
| `cancel_delete` | — | Close modal. |

### Stream Strategy

On every `update/2` (triggered by param changes):
1. Build query via QueryBuilder
2. Execute paged query: `rows = repo.all(paged_query)`
3. Reset stream: `stream(socket, :rows, rows, reset: true)`

Stream reset on every param change is simple and correct. LiveView handles DOM diffing efficiently. No need for incremental stream updates for v0.1.

## TableRenderer (Function Components)

### Components

| Component | daisyUI Classes | Description |
|-----------|----------------|-------------|
| `search_bar/1` | `input input-bordered input-sm` | Search input with phx-change + debounce |
| `filter_bar/1` | `flex gap-2 items-end` | Filter controls (select, toggle, date inputs) |
| `table_content/1` | `table table-zebra` | Full table with headers and streamed rows |
| `sort_header/1` | `cursor-pointer hover:bg-base-200` | Clickable `<th>` with sort arrow ▲/▼ |
| `action_buttons/1` | `btn btn-sm btn-ghost` / `btn-error` | Per-row action buttons |
| `empty_state/1` | `alert` | Empty message with optional CTA |
| `pagination/1` | `join` + `btn btn-sm` | Page numbers + per-page selector + "Showing X of Y" |
| `delete_modal/1` | Uses Phase 2 `modal/1` | Confirmation dialog for delete action |

### Cell Rendering

```elixir
defp render_cell(value, row, column) do
  cond do
    column.opts[:format] -> column.opts[:format].(value, row)
    column.opts[:badge] -> badge_html(value)
    true -> to_string(value || "")
  end
end
```

Priority: `format:` callback > `badge: true` shorthand > default `to_string`.

## DSL Extension

Add `actions/1` and `filters/1` blocks to the table DSL using the same push/pop context pattern from Phase 3:

```elixir
table do
  column :title, sortable: true, searchable: true
  column :status, badge: true
  column :inserted_at, format: &Calendar.strftime(&1, "%b %d, %Y")

  filters do
    select_filter :status, options: ~w(draft published archived)
    boolean_filter :published, label: "Published only"
  end

  actions do
    action :view, label: "View"
    action :edit, label: "Edit"
    action :delete, label: "Delete", confirm: "Are you sure?"
  end
end
```

New resource accessors:
- `__resource__(:table_actions)` → `[%Action{}]`
- `__resource__(:table_filters)` → `[%Filter{}]`

## URL Params Format

```
/admin/posts?sort=title&dir=asc&page=2&per_page=25&search=hello&filter[status]=draft&filter[published]=true
```

Flat query params. Bookmarkable, human-readable, standard.

## Testing Strategy

```
test/phoenix_filament/table/
├── query_builder_test.exs    # Pure Ecto query AST inspection (no DB)
├── table_renderer_test.exs   # HTML rendering via rendered_to_string
├── action_test.exs           # %Action{} struct
├── filter_test.exs           # %Filter{} struct
├── params_test.exs           # URL param parsing/encoding
└── dsl_test.exs              # actions/1, filters/1 DSL blocks
```

**Per-layer testing:**

- **QueryBuilder:** Inspect Ecto query AST (no DB). Verify `order_by`, `where`, `limit`/`offset`, `ilike` are composed correctly from params.
- **TableRenderer:** `rendered_to_string/1` — verify daisyUI classes, sort indicators, pagination controls, empty state, action buttons.
- **Structs + DSL:** Unit tests for constructors and macro accumulation.
- **TableLive integration:** Deferred — needs Ecto SQL Sandbox with real DB. Can be tested manually or in Phase 6 integration.

## Success Criteria Mapping

| # | Criterion | How Satisfied |
|---|-----------|---------------|
| 1 | Paginated table in plain LiveView | TableLive is a LiveComponent usable anywhere. No Panel dependency. |
| 2 | Sort by column header click | `sort` event toggles direction, sort indicator shows ▲/▼ |
| 3 | Search updates URL, persists across reloads | `search` event push_patches URL. Params parsed on mount. |
| 4 | Filters narrow results, state in URL | `filter` event push_patches with filter[field]=value |
| 5 | Row actions with delete confirmation | `actions do...end` DSL. Delete opens Phase 2 modal. |
| 6 | 10k rows, no memory growth | LiveView streams with `reset: true`. Rows never in assigns. |

## Deferred

- Full-text search (pg_trgm/tsvector) — v0.2+
- Bulk actions (select multiple) — v0.2+
- Column reorder / hide toggle — v0.2+
- CSV/Excel export — v0.2+
- Inline row editing — v0.2+
- Multi-table per page (namespaced params) — v0.2+
- TableLive integration tests with real DB — Phase 6 or v0.2

---

*Phase: 04-table-builder*
*Design approved: 2026-04-01*

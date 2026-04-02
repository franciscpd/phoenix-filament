# Phase 4: Table Builder — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone table system with a LiveComponent that manages Ecto queries, LiveView streams, server-side sort/pagination/search/filters, row actions with delete confirmation, and URL-persisted state — all without Panel or Resource dependency.

**Architecture:** Three-layer — QueryBuilder (pure functions composing Ecto queries from params), TableLive (LiveComponent managing lifecycle, events, and streams), and TableRenderer (stateless function components for HTML rendering). The DSL is extended with `actions/1` and `filters/1` blocks.

**Tech Stack:** Elixir 1.19+, Phoenix.LiveComponent, Ecto.Query (dynamic), LiveView streams, daisyUI 5

---

## File Structure

### Source Files (create)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/table/action.ex` | `%Action{}` struct (type, label, confirm, icon) |
| `lib/phoenix_filament/table/filter.ex` | `%Filter{}` struct (type, field, label, options, composition) |
| `lib/phoenix_filament/table/params.ex` | URL param parsing/encoding helpers |
| `lib/phoenix_filament/table/query_builder.ex` | Pure functions: params → Ecto.Query + meta |
| `lib/phoenix_filament/table/table_renderer.ex` | Function components: table, pagination, search, filters, empty state |
| `lib/phoenix_filament/table/table_live.ex` | LiveComponent: lifecycle, events, stream |

### Source Files (modify)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/resource/dsl.ex` | Add `actions/1` and `filters/1` blocks to TableColumns |
| `lib/phoenix_filament/resource.ex` | Add `:table_actions`, `:table_filters` accessors |

### Test Files (create)

| File | Responsibility |
|------|---------------|
| `test/phoenix_filament/table/action_test.exs` | Action struct tests |
| `test/phoenix_filament/table/filter_test.exs` | Filter struct tests |
| `test/phoenix_filament/table/params_test.exs` | Param parsing tests |
| `test/phoenix_filament/table/query_builder_test.exs` | Query composition tests (Ecto AST, no DB) |
| `test/phoenix_filament/table/table_renderer_test.exs` | HTML rendering tests |
| `test/phoenix_filament/table/dsl_test.exs` | DSL extension tests (actions, filters blocks) |

---

## Task 1: Action and Filter Structs

**Files:**
- Create: `lib/phoenix_filament/table/action.ex`
- Create: `lib/phoenix_filament/table/filter.ex`
- Create: `test/phoenix_filament/table/action_test.exs`
- Create: `test/phoenix_filament/table/filter_test.exs`

- [ ] **Step 1: Write failing tests for Action**

```elixir
# test/phoenix_filament/table/action_test.exs
defmodule PhoenixFilament.Table.ActionTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Table.Action

  describe "%Action{}" do
    test "creates action with type and label" do
      action = %Action{type: :edit, label: "Edit"}

      assert action.type == :edit
      assert action.label == "Edit"
      assert action.confirm == nil
      assert action.icon == nil
    end

    test "creates delete action with confirmation" do
      action = %Action{type: :delete, label: "Delete", confirm: "Are you sure?"}

      assert action.confirm == "Are you sure?"
    end

    test "defaults to nil for optional fields" do
      action = %Action{type: :view}

      assert action.label == nil
      assert action.confirm == nil
      assert action.icon == nil
    end
  end
end
```

- [ ] **Step 2: Write failing tests for Filter**

```elixir
# test/phoenix_filament/table/filter_test.exs
defmodule PhoenixFilament.Table.FilterTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Table.Filter

  describe "%Filter{}" do
    test "creates select filter with options" do
      filter = %Filter{type: :select, field: :status, label: "Status", options: ~w(draft published)}

      assert filter.type == :select
      assert filter.field == :status
      assert filter.options == ["draft", "published"]
      assert filter.composition == :and
    end

    test "creates boolean filter" do
      filter = %Filter{type: :boolean, field: :published, label: "Published only"}

      assert filter.type == :boolean
      assert filter.field == :published
      assert filter.options == nil
    end

    test "creates date_range filter" do
      filter = %Filter{type: :date_range, field: :inserted_at, label: "Created"}

      assert filter.type == :date_range
    end

    test "supports configurable composition" do
      filter = %Filter{type: :select, field: :status, composition: :or}

      assert filter.composition == :or
    end

    test "defaults composition to :and" do
      filter = %Filter{type: :boolean, field: :active}

      assert filter.composition == :and
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/table/`
Expected: Compilation error — modules not found

- [ ] **Step 4: Implement Action struct**

```elixir
# lib/phoenix_filament/table/action.ex
defmodule PhoenixFilament.Table.Action do
  @moduledoc """
  Represents a row action in a table (view, edit, delete, or custom).

  Actions are declared in the `actions do...end` block of a table DSL
  and rendered as buttons in each table row.
  """

  @type t :: %__MODULE__{
          type: atom(),
          label: String.t() | nil,
          confirm: String.t() | nil,
          icon: String.t() | nil
        }

  defstruct [:type, :label, :confirm, :icon]
end
```

- [ ] **Step 5: Implement Filter struct**

```elixir
# lib/phoenix_filament/table/filter.ex
defmodule PhoenixFilament.Table.Filter do
  @moduledoc """
  Represents a table filter declaration.

  Filters are declared in the `filters do...end` block of a table DSL.
  Supported types: `:select`, `:boolean`, `:date_range`.
  """

  @type t :: %__MODULE__{
          type: :select | :boolean | :date_range,
          field: atom(),
          label: String.t() | nil,
          options: list() | nil,
          composition: :and | :or
        }

  defstruct [:type, :field, :label, :options, composition: :and]
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/table/`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add lib/phoenix_filament/table/action.ex lib/phoenix_filament/table/filter.ex test/phoenix_filament/table/action_test.exs test/phoenix_filament/table/filter_test.exs
git commit -m "feat(table): add Action and Filter structs"
```

---

## Task 2: URL Params Module

**Files:**
- Create: `lib/phoenix_filament/table/params.ex`
- Create: `test/phoenix_filament/table/params_test.exs`

- [ ] **Step 1: Write failing tests for Params**

```elixir
# test/phoenix_filament/table/params_test.exs
defmodule PhoenixFilament.Table.ParamsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Table.Params

  describe "parse/2" do
    test "parses sort params with defaults" do
      result = Params.parse(%{"sort" => "title", "dir" => "asc"}, page_sizes: [25, 50, 100])

      assert result.sort_by == :title
      assert result.sort_dir == :asc
    end

    test "defaults to id desc when no sort params" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])

      assert result.sort_by == :id
      assert result.sort_dir == :desc
    end

    test "parses pagination params" do
      result = Params.parse(%{"page" => "3", "per_page" => "50"}, page_sizes: [25, 50, 100])

      assert result.page == 3
      assert result.per_page == 50
    end

    test "defaults pagination to page 1, first page_size" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])

      assert result.page == 1
      assert result.per_page == 25
    end

    test "clamps per_page to allowed page_sizes" do
      result = Params.parse(%{"per_page" => "999"}, page_sizes: [25, 50, 100])

      assert result.per_page == 25
    end

    test "parses search param" do
      result = Params.parse(%{"search" => "hello"}, page_sizes: [25, 50, 100])

      assert result.search == "hello"
    end

    test "defaults search to empty string" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])

      assert result.search == ""
    end

    test "parses filter params" do
      result = Params.parse(%{"filter" => %{"status" => "draft", "published" => "true"}}, page_sizes: [25, 50, 100])

      assert result.filters == %{status: "draft", published: "true"}
    end

    test "defaults filters to empty map" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])

      assert result.filters == %{}
    end

    test "clamps page to 1 minimum" do
      result = Params.parse(%{"page" => "0"}, page_sizes: [25, 50, 100])

      assert result.page == 1
    end
  end

  describe "to_query_string/1" do
    test "encodes params to URL query string map" do
      parsed = %{sort_by: :title, sort_dir: :asc, page: 2, per_page: 25, search: "hello", filters: %{status: "draft"}}
      result = Params.to_query_string(parsed)

      assert result["sort"] == "title"
      assert result["dir"] == "asc"
      assert result["page"] == "2"
      assert result["per_page"] == "25"
      assert result["search"] == "hello"
      assert result["filter"] == %{"status" => "draft"}
    end

    test "omits empty search" do
      parsed = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}
      result = Params.to_query_string(parsed)

      refute Map.has_key?(result, "search")
    end

    test "omits empty filters" do
      parsed = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}
      result = Params.to_query_string(parsed)

      refute Map.has_key?(result, "filter")
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/table/params_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement Params module**

```elixir
# lib/phoenix_filament/table/params.ex
defmodule PhoenixFilament.Table.Params do
  @moduledoc """
  Parses and encodes URL query params for table state.

  Handles sort, pagination, search, and filter params.
  """

  @type parsed :: %{
          sort_by: atom(),
          sort_dir: :asc | :desc,
          page: pos_integer(),
          per_page: pos_integer(),
          search: String.t(),
          filters: %{atom() => String.t()}
        }

  @doc "Parses raw URL params into a structured map with defaults."
  @spec parse(map(), keyword()) :: parsed()
  def parse(params, opts \\ []) do
    page_sizes = Keyword.get(opts, :page_sizes, [25, 50, 100])
    default_per_page = hd(page_sizes)

    per_page_raw = params |> Map.get("per_page", to_string(default_per_page)) |> parse_int(default_per_page)
    per_page = if per_page_raw in page_sizes, do: per_page_raw, else: default_per_page

    %{
      sort_by: params |> Map.get("sort", "id") |> String.to_existing_atom(),
      sort_dir: params |> Map.get("dir", "desc") |> parse_dir(),
      page: params |> Map.get("page", "1") |> parse_int(1) |> max(1),
      per_page: per_page,
      search: Map.get(params, "search", ""),
      filters: params |> Map.get("filter", %{}) |> atomize_keys()
    }
  rescue
    ArgumentError -> parse(Map.delete(params, "sort"), opts)
  end

  @doc "Encodes parsed params to a URL query string map."
  @spec to_query_string(parsed()) :: map()
  def to_query_string(parsed) do
    base = %{
      "sort" => to_string(parsed.sort_by),
      "dir" => to_string(parsed.sort_dir),
      "page" => to_string(parsed.page),
      "per_page" => to_string(parsed.per_page)
    }

    base =
      if parsed.search != "" do
        Map.put(base, "search", parsed.search)
      else
        base
      end

    if parsed.filters != %{} do
      filter_map = Map.new(parsed.filters, fn {k, v} -> {to_string(k), v} end)
      Map.put(base, "filter", filter_map)
    else
      base
    end
  end

  defp parse_int(str, default) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_dir("asc"), do: :asc
  defp parse_dir(_), do: :desc

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
  rescue
    ArgumentError -> %{}
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/table/params_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/table/params.ex test/phoenix_filament/table/params_test.exs
git commit -m "feat(table): add URL params parsing and encoding"
```

---

## Task 3: QueryBuilder

**Files:**
- Create: `lib/phoenix_filament/table/query_builder.ex`
- Create: `test/phoenix_filament/table/query_builder_test.exs`

- [ ] **Step 1: Write failing tests for QueryBuilder**

```elixir
# test/phoenix_filament/table/query_builder_test.exs
defmodule PhoenixFilament.Table.QueryBuilderTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  alias PhoenixFilament.Table.QueryBuilder
  alias PhoenixFilament.Table.Filter
  alias PhoenixFilament.Column

  # We test query AST composition, not DB execution.
  # Use Post schema from test support.
  @schema PhoenixFilament.Test.Schemas.Post

  defp columns do
    [
      Column.column(:title, sortable: true, searchable: true),
      Column.column(:body, searchable: true),
      Column.column(:published, sortable: true),
      Column.column(:views, sortable: true)
    ]
  end

  describe "build_query/4" do
    test "returns a base query when no params" do
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), [])

      assert %Ecto.Query{} = query
    end

    test "applies sort order" do
      params = %{sort_by: :title, sort_dir: :asc, page: 1, per_page: 25, search: "", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)

      assert query_string =~ "order_by"
      assert query_string =~ ":title"
    end

    test "rejects sort on non-sortable column" do
      params = %{sort_by: :body, sort_dir: :asc, page: 1, per_page: 25, search: "", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)

      # Should fallback to default sort (id desc), not sort by body
      refute query_string =~ ":body"
    end

    test "applies search across searchable columns" do
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "hello", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)

      assert query_string =~ "ilike"
    end

    test "skips search when empty" do
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)

      refute query_string =~ "ilike"
    end

    test "applies select filter" do
      filters = [%Filter{type: :select, field: :status, options: ~w(draft published)}]
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{status: "draft"}}

      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      query_string = inspect(query)

      assert query_string =~ "status"
    end

    test "applies boolean filter" do
      filters = [%Filter{type: :boolean, field: :published}]
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{published: "true"}}

      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      query_string = inspect(query)

      assert query_string =~ "published"
    end

    test "skips inactive filters" do
      filters = [%Filter{type: :select, field: :status, options: ~w(draft published)}]
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}

      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      query_string = inspect(query)

      refute query_string =~ "status"
    end
  end

  describe "apply_pagination/2" do
    test "adds limit and offset" do
      query = from(p in @schema)
      result = QueryBuilder.apply_pagination(query, %{page: 3, per_page: 25})

      query_string = inspect(result)
      assert query_string =~ "limit"
      assert query_string =~ "offset"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/table/query_builder_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement QueryBuilder**

```elixir
# lib/phoenix_filament/table/query_builder.ex
defmodule PhoenixFilament.Table.QueryBuilder do
  @moduledoc """
  Composes Ecto queries from table params.

  Pure functions — no DB calls, no LiveView dependency. Testable in isolation.
  """

  import Ecto.Query

  alias PhoenixFilament.Table.Filter

  @doc """
  Builds an Ecto query from parsed params, columns, and filter declarations.
  Returns the composed query (without execution).
  """
  @spec build_query(module(), map(), [PhoenixFilament.Column.t()], [Filter.t()]) :: Ecto.Query.t()
  def build_query(schema, params, columns, filters) do
    searchable = Enum.filter(columns, fn col -> Keyword.get(col.opts, :searchable, false) end)
    sortable_names = columns |> Enum.filter(fn col -> Keyword.get(col.opts, :sortable, false) end) |> Enum.map(& &1.name)

    schema
    |> apply_search(params.search, searchable)
    |> apply_filters(params.filters, filters)
    |> apply_sort(params.sort_by, params.sort_dir, sortable_names)
  end

  @doc """
  Executes the query with count and pagination. Returns {rows, meta}.
  """
  @spec execute(Ecto.Query.t(), module(), map()) :: {list(), map()}
  def execute(query, repo, params) do
    total = repo.aggregate(query, :count)
    paged_query = apply_pagination(query, params)
    rows = repo.all(paged_query)

    meta = %{
      total: total,
      page: params.page,
      per_page: params.per_page,
      total_pages: max(1, ceil(total / params.per_page))
    }

    {rows, meta}
  end

  @doc "Applies LIMIT and OFFSET to a query."
  @spec apply_pagination(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def apply_pagination(query, %{page: page, per_page: per_page}) do
    offset = (page - 1) * per_page

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  defp apply_search(query, "", _searchable), do: query
  defp apply_search(query, _search, []), do: query

  defp apply_search(query, search, searchable_columns) do
    term = "%#{search}%"

    conditions =
      Enum.reduce(searchable_columns, dynamic(false), fn col, acc ->
        dynamic([r], ^acc or ilike(field(r, ^col.name), ^term))
      end)

    where(query, ^conditions)
  end

  defp apply_filters(query, active_filters, filter_defs) do
    Enum.reduce(filter_defs, query, fn filter_def, acc ->
      case Map.get(active_filters, filter_def.field) do
        nil -> acc
        "" -> acc
        value -> apply_single_filter(acc, filter_def, value)
      end
    end)
  end

  defp apply_single_filter(query, %Filter{type: :select, field: field}, value) do
    where(query, [r], field(r, ^field) == ^value)
  end

  defp apply_single_filter(query, %Filter{type: :boolean, field: field}, "true") do
    where(query, [r], field(r, ^field) == true)
  end

  defp apply_single_filter(query, %Filter{type: :boolean, field: field}, "false") do
    where(query, [r], field(r, ^field) == false)
  end

  defp apply_single_filter(query, %Filter{type: :date_range, field: field}, value) when is_map(value) do
    query
    |> maybe_date_from(field, value["from"])
    |> maybe_date_to(field, value["to"])
  end

  defp apply_single_filter(query, _filter, _value), do: query

  defp maybe_date_from(query, _field, nil), do: query
  defp maybe_date_from(query, _field, ""), do: query

  defp maybe_date_from(query, field, from) do
    where(query, [r], field(r, ^field) >= ^from)
  end

  defp maybe_date_to(query, _field, nil), do: query
  defp maybe_date_to(query, _field, ""), do: query

  defp maybe_date_to(query, field, to) do
    where(query, [r], field(r, ^field) <= ^to)
  end

  defp apply_sort(query, sort_by, sort_dir, sortable_names) do
    if sort_by in sortable_names do
      order_by(query, [r], [{^sort_dir, field(r, ^sort_by)}])
    else
      order_by(query, [r], [desc: r.id])
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/table/query_builder_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/table/query_builder.ex test/phoenix_filament/table/query_builder_test.exs
git commit -m "feat(table): add QueryBuilder for Ecto query composition"
```

---

## Task 4: TableRenderer — Function Components

**Files:**
- Create: `lib/phoenix_filament/table/table_renderer.ex`
- Create: `test/phoenix_filament/table/table_renderer_test.exs`

- [ ] **Step 1: Write failing tests for TableRenderer**

```elixir
# test/phoenix_filament/table/table_renderer_test.exs
defmodule PhoenixFilament.Table.TableRendererTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Table.TableRenderer
  alias PhoenixFilament.Table.{Action, Filter}
  alias PhoenixFilament.Column

  describe "table_header/1" do
    test "renders sortable column header with sort indicator" do
      columns = [Column.column(:title, sortable: true), Column.column(:body)]
      assigns = %{columns: columns, sort_by: :title, sort_dir: :asc, actions: [], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_header columns={@columns} sort_by={@sort_by} sort_dir={@sort_dir} actions={@actions} target={@target} />
      """)

      assert html =~ "<th"
      assert html =~ "Title"
      assert html =~ "cursor-pointer"
    end

    test "renders non-sortable column without click handler" do
      columns = [Column.column(:body)]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :desc, actions: [], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_header columns={@columns} sort_by={@sort_by} sort_dir={@sort_dir} actions={@actions} target={@target} />
      """)

      assert html =~ "Body"
      refute html =~ "phx-click"
    end

    test "renders Actions column when actions present" do
      columns = [Column.column(:title)]
      actions = [%Action{type: :edit, label: "Edit"}]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :desc, actions: actions, target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_header columns={@columns} sort_by={@sort_by} sort_dir={@sort_dir} actions={@actions} target={@target} />
      """)

      assert html =~ "Actions"
    end
  end

  describe "table_row/1" do
    test "renders cells for each column" do
      columns = [Column.column(:title), Column.column(:views)]
      row = %{id: 1, title: "Hello", views: 42}
      assigns = %{columns: columns, row: row, actions: [], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_row columns={@columns} row={@row} actions={@actions} target={@target} />
      """)

      assert html =~ "<td"
      assert html =~ "Hello"
      assert html =~ "42"
    end

    test "renders badge for badge column" do
      columns = [Column.column(:status, badge: true)]
      row = %{id: 1, status: "active"}
      assigns = %{columns: columns, row: row, actions: [], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_row columns={@columns} row={@row} actions={@actions} target={@target} />
      """)

      assert html =~ "badge"
      assert html =~ "active"
    end

    test "renders format callback" do
      columns = [Column.column(:views, format: fn val, _row -> "#{val} views" end)]
      row = %{id: 1, views: 42}
      assigns = %{columns: columns, row: row, actions: [], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_row columns={@columns} row={@row} actions={@actions} target={@target} />
      """)

      assert html =~ "42 views"
    end

    test "renders action buttons" do
      columns = [Column.column(:title)]
      actions = [%Action{type: :edit, label: "Edit"}, %Action{type: :delete, label: "Delete", confirm: "Sure?"}]
      row = %{id: 1, title: "Hello"}
      assigns = %{columns: columns, row: row, actions: actions, target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.table_row columns={@columns} row={@row} actions={@actions} target={@target} />
      """)

      assert html =~ "Edit"
      assert html =~ "Delete"
      assert html =~ "btn"
    end
  end

  describe "pagination/1" do
    test "renders page info and navigation" do
      meta = %{total: 142, page: 2, per_page: 25, total_pages: 6}
      assigns = %{meta: meta, page_sizes: [25, 50, 100], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.pagination meta={@meta} page_sizes={@page_sizes} target={@target} />
      """)

      assert html =~ "142"
      assert html =~ "phx-click"
    end

    test "renders per-page selector" do
      meta = %{total: 100, page: 1, per_page: 25, total_pages: 4}
      assigns = %{meta: meta, page_sizes: [25, 50, 100], target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.pagination meta={@meta} page_sizes={@page_sizes} target={@target} />
      """)

      assert html =~ "<select"
      assert html =~ "25"
      assert html =~ "50"
      assert html =~ "100"
    end
  end

  describe "search_bar/1" do
    test "renders search input with debounce" do
      assigns = %{search: "", target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.search_bar search={@search} target={@target} />
      """)

      assert html =~ "input"
      assert html =~ "search"
    end
  end

  describe "empty_state/1" do
    test "renders message" do
      assigns = %{message: "No posts found", action_label: nil, action_event: nil, target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.empty_state message={@message} action_label={@action_label} action_event={@action_event} target={@target} />
      """)

      assert html =~ "No posts found"
      assert html =~ "alert"
    end

    test "renders CTA button when action provided" do
      assigns = %{message: "No posts", action_label: "Create Post", action_event: "new_post", target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.empty_state message={@message} action_label={@action_label} action_event={@action_event} target={@target} />
      """)

      assert html =~ "Create Post"
      assert html =~ "btn"
    end
  end

  describe "filter_bar/1" do
    test "renders select filter" do
      filters = [%Filter{type: :select, field: :status, label: "Status", options: ~w(draft published)}]
      assigns = %{filters: filters, active_filters: %{}, target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.filter_bar filters={@filters} active_filters={@active_filters} target={@target} />
      """)

      assert html =~ "<select"
      assert html =~ "Status"
      assert html =~ "draft"
      assert html =~ "published"
    end

    test "renders boolean filter" do
      filters = [%Filter{type: :boolean, field: :published, label: "Published only"}]
      assigns = %{filters: filters, active_filters: %{}, target: nil}

      html = rendered_to_string(~H"""
      <TableRenderer.filter_bar filters={@filters} active_filters={@active_filters} target={@target} />
      """)

      assert html =~ "Published only"
      assert html =~ ~s(type="checkbox")
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/table/table_renderer_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement TableRenderer**

```elixir
# lib/phoenix_filament/table/table_renderer.ex
defmodule PhoenixFilament.Table.TableRenderer do
  @moduledoc """
  Stateless function components for rendering table UI elements.
  Uses daisyUI 5 semantic classes.
  """

  use Phoenix.Component

  alias PhoenixFilament.Table.{Action, Filter}
  alias PhoenixFilament.Column
  import PhoenixFilament.Components.Badge, only: [badge: 1]
  import PhoenixFilament.Components.Button, only: [button: 1]

  # --- search_bar/1 ---

  @doc "Renders a search input with debounce."
  attr :search, :string, required: true
  attr :target, :any, default: nil

  def search_bar(assigns) do
    ~H"""
    <div class="mb-4">
      <input
        type="search"
        name="search"
        value={@search}
        placeholder="Search..."
        phx-change="search"
        phx-debounce="300"
        phx-target={@target}
        class="input input-bordered input-sm w-full max-w-xs"
      />
    </div>
    """
  end

  # --- filter_bar/1 ---

  @doc "Renders filter controls."
  attr :filters, :list, required: true
  attr :active_filters, :map, required: true
  attr :target, :any, default: nil

  def filter_bar(assigns) do
    ~H"""
    <div class="flex gap-2 items-end mb-4 flex-wrap">
      <.render_filter :for={filter <- @filters} filter={filter} active={Map.get(@active_filters, filter.field)} target={@target} />
    </div>
    """
  end

  attr :filter, :any, required: true
  attr :active, :any, default: nil
  attr :target, :any, default: nil

  defp render_filter(%{filter: %Filter{type: :select} = filter} = assigns) do
    ~H"""
    <div class="form-control">
      <label class="label label-text text-xs">{@filter.label}</label>
      <select
        name={"filter[#{@filter.field}]"}
        phx-change="filter"
        phx-target={@target}
        class="select select-bordered select-sm"
      >
        <option value="">All</option>
        <option :for={opt <- @filter.options} value={opt} selected={@active == opt}>{opt}</option>
      </select>
    </div>
    """
  end

  defp render_filter(%{filter: %Filter{type: :boolean} = filter} = assigns) do
    ~H"""
    <div class="form-control">
      <label class="label cursor-pointer gap-2">
        <input
          type="checkbox"
          name={"filter[#{@filter.field}]"}
          value="true"
          checked={@active == "true"}
          phx-change="filter"
          phx-target={@target}
          class="checkbox checkbox-sm"
        />
        <span class="label-text text-xs">{@filter.label}</span>
      </label>
    </div>
    """
  end

  defp render_filter(%{filter: %Filter{type: :date_range} = filter} = assigns) do
    assigns = assign(assigns, :from_val, get_in(assigns, [:active, "from"]) || "")
    assigns = assign(assigns, :to_val, get_in(assigns, [:active, "to"]) || "")

    ~H"""
    <div class="form-control">
      <label class="label label-text text-xs">{@filter.label}</label>
      <div class="flex gap-1">
        <input type="date" name={"filter[#{@filter.field}][from]"} value={@from_val} phx-change="filter" phx-target={@target} class="input input-bordered input-sm" />
        <input type="date" name={"filter[#{@filter.field}][to]"} value={@to_val} phx-change="filter" phx-target={@target} class="input input-bordered input-sm" />
      </div>
    </div>
    """
  end

  # --- table_header/1 ---

  @doc "Renders table header row with sortable columns."
  attr :columns, :list, required: true
  attr :sort_by, :atom, required: true
  attr :sort_dir, :atom, required: true
  attr :actions, :list, default: []
  attr :target, :any, default: nil

  def table_header(assigns) do
    ~H"""
    <thead>
      <tr>
        <th :for={col <- @columns} class={[Keyword.get(col.opts, :sortable, false) && "cursor-pointer hover:bg-base-200"]}>
          <span
            :if={Keyword.get(col.opts, :sortable, false)}
            phx-click="sort"
            phx-value-column={col.name}
            phx-target={@target}
          >
            {col.label}
            <span :if={@sort_by == col.name}>
              {if @sort_dir == :asc, do: "▲", else: "▼"}
            </span>
          </span>
          <span :if={!Keyword.get(col.opts, :sortable, false)}>
            {col.label}
          </span>
        </th>
        <th :if={@actions != []}>Actions</th>
      </tr>
    </thead>
    """
  end

  # --- table_row/1 ---

  @doc "Renders a single table row with cells and action buttons."
  attr :columns, :list, required: true
  attr :row, :map, required: true
  attr :actions, :list, default: []
  attr :target, :any, default: nil

  def table_row(assigns) do
    ~H"""
    <tr>
      <td :for={col <- @columns}>
        {render_cell(Map.get(@row, col.name), @row, col)}
      </td>
      <td :if={@actions != []}>
        <div class="flex gap-1">
          <.action_button :for={action <- @actions} action={action} row={@row} target={@target} />
        </div>
      </td>
    </tr>
    """
  end

  defp render_cell(value, row, col) do
    cond do
      col.opts[:format] -> col.opts[:format].(value, row)
      col.opts[:badge] -> badge_text(value)
      true -> to_string(value || "")
    end
  end

  defp badge_text(value) do
    Phoenix.HTML.raw(~s(<span class="badge badge-sm">#{Phoenix.HTML.html_escape(to_string(value || ""))}</span>))
  end

  attr :action, :any, required: true
  attr :row, :map, required: true
  attr :target, :any, default: nil

  defp action_button(%{action: %Action{type: :delete}} = assigns) do
    ~H"""
    <.button
      size={:sm}
      variant={:danger}
      phx-click="row_action"
      phx-value-action={@action.type}
      phx-value-id={@row.id}
      phx-target={@target}
    >
      {@action.label || PhoenixFilament.Naming.humanize(@action.type)}
    </.button>
    """
  end

  defp action_button(assigns) do
    ~H"""
    <.button
      size={:sm}
      variant={:ghost}
      phx-click="row_action"
      phx-value-action={@action.type}
      phx-value-id={@row.id}
      phx-target={@target}
    >
      {@action.label || PhoenixFilament.Naming.humanize(@action.type)}
    </.button>
    """
  end

  # --- pagination/1 ---

  @doc "Renders pagination controls with page navigation and per-page selector."
  attr :meta, :map, required: true
  attr :page_sizes, :list, required: true
  attr :target, :any, default: nil

  def pagination(assigns) do
    assigns = assign(assigns, :start_record, (assigns.meta.page - 1) * assigns.meta.per_page + 1)
    assigns = assign(assigns, :end_record, min(assigns.meta.page * assigns.meta.per_page, assigns.meta.total))

    ~H"""
    <div class="flex items-center justify-between mt-4">
      <div class="text-sm text-base-content/70">
        Showing {@start_record}-{@end_record} of {@meta.total}
      </div>
      <div class="flex items-center gap-4">
        <select phx-change="change_per_page" phx-target={@target} class="select select-bordered select-sm">
          <option :for={size <- @page_sizes} value={size} selected={size == @meta.per_page}>{size} per page</option>
        </select>
        <div class="join">
          <button
            :if={@meta.page > 1}
            phx-click="change_page"
            phx-value-page={@meta.page - 1}
            phx-target={@target}
            class="join-item btn btn-sm"
          >«</button>
          <button class="join-item btn btn-sm btn-active">{@meta.page}</button>
          <button
            :if={@meta.page < @meta.total_pages}
            phx-click="change_page"
            phx-value-page={@meta.page + 1}
            phx-target={@target}
            class="join-item btn btn-sm"
          >»</button>
        </div>
      </div>
    </div>
    """
  end

  # --- empty_state/1 ---

  @doc "Renders empty state when no records match."
  attr :message, :string, required: true
  attr :action_label, :string, default: nil
  attr :action_event, :string, default: nil
  attr :target, :any, default: nil

  def empty_state(assigns) do
    ~H"""
    <div class="alert mt-4">
      <span>{@message}</span>
      <.button :if={@action_label} size={:sm} phx-click={@action_event} phx-target={@target}>
        {@action_label}
      </.button>
    </div>
    """
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/table/table_renderer_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/table/table_renderer.ex test/phoenix_filament/table/table_renderer_test.exs
git commit -m "feat(table): add TableRenderer function components"
```

---

## Task 5: Extend DSL with actions/1 and filters/1

**Files:**
- Modify: `lib/phoenix_filament/resource/dsl.ex`
- Modify: `lib/phoenix_filament/resource.ex`
- Create: `test/phoenix_filament/table/dsl_test.exs`

- [ ] **Step 1: Write failing tests for extended table DSL**

```elixir
# test/phoenix_filament/table/dsl_test.exs
defmodule PhoenixFilament.Table.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Column
  alias PhoenixFilament.Table.{Action, Filter}

  describe "table DSL with actions/1" do
    test "actions block accumulates Action structs" do
      defmodule ActionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title, sortable: true)

          actions do
            action(:view, label: "View")
            action(:edit, label: "Edit")
            action(:delete, label: "Delete", confirm: "Are you sure?")
          end
        end
      end

      actions = ActionResource.__resource__(:table_actions)

      assert [%Action{type: :view}, %Action{type: :edit}, %Action{type: :delete, confirm: "Are you sure?"}] = actions
    end

    test "resource with no actions returns empty list" do
      defmodule NoActionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)
        end
      end

      assert NoActionResource.__resource__(:table_actions) == []
    end
  end

  describe "table DSL with filters/1" do
    test "filters block accumulates Filter structs" do
      defmodule FilterResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)

          filters do
            select_filter(:status, options: ~w(draft published archived))
            boolean_filter(:published, label: "Published only")
          end
        end
      end

      filters = FilterResource.__resource__(:table_filters)

      assert [%Filter{type: :select, field: :status}, %Filter{type: :boolean, field: :published}] = filters
    end

    test "resource with no filters returns empty list" do
      defmodule NoFilterResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)
        end
      end

      assert NoFilterResource.__resource__(:table_filters) == []
    end
  end

  describe "backward compatibility" do
    test "table_columns still works" do
      defmodule CompatResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title, sortable: true)
          column(:published)
        end
      end

      columns = CompatResource.__resource__(:table_columns)

      assert [%Column{name: :title}, %Column{name: :published}] = columns
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/table/dsl_test.exs`
Expected: Compilation errors

- [ ] **Step 3: Implement DSL extension**

Add to `lib/phoenix_filament/resource/dsl.ex` — new macros in `TableColumns` module:

```elixir
# In TableColumns module, add:

defmacro actions(do: block) do
  quote do
    import PhoenixFilament.Resource.DSL.TableActions
    unquote(block)
    import PhoenixFilament.Resource.DSL.TableActions, only: []
  end
end

defmacro filters(do: block) do
  quote do
    import PhoenixFilament.Resource.DSL.TableFilters
    unquote(block)
    import PhoenixFilament.Resource.DSL.TableFilters, only: []
  end
end
```

Create two new sub-modules:

```elixir
defmodule PhoenixFilament.Resource.DSL.TableActions do
  @moduledoc false

  defmacro action(type, opts \\ []) do
    quote do
      @_phx_filament_table_actions %PhoenixFilament.Table.Action{
        type: unquote(type),
        label: Keyword.get(unquote(opts), :label),
        confirm: Keyword.get(unquote(opts), :confirm),
        icon: Keyword.get(unquote(opts), :icon)
      }
    end
  end
end

defmodule PhoenixFilament.Resource.DSL.TableFilters do
  @moduledoc false

  defmacro select_filter(field, opts \\ []) do
    quote do
      @_phx_filament_table_filters %PhoenixFilament.Table.Filter{
        type: :select,
        field: unquote(field),
        label: Keyword.get(unquote(opts), :label, PhoenixFilament.Naming.humanize(unquote(field))),
        options: Keyword.get(unquote(opts), :options, []),
        composition: Keyword.get(unquote(opts), :composition, :and)
      }
    end
  end

  defmacro boolean_filter(field, opts \\ []) do
    quote do
      @_phx_filament_table_filters %PhoenixFilament.Table.Filter{
        type: :boolean,
        field: unquote(field),
        label: Keyword.get(unquote(opts), :label, PhoenixFilament.Naming.humanize(unquote(field))),
        composition: Keyword.get(unquote(opts), :composition, :and)
      }
    end
  end

  defmacro date_filter(field, opts \\ []) do
    quote do
      @_phx_filament_table_filters %PhoenixFilament.Table.Filter{
        type: :date_range,
        field: unquote(field),
        label: Keyword.get(unquote(opts), :label, PhoenixFilament.Naming.humanize(unquote(field))),
        composition: Keyword.get(unquote(opts), :composition, :and)
      }
    end
  end
end
```

Update `lib/phoenix_filament/resource.ex`:

In `__using__/1`, add:
```elixir
Module.register_attribute(__MODULE__, :_phx_filament_table_actions, accumulate: true)
Module.register_attribute(__MODULE__, :_phx_filament_table_filters, accumulate: true)
```

In `__before_compile__/1`, add:
```elixir
def __resource__(:table_actions) do
  @_phx_filament_table_actions |> Enum.reverse()
end

def __resource__(:table_filters) do
  @_phx_filament_table_filters |> Enum.reverse()
end
```

Update `@valid_resource_keys` to include `:table_actions` and `:table_filters`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/table/dsl_test.exs`
Expected: All tests pass

- [ ] **Step 5: Run full suite for regressions**

Run: `mix test --include cascade`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/phoenix_filament/resource/dsl.ex lib/phoenix_filament/resource.ex test/phoenix_filament/table/dsl_test.exs
git commit -m "feat(table): extend DSL with actions/1 and filters/1 blocks"
```

---

## Task 6: TableLive — LiveComponent

**Files:**
- Create: `lib/phoenix_filament/table/table_live.ex`

This is the orchestration layer. It uses QueryBuilder, TableRenderer, and manages the LiveView stream. Because it requires a real DB for integration testing, we test it indirectly via the other layers and defer full integration tests.

- [ ] **Step 1: Implement TableLive**

```elixir
# lib/phoenix_filament/table/table_live.ex
defmodule PhoenixFilament.Table.TableLive do
  @moduledoc """
  LiveComponent that renders a complete data table.

  Manages Ecto queries, LiveView streams, sort/pagination/search/filters,
  row actions, and URL state persistence.

  ## Example

      <.live_component
        module={PhoenixFilament.Table.TableLive}
        id="posts-table"
        schema={Post}
        repo={Repo}
        columns={@columns}
        params={@params}
      />
  """

  use Phoenix.LiveComponent

  alias PhoenixFilament.Table.{QueryBuilder, Params, TableRenderer}
  import PhoenixFilament.Components.Modal, only: [modal: 1]

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    params = Params.parse(
      socket.assigns[:params] || %{},
      page_sizes: socket.assigns[:page_sizes] || [25, 50, 100]
    )

    columns = socket.assigns.columns
    filters = socket.assigns[:filters] || []
    schema = socket.assigns[:base_query] || socket.assigns.schema
    repo = socket.assigns.repo

    query = QueryBuilder.build_query(schema, params, columns, filters)
    {rows, meta} = QueryBuilder.execute(query, repo, params)

    has_search = Enum.any?(columns, fn col -> Keyword.get(col.opts, :searchable, false) end)

    socket =
      socket
      |> assign(:parsed_params, params)
      |> assign(:meta, meta)
      |> assign(:has_search, has_search)
      |> assign(:confirm_delete, nil)
      |> assign_new(:actions, fn -> [] end)
      |> assign_new(:filters, fn -> [] end)
      |> assign_new(:page_sizes, fn -> [25, 50, 100] end)
      |> assign_new(:empty_message, fn -> "No records found" end)
      |> assign_new(:empty_action_label, fn -> nil end)
      |> assign_new(:empty_action_event, fn -> nil end)
      |> stream(:rows, rows, reset: true)

    {:ok, socket}
  end

  @impl true
  def handle_event("sort", %{"column" => column}, socket) do
    col = String.to_existing_atom(column)
    params = socket.assigns.parsed_params

    {sort_by, sort_dir} =
      if params.sort_by == col do
        {col, if(params.sort_dir == :asc, do: :desc, else: :asc)}
      else
        {col, :asc}
      end

    new_params = %{params | sort_by: sort_by, sort_dir: sort_dir, page: 1}
    push_table_patch(socket, new_params)
  end

  def handle_event("search", %{"search" => term}, socket) do
    new_params = %{socket.assigns.parsed_params | search: term, page: 1}
    push_table_patch(socket, new_params)
  end

  def handle_event("filter", %{"filter" => filter_params}, socket) do
    new_filters = Map.new(filter_params, fn {k, v} -> {String.to_existing_atom(k), v} end)
    new_params = %{socket.assigns.parsed_params | filters: new_filters, page: 1}
    push_table_patch(socket, new_params)
  rescue
    ArgumentError -> {:noreply, socket}
  end

  def handle_event("change_page", %{"page" => page}, socket) do
    new_params = %{socket.assigns.parsed_params | page: String.to_integer(page)}
    push_table_patch(socket, new_params)
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    new_params = %{socket.assigns.parsed_params | per_page: String.to_integer(per_page), page: 1}
    push_table_patch(socket, new_params)
  end

  def handle_event("row_action", %{"action" => "delete", "id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete, id)}
  end

  def handle_event("row_action", %{"action" => action, "id" => id}, socket) do
    send(self(), {:table_action, String.to_existing_atom(action), id})
    {:noreply, socket}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    send(self(), {:table_action, :delete, id})
    {:noreply, assign(socket, :confirm_delete, nil)}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, nil)}
  end

  defp push_table_patch(socket, params) do
    query_string = Params.to_query_string(params)
    send(self(), {:table_patch, query_string})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <TableRenderer.search_bar :if={@has_search} search={@parsed_params.search} target={@myself} />
      <TableRenderer.filter_bar :if={@filters != []} filters={@filters} active_filters={@parsed_params.filters} target={@myself} />

      <div :if={@meta.total > 0} class="overflow-x-auto">
        <table class="table table-zebra">
          <TableRenderer.table_header
            columns={@columns}
            sort_by={@parsed_params.sort_by}
            sort_dir={@parsed_params.sort_dir}
            actions={@actions}
            target={@myself}
          />
          <tbody id={"#{@id}-rows"} phx-update="stream">
            <tr :for={{dom_id, row} <- @streams.rows} id={dom_id}>
              <TableRenderer.table_row columns={@columns} row={row} actions={@actions} target={@myself} />
            </tr>
          </tbody>
        </table>
      </div>

      <TableRenderer.empty_state
        :if={@meta.total == 0}
        message={@empty_message}
        action_label={@empty_action_label}
        action_event={@empty_action_event}
        target={@myself}
      />

      <TableRenderer.pagination
        :if={@meta.total > 0}
        meta={@meta}
        page_sizes={@page_sizes}
        target={@myself}
      />

      <.modal
        :if={@confirm_delete}
        show={@confirm_delete != nil}
        id={"#{@id}-delete-modal"}
        on_cancel="cancel_delete"
      >
        <:header>Confirm Delete</:header>
        <p>Are you sure you want to delete this record? This action cannot be undone.</p>
        <:actions>
          <button class="btn btn-error" phx-click="confirm_delete" phx-value-id={@confirm_delete} phx-target={@myself}>Delete</button>
          <button class="btn btn-ghost" phx-click="cancel_delete" phx-target={@myself}>Cancel</button>
        </:actions>
      </.modal>
    </div>
    """
  end
end
```

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 3: Commit**

```bash
git add lib/phoenix_filament/table/table_live.ex
git commit -m "feat(table): add TableLive LiveComponent with query/stream/events"
```

---

## Task 7: Final Verification

**Files:** All test and source files from previous tasks

- [ ] **Step 1: Run the complete test suite**

Run: `mix test --include cascade`
Expected: All tests pass (178 from Phases 1-3 + new table tests)

- [ ] **Step 2: Run the code formatter**

Run: `mix format --check-formatted`
Expected: All files formatted. If not: `mix format` then re-check.

- [ ] **Step 3: Verify clean compilation with no warnings**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation, zero warnings

- [ ] **Step 4: Verify no hardcoded colors in table components**

Run: `grep -rn "bg-blue\|bg-red\|bg-green\|text-blue\|#[0-9a-fA-F]\{3,6\}" lib/phoenix_filament/table/`
Expected: No matches

- [ ] **Step 5: Verify no Tailwind class interpolation**

Run: `grep -rn '"grid-cols-#{\|"btn-#{\|"badge-#{' lib/phoenix_filament/table/`
Expected: No matches

- [ ] **Step 6: Commit any final adjustments**

```bash
git add -A
git commit -m "chore: final Phase 4 verification pass"
```

---

## Success Criteria Verification

| # | Criterion | Verified By |
|---|-----------|-------------|
| 1 | Paginated table in plain LiveView | TableLive is a LiveComponent — no Panel dependency |
| 2 | Sort by column header click | `sort` event in TableLive + sort indicator in TableRenderer |
| 3 | Search updates URL, persists | `search` event + Params.to_query_string + push_patch |
| 4 | Filters in URL, narrow results | `filter` event + QueryBuilder.apply_filters + URL persistence |
| 5 | Row actions + delete confirmation | `actions do...end` DSL + modal in TableLive |
| 6 | 10k rows, no memory growth | LiveView streams with `reset: true` — rows never in assigns |

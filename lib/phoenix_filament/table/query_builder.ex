defmodule PhoenixFilament.Table.QueryBuilder do
  @moduledoc """
  Composes Ecto queries from table params.
  Pure functions — no DB calls, no LiveView dependency.
  """

  import Ecto.Query

  alias PhoenixFilament.Table.Filter

  @doc "Builds an Ecto query from parsed params, columns, and filter declarations."
  @spec build_query(module(), map(), [PhoenixFilament.Column.t()], [Filter.t()]) :: Ecto.Query.t()
  def build_query(schema, params, columns, filters) do
    searchable =
      Enum.filter(columns, fn col -> Keyword.get(col.opts, :searchable, false) end)

    sortable_names =
      columns
      |> Enum.filter(fn col -> Keyword.get(col.opts, :sortable, false) end)
      |> Enum.map(& &1.name)

    schema
    |> apply_search(params.search, searchable)
    |> apply_filters(params.filters, filters)
    |> apply_sort(params.sort_by, params.sort_dir, sortable_names)
  end

  @doc "Executes the query with count and pagination. Returns {rows, meta}."
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
    query |> limit(^per_page) |> offset(^offset)
  end

  defp apply_search(query, "", _), do: query
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

  defp apply_single_filter(query, %Filter{type: :date_range, field: field}, value)
       when is_map(value) do
    query
    |> maybe_date_from(field, value["from"])
    |> maybe_date_to(field, value["to"])
  end

  defp apply_single_filter(query, _filter, _value), do: query

  defp maybe_date_from(query, _field, nil), do: query
  defp maybe_date_from(query, _field, ""), do: query
  defp maybe_date_from(query, field, from), do: where(query, [r], field(r, ^field) >= ^from)

  defp maybe_date_to(query, _field, nil), do: query
  defp maybe_date_to(query, _field, ""), do: query
  defp maybe_date_to(query, field, to), do: where(query, [r], field(r, ^field) <= ^to)

  defp apply_sort(query, sort_by, sort_dir, sortable_names) do
    if sort_by in sortable_names do
      order_by(query, [r], [{^sort_dir, field(r, ^sort_by)}])
    else
      order_by(query, [r], desc: r.id)
    end
  end
end

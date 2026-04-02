defmodule PhoenixFilament.Table.Params do
  @moduledoc "Parses and encodes URL query params for table state."

  @type parsed :: %{
          sort_by: atom(),
          sort_dir: :asc | :desc,
          page: pos_integer(),
          per_page: pos_integer(),
          search: String.t(),
          filters: %{atom() => String.t()}
        }

  @spec parse(map(), keyword()) :: parsed()
  def parse(params, opts \\ []) do
    page_sizes = Keyword.get(opts, :page_sizes, [25, 50, 100])
    default_per_page = hd(page_sizes)

    per_page_raw =
      params |> Map.get("per_page", to_string(default_per_page)) |> parse_int(default_per_page)

    per_page = if per_page_raw in page_sizes, do: per_page_raw, else: default_per_page

    %{
      sort_by: params |> Map.get("sort", "id") |> safe_to_atom(:id),
      sort_dir: params |> Map.get("dir", "desc") |> parse_dir(),
      page: params |> Map.get("page", "1") |> parse_int(1) |> max(1),
      per_page: per_page,
      search: Map.get(params, "search", ""),
      filters: params |> Map.get("filter", %{}) |> atomize_keys()
    }
  end

  @spec to_query_string(parsed()) :: map()
  def to_query_string(parsed) do
    base = %{
      "sort" => to_string(parsed.sort_by),
      "dir" => to_string(parsed.sort_dir),
      "page" => to_string(parsed.page),
      "per_page" => to_string(parsed.per_page)
    }

    base = if parsed.search != "", do: Map.put(base, "search", parsed.search), else: base

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

  defp safe_to_atom(str, default) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> default
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(
      for {k, v} <- map,
          atom_key = safe_to_existing_atom(k),
          atom_key != nil,
          do: {atom_key, v}
    )
  end

  defp safe_to_existing_atom(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> nil
  end
end

defmodule PhoenixFilament.Table.QueryBuilderTest do
  use ExUnit.Case, async: true

  import Ecto.Query
  alias PhoenixFilament.Table.QueryBuilder
  alias PhoenixFilament.Table.Filter
  alias PhoenixFilament.Column

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
    test "returns an Ecto.Query" do
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}
      query = QueryBuilder.build_query(@schema, params, columns(), [])
      assert %Ecto.Query{} = query
    end

    test "applies sort order" do
      params = %{sort_by: :title, sort_dir: :asc, page: 1, per_page: 25, search: "", filters: %{}}
      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)
      assert query_string =~ "order_by"
    end

    test "rejects sort on non-sortable column" do
      params = %{sort_by: :body, sort_dir: :asc, page: 1, per_page: 25, search: "", filters: %{}}
      query = QueryBuilder.build_query(@schema, params, columns(), [])
      query_string = inspect(query)
      # Should NOT sort by body (not sortable), falls back to id desc
      refute query_string =~ "asc:"
    end

    test "applies search with ilike" do
      params = %{
        sort_by: :id,
        sort_dir: :desc,
        page: 1,
        per_page: 25,
        search: "hello",
        filters: %{}
      }

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
      filters = [%Filter{type: :select, field: :published, options: ["true", "false"]}]

      params = %{
        sort_by: :id,
        sort_dir: :desc,
        page: 1,
        per_page: 25,
        search: "",
        filters: %{published: "true"}
      }

      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      query_string = inspect(query)
      assert query_string =~ "where"
    end

    test "applies boolean filter" do
      filters = [%Filter{type: :boolean, field: :published}]

      params = %{
        sort_by: :id,
        sort_dir: :desc,
        page: 1,
        per_page: 25,
        search: "",
        filters: %{published: "true"}
      }

      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      query_string = inspect(query)
      assert query_string =~ "where"
    end

    test "skips inactive filters" do
      filters = [%Filter{type: :select, field: :status, options: ~w(draft published)}]
      params = %{sort_by: :id, sort_dir: :desc, page: 1, per_page: 25, search: "", filters: %{}}
      query = QueryBuilder.build_query(@schema, params, columns(), filters)
      # Should just be a base query with sort, no where clause for status
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

    test "page 1 has offset 0" do
      query = from(p in @schema)
      result = QueryBuilder.apply_pagination(query, %{page: 1, per_page: 25})
      query_string = inspect(result)
      assert query_string =~ "offset"
    end
  end
end

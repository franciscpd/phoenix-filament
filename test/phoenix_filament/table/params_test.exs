defmodule PhoenixFilament.Table.ParamsTest do
  use ExUnit.Case, async: true
  alias PhoenixFilament.Table.Params

  describe "parse/2" do
    test "parses sort params" do
      result = Params.parse(%{"sort" => "title", "dir" => "asc"}, page_sizes: [25, 50, 100])
      assert result.sort_by == :title
      assert result.sort_dir == :asc
    end

    test "defaults to id desc" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])
      assert result.sort_by == :id
      assert result.sort_dir == :desc
    end

    test "parses pagination" do
      result = Params.parse(%{"page" => "3", "per_page" => "50"}, page_sizes: [25, 50, 100])
      assert result.page == 3
      assert result.per_page == 50
    end

    test "defaults page 1 first page_size" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])
      assert result.page == 1
      assert result.per_page == 25
    end

    test "clamps per_page to allowed" do
      result = Params.parse(%{"per_page" => "999"}, page_sizes: [25, 50, 100])
      assert result.per_page == 25
    end

    test "parses search" do
      result = Params.parse(%{"search" => "hello"}, page_sizes: [25, 50, 100])
      assert result.search == "hello"
    end

    test "defaults search to empty" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])
      assert result.search == ""
    end

    test "parses filters" do
      result =
        Params.parse(
          %{"filter" => %{"status" => "draft", "published" => "true"}},
          page_sizes: [25, 50, 100]
        )

      assert result.filters == %{status: "draft", published: "true"}
    end

    test "defaults filters to empty" do
      result = Params.parse(%{}, page_sizes: [25, 50, 100])
      assert result.filters == %{}
    end

    test "clamps page minimum 1" do
      result = Params.parse(%{"page" => "0"}, page_sizes: [25, 50, 100])
      assert result.page == 1
    end
  end

  describe "to_query_string/1" do
    test "encodes params" do
      parsed = %{
        sort_by: :title,
        sort_dir: :asc,
        page: 2,
        per_page: 25,
        search: "hello",
        filters: %{status: "draft"}
      }

      result = Params.to_query_string(parsed)
      assert result["sort"] == "title"
      assert result["dir"] == "asc"
      assert result["page"] == "2"
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

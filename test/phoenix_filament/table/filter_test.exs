defmodule PhoenixFilament.Table.FilterTest do
  use ExUnit.Case, async: true
  alias PhoenixFilament.Table.Filter

  describe "%Filter{}" do
    test "creates select filter" do
      filter = %Filter{
        type: :select,
        field: :status,
        label: "Status",
        options: ~w(draft published)
      }

      assert filter.type == :select
      assert filter.field == :status
      assert filter.options == ["draft", "published"]
      assert filter.composition == :and
    end

    test "creates boolean filter" do
      filter = %Filter{type: :boolean, field: :published, label: "Published only"}
      assert filter.type == :boolean
      assert filter.options == nil
    end

    test "creates date_range filter" do
      filter = %Filter{type: :date_range, field: :inserted_at, label: "Created"}
      assert filter.type == :date_range
    end

    test "configurable composition" do
      filter = %Filter{type: :select, field: :status, composition: :or}
      assert filter.composition == :or
    end

    test "defaults composition to :and" do
      filter = %Filter{type: :boolean, field: :active}
      assert filter.composition == :and
    end
  end
end

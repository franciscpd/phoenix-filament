defmodule PhoenixFilament.ColumnTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Column

  describe "column/2" do
    test "creates a column struct with name and auto-humanized label" do
      col = Column.column(:title, [])

      assert %Column{} = col
      assert col.name == :title
      assert col.label == "Title"
      assert col.opts == []
    end

    test "auto-humanizes multi-word atom names" do
      col = Column.column(:published_at, [])

      assert col.label == "Published at"
    end

    test "custom label overrides auto-humanized label" do
      col = Column.column(:title, label: "Post Title")

      assert col.label == "Post Title"
    end

    test "preserves opts" do
      opts = [sortable: true, searchable: true, badge: true]
      col = Column.column(:status, opts)

      assert col.opts == opts
    end

    test "default opts is empty list" do
      col = Column.column(:title)

      assert col.opts == []
    end
  end
end

defmodule PhoenixFilament.Resource.DefaultsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.{Field, Column}
  alias PhoenixFilament.Resource.Defaults
  alias PhoenixFilament.Test.Schemas.{Post, User}

  describe "form_fields/1" do
    test "generates fields from schema visible fields" do
      fields = Defaults.form_fields(Post)

      assert is_list(fields)
      assert length(fields) > 0
      assert Enum.all?(fields, &match?(%Field{}, &1))
    end

    test "maps string fields to text_input" do
      fields = Defaults.form_fields(Post)
      title = Enum.find(fields, &(&1.name == :title))

      assert title.type == :text_input
    end

    test "maps boolean fields to toggle" do
      fields = Defaults.form_fields(Post)
      published = Enum.find(fields, &(&1.name == :published))

      assert published.type == :toggle
    end

    test "maps integer fields to number_input" do
      fields = Defaults.form_fields(Post)
      views = Enum.find(fields, &(&1.name == :views))

      assert views.type == :number_input
    end

    test "maps naive_datetime to datetime" do
      fields = Defaults.form_fields(Post)
      pub_at = Enum.find(fields, &(&1.name == :published_at))

      assert pub_at.type == :datetime
    end

    test "excludes sensitive fields from User schema" do
      fields = Defaults.form_fields(User)
      names = Enum.map(fields, & &1.name)

      refute :password_hash in names
      refute :confirmation_token in names
    end

    test "auto-humanizes labels" do
      fields = Defaults.form_fields(Post)
      pub_at = Enum.find(fields, &(&1.name == :published_at))

      assert pub_at.label == "Published at"
    end
  end

  describe "table_columns/1" do
    test "generates columns from schema visible fields" do
      columns = Defaults.table_columns(Post)

      assert is_list(columns)
      assert length(columns) > 0
      assert Enum.all?(columns, &match?(%Column{}, &1))
    end

    test "all columns are sortable by default" do
      columns = Defaults.table_columns(Post)

      assert Enum.all?(columns, fn col -> col.opts[:sortable] == true end)
    end

    test "excludes sensitive fields from User schema" do
      columns = Defaults.table_columns(User)
      names = Enum.map(columns, & &1.name)

      refute :password_hash in names
      refute :confirmation_token in names
    end
  end
end

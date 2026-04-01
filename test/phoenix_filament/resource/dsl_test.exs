defmodule PhoenixFilament.Resource.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.{Field, Column}

  describe "form block accumulation" do
    defmodule FormResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input(:title, required: true, placeholder: "Enter title")
        textarea(:body, rows: 5)
        toggle(:published)
        select(:status, options: ~w(draft published archived))
      end
    end

    test "accumulates fields in declaration order" do
      fields = FormResource.__resource__(:form_fields)

      assert length(fields) == 4

      assert [
               %Field{name: :title},
               %Field{name: :body},
               %Field{name: :published},
               %Field{name: :status}
             ] = fields
    end

    test "fields have correct types" do
      fields = FormResource.__resource__(:form_fields)

      assert Enum.at(fields, 0).type == :text_input
      assert Enum.at(fields, 1).type == :textarea
      assert Enum.at(fields, 2).type == :toggle
      assert Enum.at(fields, 3).type == :select
    end

    test "fields preserve opts" do
      fields = FormResource.__resource__(:form_fields)

      title = Enum.at(fields, 0)
      assert title.opts[:required] == true
      assert title.opts[:placeholder] == "Enter title"

      body = Enum.at(fields, 1)
      assert body.opts[:rows] == 5
    end

    test "fields have auto-humanized labels" do
      fields = FormResource.__resource__(:form_fields)

      assert Enum.at(fields, 0).label == "Title"
      assert Enum.at(fields, 2).label == "Published"
    end
  end

  describe "table block accumulation" do
    defmodule TableResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      table do
        column(:title, sortable: true)
        column(:published, badge: true)
        column(:inserted_at, label: "Created")
      end
    end

    test "accumulates columns in declaration order" do
      columns = TableResource.__resource__(:table_columns)

      assert length(columns) == 3

      assert [
               %Column{name: :title},
               %Column{name: :published},
               %Column{name: :inserted_at}
             ] = columns
    end

    test "columns preserve opts" do
      columns = TableResource.__resource__(:table_columns)

      assert Enum.at(columns, 0).opts[:sortable] == true
      assert Enum.at(columns, 1).opts[:badge] == true
    end

    test "columns support custom labels" do
      columns = TableResource.__resource__(:table_columns)

      assert Enum.at(columns, 2).label == "Created"
    end
  end

  describe "mixed form and table blocks" do
    defmodule MixedResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input(:title)
        textarea(:body)
      end

      table do
        column(:title, sortable: true)
      end
    end

    test "form block fields are independent from table columns" do
      fields = MixedResource.__resource__(:form_fields)
      columns = MixedResource.__resource__(:table_columns)

      assert length(fields) == 2
      assert length(columns) == 1
    end
  end

  describe "partial override" do
    defmodule FormOnlyResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input(:title)
      end
    end

    test "custom form with auto-discovered table" do
      fields = FormOnlyResource.__resource__(:form_fields)
      columns = FormOnlyResource.__resource__(:table_columns)

      assert length(fields) == 1
      assert hd(fields).name == :title

      assert length(columns) > 1
      assert Enum.all?(columns, &match?(%Column{}, &1))
    end
  end
end

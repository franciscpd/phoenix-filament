defmodule PhoenixFilament.FieldTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Field

  describe "new/3" do
    test "creates a field struct with name, type, and default label" do
      field = Field.new(:title, :text_input, [])

      assert %Field{} = field
      assert field.name == :title
      assert field.type == :text_input
      assert field.label == "Title"
      assert field.opts == []
    end

    test "auto-humanizes multi-word atom names" do
      field = Field.new(:published_at, :datetime, [])

      assert field.label == "Published at"
    end

    test "custom label overrides auto-humanized label" do
      field = Field.new(:title, :text_input, label: "Post Title")

      assert field.label == "Post Title"
    end

    test "preserves opts in the struct" do
      opts = [required: true, placeholder: "Enter title", max_length: 255]
      field = Field.new(:title, :text_input, opts)

      assert field.opts == opts
    end
  end

  describe "constructor functions" do
    test "text_input/2 creates a :text_input field" do
      field = Field.text_input(:name, required: true)

      assert field.type == :text_input
      assert field.name == :name
      assert field.opts == [required: true]
    end

    test "textarea/2 creates a :textarea field" do
      field = Field.textarea(:body, rows: 5)

      assert field.type == :textarea
      assert field.opts == [rows: 5]
    end

    test "number_input/2 creates a :number_input field" do
      field = Field.number_input(:age, min: 0, max: 150)

      assert field.type == :number_input
    end

    test "select/2 creates a :select field" do
      field = Field.select(:role, options: ~w(admin user))

      assert field.type == :select
      assert field.opts == [options: ~w(admin user)]
    end

    test "checkbox/2 creates a :checkbox field" do
      field = Field.checkbox(:agree)

      assert field.type == :checkbox
    end

    test "toggle/2 creates a :toggle field" do
      field = Field.toggle(:published)

      assert field.type == :toggle
    end

    test "date/2 creates a :date field" do
      field = Field.date(:birthday)

      assert field.type == :date
    end

    test "datetime/2 creates a :datetime field" do
      field = Field.datetime(:published_at)

      assert field.type == :datetime
    end

    test "hidden/2 creates a :hidden field" do
      field = Field.hidden(:secret_id)

      assert field.type == :hidden
    end

    test "constructors with no opts default to empty list" do
      field = Field.text_input(:name)

      assert field.opts == []
    end
  end
end

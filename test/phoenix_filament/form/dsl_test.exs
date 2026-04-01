defmodule PhoenixFilament.Form.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Field
  alias PhoenixFilament.Form.{Section, Columns, Schema}

  describe "form DSL with section/2" do
    test "section wraps fields in Section struct" do
      defmodule SectionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          section "Basic Info" do
            text_input(:title, required: true)
            textarea(:body)
          end
        end
      end

      schema = SectionResource.__resource__(:form_schema)
      assert [%Section{label: "Basic Info", items: items}] = schema
      assert [%Field{name: :title}, %Field{name: :body}] = items
    end

    test "mixes top-level fields and sections" do
      defmodule MixedResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          text_input(:title)

          section "Details" do
            textarea(:body)
            toggle(:published)
          end
        end
      end

      schema = MixedResource.__resource__(:form_schema)
      assert [%Field{name: :title}, %Section{label: "Details", items: items}] = schema
      assert [%Field{name: :body}, %Field{name: :published}] = items
    end

    test "section with visible_when" do
      defmodule VisibleSectionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          select(:status, options: ~w(draft published))

          section "Publishing", visible_when: {:status, :eq, "published"} do
            date(:published_at)
          end
        end
      end

      schema = VisibleSectionResource.__resource__(:form_schema)

      assert [
               %Field{name: :status},
               %Section{label: "Publishing", visible_when: {:status, :eq, "published"}}
             ] = schema
    end
  end

  describe "form DSL with columns/2" do
    test "columns wraps fields in Columns struct" do
      defmodule ColumnsResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          columns 2 do
            text_input(:title)
            text_input(:body)
          end
        end
      end

      schema = ColumnsResource.__resource__(:form_schema)
      assert [%Columns{count: 2, items: items}] = schema
      assert [%Field{name: :title}, %Field{name: :body}] = items
    end

    test "columns inside section" do
      defmodule NestedColumnsResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          section "Author" do
            columns 2 do
              text_input(:title)
              text_input(:body)
            end

            textarea(:body)
          end
        end
      end

      schema = NestedColumnsResource.__resource__(:form_schema)
      assert [%Section{label: "Author", items: items}] = schema
      assert [%Columns{count: 2, items: col_items}, %Field{name: :body}] = items
      assert [%Field{name: :title}, %Field{name: :body}] = col_items
    end
  end

  describe "form DSL with visible_when on fields" do
    test "visible_when stored in Field opts" do
      defmodule FieldVisibilityResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          toggle(:published)
          date(:published_at, visible_when: {:published, :eq, true})
        end
      end

      schema = FieldVisibilityResource.__resource__(:form_schema)
      assert [%Field{name: :published}, %Field{name: :published_at, opts: opts}] = schema
      assert opts[:visible_when] == {:published, :eq, true}
    end
  end

  describe "Schema.extract_fields/1" do
    test "extracts flat fields from nested schema" do
      schema = [
        Field.text_input(:title),
        %Section{
          label: "Details",
          items: [
            %Columns{
              count: 2,
              items: [
                Field.text_input(:first),
                Field.text_input(:last)
              ]
            },
            Field.textarea(:bio)
          ]
        }
      ]

      fields = Schema.extract_fields(schema)

      assert length(fields) == 4
      assert Enum.map(fields, & &1.name) == [:title, :first, :last, :bio]
    end

    test "returns flat list unchanged" do
      schema = [Field.text_input(:title), Field.textarea(:body)]
      fields = Schema.extract_fields(schema)

      assert length(fields) == 2
      assert Enum.map(fields, & &1.name) == [:title, :body]
    end
  end

  describe "backward compatibility" do
    test "flat fields still work (no sections)" do
      defmodule FlatResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          text_input(:title)
          textarea(:body)
        end
      end

      schema = FlatResource.__resource__(:form_schema)
      assert [%Field{name: :title}, %Field{name: :body}] = schema
    end

    test "resource with no form block auto-discovers fields" do
      defmodule AutoResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo
      end

      schema = AutoResource.__resource__(:form_schema)
      assert is_list(schema)
      assert length(schema) > 0
      assert Enum.all?(schema, &match?(%Field{}, &1))
    end
  end
end

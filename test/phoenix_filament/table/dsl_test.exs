defmodule PhoenixFilament.Table.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Column
  alias PhoenixFilament.Table.{Action, Filter}

  describe "table DSL with actions/1" do
    test "actions block accumulates Action structs" do
      defmodule ActionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title, sortable: true)

          actions do
            action(:view, label: "View")
            action(:edit, label: "Edit")
            action(:delete, label: "Delete", confirm: "Are you sure?")
          end
        end
      end

      actions = ActionResource.__resource__(:table_actions)
      assert length(actions) == 3

      assert [
               %Action{type: :view, label: "View"},
               %Action{type: :edit, label: "Edit"},
               %Action{type: :delete, confirm: "Are you sure?"}
             ] = actions
    end

    test "resource with no actions returns empty list" do
      defmodule NoActionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)
        end
      end

      assert NoActionResource.__resource__(:table_actions) == []
    end
  end

  describe "table DSL with filters/1" do
    test "filters block accumulates Filter structs" do
      defmodule FilterResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)

          filters do
            select_filter(:status, options: ~w(draft published archived))
            boolean_filter(:published, label: "Published only")
          end
        end
      end

      filters = FilterResource.__resource__(:table_filters)
      assert length(filters) == 2

      assert [
               %Filter{type: :select, field: :status},
               %Filter{type: :boolean, field: :published}
             ] = filters
    end

    test "resource with no filters returns empty list" do
      defmodule NoFilterResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title)
        end
      end

      assert NoFilterResource.__resource__(:table_filters) == []
    end
  end

  describe "backward compatibility" do
    test "table_columns still works" do
      defmodule CompatResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        table do
          column(:title, sortable: true)
          column(:published)
        end
      end

      columns = CompatResource.__resource__(:table_columns)
      assert [%Column{name: :title}, %Column{name: :published}] = columns
    end
  end
end

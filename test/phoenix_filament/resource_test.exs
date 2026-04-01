defmodule PhoenixFilament.ResourceTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Schemas.Post

  describe "__using__ macro with NimbleOptions" do
    test "valid options compile without errors" do
      defmodule ValidResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo
      end

      assert ValidResource.__resource__(:schema) == Post
    end

    test "missing :schema raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/required :schema option/, fn ->
        defmodule BadResource1 do
          use PhoenixFilament.Resource, repo: SomeRepo
        end
      end
    end

    test "missing :repo raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/required :repo option/, fn ->
        defmodule BadResource2 do
          use PhoenixFilament.Resource, schema: SomeSchema
        end
      end
    end

    test "unknown option raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options/, fn ->
        defmodule BadResource3 do
          use PhoenixFilament.Resource,
            schema: SomeSchema,
            repo: SomeRepo,
            bogus: true
        end
      end
    end
  end

  describe "__resource__/1 accessors" do
    defmodule TestResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo,
        label: "Blog Post",
        icon: "document"
    end

    test "returns schema module" do
      assert TestResource.__resource__(:schema) == Post
    end

    test "returns repo module" do
      assert TestResource.__resource__(:repo) == PhoenixFilament.Test.FakeRepo
    end

    test "returns validated options" do
      opts = TestResource.__resource__(:opts)

      assert opts[:label] == "Blog Post"
      assert opts[:icon] == "document"
    end

    test "returns form_fields (auto-discovered since no form block)" do
      fields = TestResource.__resource__(:form_fields)

      assert is_list(fields)
      assert length(fields) > 0
      assert Enum.all?(fields, &match?(%PhoenixFilament.Field{}, &1))
    end

    test "returns table_columns (auto-discovered since no table block)" do
      columns = TestResource.__resource__(:table_columns)

      assert is_list(columns)
      assert length(columns) > 0
      assert Enum.all?(columns, &match?(%PhoenixFilament.Column{}, &1))
    end
  end
end

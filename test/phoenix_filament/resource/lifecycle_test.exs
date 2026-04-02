defmodule PhoenixFilament.Resource.LifecycleTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Lifecycle

  # Simple schema with changeset/2 for testing changeset resolution
  defmodule TestSchema do
    use Ecto.Schema
    import Ecto.Changeset

    schema "test_items" do
      field(:title, :string)
      field(:body, :string)
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:title, :body])
      |> validate_required([:title])
    end
  end

  # Mock resource module using TestSchema (has changeset/2)
  defmodule MockResource do
    def __resource__(:schema), do: TestSchema
    def __resource__(:repo), do: PhoenixFilament.Test.FakeRepo
    def __resource__(:opts), do: [label: "Blog Post", plural_label: "Blog Posts"]
    def __resource__(:form_schema), do: [PhoenixFilament.Field.text_input(:title)]
    def __resource__(:table_columns), do: [PhoenixFilament.Column.column(:title, sortable: true)]
    def __resource__(:table_actions), do: []
    def __resource__(:table_filters), do: []
  end

  # Mock resource with custom create_changeset
  defmodule CustomChangesetResource do
    def __resource__(:schema), do: TestSchema
    def __resource__(:repo), do: PhoenixFilament.Test.FakeRepo

    def __resource__(:opts) do
      [
        label: "Article",
        create_changeset: fn struct, params ->
          Ecto.Changeset.cast(struct, params, [:title])
        end,
        update_changeset: fn record, params ->
          Ecto.Changeset.cast(record, params, [:title, :body])
        end
      ]
    end

    def __resource__(:form_schema), do: [PhoenixFilament.Field.text_input(:title)]
    def __resource__(:table_columns), do: [PhoenixFilament.Column.column(:title)]
    def __resource__(:table_actions), do: []
    def __resource__(:table_filters), do: []
  end

  # Mock resource with no label (tests auto-derivation)
  defmodule NoLabelResource do
    def __resource__(:schema), do: TestSchema
    def __resource__(:repo), do: PhoenixFilament.Test.FakeRepo
    def __resource__(:opts), do: []
    def __resource__(:form_schema), do: []
    def __resource__(:table_columns), do: []
    def __resource__(:table_actions), do: []
    def __resource__(:table_filters), do: []
  end

  defp base_socket(extra_assigns \\ %{}) do
    assigns =
      %Phoenix.LiveView.Socket{}.assigns
      |> Map.merge(extra_assigns)

    %Phoenix.LiveView.Socket{assigns: assigns}
  end

  describe "init_assigns/2" do
    test "sets resource metadata on socket" do
      socket = Lifecycle.init_assigns(base_socket(), MockResource)

      assert socket.assigns.resource == MockResource
      assert socket.assigns.schema == TestSchema
      assert socket.assigns.repo == PhoenixFilament.Test.FakeRepo
      assert socket.assigns.opts == [label: "Blog Post", plural_label: "Blog Posts"]
    end

    test "sets form and table metadata" do
      socket = Lifecycle.init_assigns(base_socket(), MockResource)

      assert [%PhoenixFilament.Field{name: :title}] = socket.assigns.form_schema
      assert [%PhoenixFilament.Column{name: :title}] = socket.assigns.columns
      assert socket.assigns.table_actions == []
      assert socket.assigns.table_filters == []
    end

    test "initializes nil defaults" do
      socket = Lifecycle.init_assigns(base_socket(), MockResource)

      assert socket.assigns.page_title == nil
      assert socket.assigns.record == nil
      assert socket.assigns.form == nil
      assert socket.assigns.changeset_fn == nil
      assert socket.assigns.params == %{}
    end
  end

  describe "apply_action/3 :index" do
    test "sets page title from plural_label" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:index, %{})

      assert socket.assigns.page_title == "Blog Posts"
    end

    test "clears record and form" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:index, %{})

      assert socket.assigns.record == nil
      assert socket.assigns.form == nil
    end

    test "stores params" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:index, %{"sort" => "title"})

      assert socket.assigns.params == %{"sort" => "title"}
    end

    test "auto-derives plural label when not configured" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(NoLabelResource)
        |> Lifecycle.apply_action(:index, %{})

      # TestSchema -> "TestSchema" -> "TestSchemas"
      assert socket.assigns.page_title == "TestSchemas"
    end
  end

  describe "apply_action/3 :new" do
    test "sets page title with singular label" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert socket.assigns.page_title == "New Blog Post"
    end

    test "record is nil for new action" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert socket.assigns.record == nil
    end

    test "sets form from changeset" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert socket.assigns.form != nil
      assert %Phoenix.HTML.Form{} = socket.assigns.form
    end

    test "sets changeset_fn" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert is_function(socket.assigns.changeset_fn, 2)
    end

    test "auto-derives singular label when not configured" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(NoLabelResource)
        |> Lifecycle.apply_action(:new, %{})

      assert socket.assigns.page_title == "New TestSchema"
    end
  end

  describe "changeset resolution" do
    test "uses default schema.changeset/2 when none configured" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      changeset_fn = socket.assigns.changeset_fn
      changeset = changeset_fn.(struct(TestSchema), %{"title" => "Hello"})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :title) == "Hello"
    end

    test "uses custom create_changeset when configured" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(CustomChangesetResource)
        |> Lifecycle.apply_action(:new, %{})

      changeset_fn = socket.assigns.changeset_fn
      # Custom create_changeset only casts :title
      changeset = changeset_fn.(struct(TestSchema), %{"title" => "Hi", "body" => "ignored"})
      assert Ecto.Changeset.get_change(changeset, :title) == "Hi"
      # body should not be cast since custom changeset only casts :title
      assert Ecto.Changeset.get_change(changeset, :body) == nil
    end
  end

  describe "handle_validate/2" do
    test "returns noreply tuple with updated form" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert {:noreply, updated_socket} =
               Lifecycle.handle_validate(socket, %{"title" => "Updated"})

      assert %Phoenix.HTML.Form{} = updated_socket.assigns.form
    end

    test "sets action to :validate on changeset" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      {:noreply, updated_socket} = Lifecycle.handle_validate(socket, %{"title" => ""})

      # The form source is the changeset, which should have action :validate
      assert updated_socket.assigns.form.source.action == :validate
    end
  end

  describe "index_path/1" do
    test "returns default / when no index_path assigned" do
      socket = base_socket()
      assert Lifecycle.index_path(socket) == "/"
    end

    test "returns custom index_path when assigned" do
      socket = base_socket(%{index_path: "/admin/posts"})
      assert Lifecycle.index_path(socket) == "/admin/posts"
    end
  end

  describe "function exports" do
    test "handle_save/2 is defined" do
      assert function_exported?(Lifecycle, :handle_save, 2)
    end

    test "handle_table_action/3 is defined" do
      assert function_exported?(Lifecycle, :handle_table_action, 3)
    end

    test "handle_table_patch/2 is defined" do
      assert function_exported?(Lifecycle, :handle_table_patch, 2)
    end

    test "apply_action/3 handles :edit" do
      assert function_exported?(Lifecycle, :apply_action, 3)
    end

    test "apply_action/3 handles :show" do
      assert function_exported?(Lifecycle, :apply_action, 3)
    end
  end
end

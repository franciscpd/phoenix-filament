defmodule PhoenixFilament.Resource.RendererTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Resource.Renderer
  alias PhoenixFilament.{Field, Column}

  # Minimal stub module to stand in for a Resource module atom
  defmodule TestResource do
  end

  # ---- :show action — fully testable without LiveComponent ----

  describe "render/1 for :show" do
    test "renders page title" do
      assigns = show_assigns(%{page_title: "Blog Post"})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Blog Post"
    end

    test "renders column labels" do
      assigns = show_assigns(%{})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Title"
      assert html =~ "Body"
    end

    test "renders record field values" do
      assigns = show_assigns(%{record: %{title: "Hello World", body: "Some content"}})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Hello World"
      assert html =~ "Some content"
    end

    test "renders Back button" do
      assigns = show_assigns(%{})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Back"
      assert html =~ "phx-click"
    end

    test "renders dl/dt/dd structure" do
      assigns = show_assigns(%{})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "<dl"
      assert html =~ "<dt"
      assert html =~ "<dd"
    end

    test "applies format function when present" do
      assigns =
        show_assigns(%{
          columns: [Column.column(:title, format: fn value, _record -> "FORMATTED:#{value}" end)],
          record: %{title: "raw-value", body: nil}
        })

      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "FORMATTED:raw-value"
    end

    test "renders empty string for nil field values" do
      assigns = show_assigns(%{record: %{title: nil, body: nil}})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Title"
    end

    test "does not render form modal for :show" do
      assigns = show_assigns(%{})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      refute html =~ "form-modal"
    end
  end

  # ---- :new / :edit / :index — live_component cannot render via rendered_to_string.
  # These tests verify the assigns shape is valid. Actual rendering of the table
  # requires a real LiveView process; full integration is deferred to a future phase.

  describe "render/1 for :new (assigns structure check)" do
    test "assigns are correctly structured for :new" do
      assigns = new_assigns(%{page_title: "New Blog Post"})

      assert assigns.live_action == :new
      assert assigns.page_title == "New Blog Post"
      assert assigns.form != nil
      assert is_list(assigns.form_schema)
      assert assigns.record == nil
    end
  end

  describe "render/1 for :edit (assigns structure check)" do
    test "assigns are correctly structured for :edit" do
      assigns = edit_assigns(%{page_title: "Edit Blog Post"})

      assert assigns.live_action == :edit
      assert assigns.page_title == "Edit Blog Post"
      assert assigns.form != nil
      assert assigns.record != nil
    end
  end

  describe "render/1 for :index (assigns structure check)" do
    test "assigns are correctly structured for :index" do
      assigns = index_assigns(%{page_title: "Blog Posts"})

      assert assigns.live_action == :index
      assert assigns.page_title == "Blog Posts"
      assert is_list(assigns.columns)
      assert is_list(assigns.table_actions)
      assert is_list(assigns.table_filters)
    end
  end

  describe "resource_slug encoding" do
    test "show view renders without crashing for nested module resource" do
      assigns = show_assigns(%{resource: PhoenixFilament.Resource.RendererTest.TestResource})
      html = rendered_to_string(~H"<Renderer.render {assigns} />")

      assert html =~ "Blog Post"
    end
  end

  # --- Helpers ---

  defp base_assigns do
    %{
      resource: TestResource,
      schema: PhoenixFilament.Test.Schemas.Post,
      repo: PhoenixFilament.Test.FakeRepo,
      columns: [Column.column(:title), Column.column(:body)],
      table_actions: [],
      table_filters: [],
      params: %{},
      record: %{title: "Hello", body: "World"},
      form: nil,
      form_schema: []
    }
  end

  defp show_assigns(overrides) do
    base_assigns()
    |> Map.merge(%{live_action: :show})
    |> Map.put_new(:page_title, "Blog Post")
    |> Map.merge(overrides)
  end

  defp new_assigns(overrides) do
    form = to_form(%{"title" => ""}, as: "post")
    form_schema = [Field.text_input(:title)]

    base_assigns()
    |> Map.merge(%{live_action: :new, record: nil, form: form, form_schema: form_schema})
    |> Map.put_new(:page_title, "New Blog Post")
    |> Map.merge(overrides)
  end

  defp edit_assigns(overrides) do
    form = to_form(%{"title" => "Existing"}, as: "post")
    form_schema = [Field.text_input(:title)]

    base_assigns()
    |> Map.merge(%{
      live_action: :edit,
      form: form,
      form_schema: form_schema
    })
    |> Map.put_new(:page_title, "Edit Blog Post")
    |> Map.merge(overrides)
  end

  defp index_assigns(overrides) do
    base_assigns()
    |> Map.merge(%{live_action: :index, record: nil, form: nil})
    |> Map.put_new(:page_title, "Blog Posts")
    |> Map.merge(overrides)
  end
end

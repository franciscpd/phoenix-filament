defmodule PhoenixFilament.Components.InputTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Components.Input

  defp form_field(params, field_name, opts \\ []) do
    as = Keyword.get(opts, :as, :post)
    form = to_form(params, as: to_string(as))
    form[field_name]
  end

  describe "text_input/1" do
    test "renders input with correct type and daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{"title" => "Hello"}, :title)} />
        """)

      assert html =~ ~s(type="text")
      assert html =~ "input input-bordered"
      assert html =~ ~s(value="Hello")
    end

    test "renders label when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} label="Title" />
        """)

      assert html =~ "<label"
      assert html =~ "Title"
    end

    test "omits label when nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} />
        """)

      refute html =~ "<label"
    end

    test "renders required asterisk" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} label="Title" required />
        """)

      assert html =~ "*"
    end

    test "renders placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} placeholder="Enter title" />
        """)

      assert html =~ ~s(placeholder="Enter title")
    end

    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} disabled />
        """)

      assert html =~ "disabled"
    end

    test "merges custom class with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} class="mt-4" />
        """)

      assert html =~ "input input-bordered"
      assert html =~ "mt-4"
    end

    test "renders errors with role alert" do
      field = %Phoenix.HTML.FormField{
        id: "post_title",
        name: "post[title]",
        value: "",
        errors: ["can't be blank"],
        field: :title,
        form: %Phoenix.HTML.Form{
          source: %{},
          impl: Phoenix.HTML.FormData.Map,
          id: "post",
          name: "post",
          data: %{},
          action: nil,
          hidden: [],
          params: %{},
          errors: [],
          options: [],
          index: nil
        }
      }

      assigns = %{field: field}

      html =
        rendered_to_string(~H"""
        <Input.text_input field={@field} label="Title" />
        """)

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
      assert html =~ ~s(role="alert")
      assert html =~ "input-error"
    end
  end

  describe "textarea/1" do
    test "renders textarea with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.textarea field={form_field(%{"body" => "Content"}, :body)} />
        """)

      assert html =~ "<textarea"
      assert html =~ "textarea textarea-bordered"
      assert html =~ "Content"
    end

    test "renders with custom rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.textarea field={form_field(%{}, :body)} rows={5} />
        """)

      assert html =~ ~s(rows="5")
    end
  end

  describe "number_input/1" do
    test "renders number input with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.number_input field={form_field(%{"views" => "42"}, :views)} />
        """)

      assert html =~ ~s(type="number")
      assert html =~ "input input-bordered"
    end

    test "renders with min, max, step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.number_input field={form_field(%{}, :views)} min={0} max={100} step={1} />
        """)

      assert html =~ ~s(min="0")
      assert html =~ ~s(max="100")
      assert html =~ ~s(step="1")
    end
  end

  describe "select/1" do
    test "renders select with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "draft"}, :status)}
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        />
        """)

      assert html =~ "<select"
      assert html =~ "select select-bordered"
      assert html =~ "<option"
      assert html =~ "Draft"
    end

    test "renders prompt option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{}, :status)}
          options={[{"Draft", "draft"}]}
          prompt="Choose status"
        />
        """)

      assert html =~ "Choose status"
    end

    test "renders string options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "draft"}, :status)}
          options={["draft", "published", "archived"]}
        />
        """)

      assert html =~ "draft"
      assert html =~ "published"
    end

    test "marks selected option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "published"}, :status)}
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        />
        """)

      assert html =~ ~s(selected)
    end
  end

  describe "checkbox/1" do
    test "renders checkbox with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.checkbox field={form_field(%{"published" => "true"}, :published)} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "checkbox"
    end

    test "renders label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.checkbox field={form_field(%{}, :published)} label="Published" />
        """)

      assert html =~ "Published"
    end
  end

  describe "toggle/1" do
    test "renders toggle with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.toggle field={form_field(%{"active" => "true"}, :active)} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "toggle"
    end

    test "renders label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.toggle field={form_field(%{}, :active)} label="Active" />
        """)

      assert html =~ "Active"
    end
  end

  describe "date/1" do
    test "renders native date input with daisyUI classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.date field={form_field(%{"published_at" => "2026-04-01"}, :published_at)} />
        """)

      assert html =~ ~s(type="date")
      assert html =~ "input input-bordered"
      assert html =~ ~s(value="2026-04-01")
    end

    test "renders with min and max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.date field={form_field(%{}, :published_at)} min="2026-01-01" max="2026-12-31" />
        """)

      assert html =~ ~s(min="2026-01-01")
      assert html =~ ~s(max="2026-12-31")
    end
  end

  describe "datetime/1" do
    test "renders native datetime-local input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.datetime field={form_field(%{"starts_at" => "2026-04-01T10:30"}, :starts_at)} />
        """)

      assert html =~ ~s(type="datetime-local")
      assert html =~ "input input-bordered"
    end
  end

  describe "hidden/1" do
    test "renders hidden input with no wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.hidden field={form_field(%{"id" => "42"}, :id)} />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="42")
      refute html =~ "<label"
      refute html =~ "input-bordered"
    end
  end
end

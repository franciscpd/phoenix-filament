defmodule PhoenixFilament.Components.InputTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Components.Input

  defp form_field(params \\ %{}, field_name, opts \\ []) do
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
      assigns = %{}

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

      html =
        rendered_to_string(~H"""
        <Input.text_input field={field} label="Title" />
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
end

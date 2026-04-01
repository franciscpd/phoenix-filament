defmodule PhoenixFilament.Form.FormBuilderTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Form.FormBuilder
  alias PhoenixFilament.Form.{Section, Columns}
  alias PhoenixFilament.Field

  defp post_form(params \\ %{}) do
    to_form(params, as: "post")
  end

  describe "form_builder/1 with flat fields" do
    test "renders form with fields and submit button" do
      form = post_form(%{"title" => "Hello", "body" => "World"})
      schema = [Field.text_input(:title), Field.textarea(:body)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} phx-change="validate" phx-submit="save" />
        """)

      assert html =~ "<form"
      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-submit="save")
      assert html =~ ~s(type="text")
      assert html =~ "<textarea"
      assert html =~ "Save"
    end

    test "renders custom submit label" do
      form = post_form()
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit_label="Create Post" />
        """)

      assert html =~ "Create Post"
    end

    test "hides submit button when submit is false" do
      form = post_form()
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      refute html =~ ~s(type="submit")
    end
  end

  describe "form_builder/1 with sections" do
    test "renders section as fieldset with legend" do
      form = post_form(%{"title" => "", "body" => ""})

      schema = [
        %Section{
          label: "Basic Info",
          items: [
            Field.text_input(:title),
            Field.textarea(:body)
          ]
        }
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "<fieldset"
      assert html =~ "Basic Info"
      assert html =~ ~s(type="text")
    end
  end

  describe "form_builder/1 with columns" do
    test "renders columns as CSS grid" do
      form = post_form(%{"first" => "", "last" => ""})

      schema = [
        %Columns{
          count: 2,
          items: [
            Field.text_input(:first),
            Field.text_input(:last)
          ]
        }
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "grid-cols-2"
      assert html =~ "gap-4"
    end
  end

  describe "form_builder/1 with nested layout" do
    test "renders section with columns inside" do
      form = post_form(%{"first" => "", "last" => "", "bio" => ""})

      schema = [
        %Section{
          label: "Author",
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

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "<fieldset"
      assert html =~ "Author"
      assert html =~ "grid-cols-2"
      assert html =~ "<textarea"
    end
  end
end

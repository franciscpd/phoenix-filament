defmodule PhoenixFilament.Components.FieldRendererTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.FieldRenderer
  alias PhoenixFilament.Field

  defp post_form(params) do
    to_form(params, as: "post")
  end

  describe "render_field/1" do
    test "dispatches text_input field" do
      field = Field.text_input(:title, required: true)
      form = post_form(%{"title" => "Hello"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="text")
      assert html =~ "Title"
    end

    test "dispatches textarea field" do
      field = Field.textarea(:body, rows: 5)
      form = post_form(%{"body" => "Content"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ "<textarea"
      assert html =~ "Body"
    end

    test "dispatches number_input field" do
      field = Field.number_input(:views)
      form = post_form(%{"views" => "42"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="number")
    end

    test "dispatches select field" do
      field = Field.select(:status, options: [{"Draft", "draft"}, {"Published", "published"}])
      form = post_form(%{"status" => "draft"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ "<select"
    end

    test "dispatches checkbox field" do
      field = Field.checkbox(:active)
      form = post_form(%{"active" => "true"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="checkbox")
      assert html =~ "checkbox"
    end

    test "dispatches toggle field" do
      field = Field.toggle(:published)
      form = post_form(%{"published" => "false"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="checkbox")
      assert html =~ "toggle"
    end

    test "dispatches date field" do
      field = Field.date(:published_at)
      form = post_form(%{"published_at" => "2026-04-01"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="date")
    end

    test "dispatches datetime field" do
      field = Field.datetime(:starts_at)
      form = post_form(%{"starts_at" => "2026-04-01T10:30"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="datetime-local")
    end

    test "dispatches hidden field" do
      field = Field.hidden(:id)
      form = post_form(%{"id" => "42"})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ ~s(type="hidden")
    end

    test "passes label from Field struct" do
      field = Field.text_input(:first_name)
      form = post_form(%{})
      assigns = %{field: field, form: form}
      html = rendered_to_string(~H"<FieldRenderer.render_field pf_field={@field} form={@form} />")
      assert html =~ "First name"
    end
  end
end

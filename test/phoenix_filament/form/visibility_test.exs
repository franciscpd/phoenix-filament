defmodule PhoenixFilament.Form.VisibilityTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Form.FormBuilder
  alias PhoenixFilament.Form.Section
  alias PhoenixFilament.Field

  defp post_form(params) do
    to_form(params, as: "post")
  end

  describe "visible_when on fields" do
    test "wraps field in hidden div with hook data attrs" do
      form = post_form(%{"published" => "false", "published_at" => ""})

      schema = [
        Field.toggle(:published),
        Field.date(:published_at, visible_when: {:published, :eq, "true"})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(style="display:none")
      assert html =~ ~s(phx-hook="PFVisibility")
      assert html =~ ~s(data-controlling-id="post_published")
      assert html =~ ~s(data-operator="eq")
      assert html =~ ~s(data-expected="true")
    end

    test "field without visible_when renders normally" do
      form = post_form(%{"title" => ""})
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      refute html =~ "phx-hook"
      refute html =~ "PFVisibility"
    end
  end

  describe "visible_when on sections" do
    test "wraps section in hidden div with hook data attrs" do
      form = post_form(%{"type" => ""})

      schema = [
        Field.select(:type, options: ["basic", "pro"]),
        %Section{
          label: "Advanced",
          visible_when: {:type, :eq, "pro"},
          items: [Field.toggle(:feature_x)]
        }
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(phx-hook="PFVisibility")
      assert html =~ ~s(data-controlling-id="post_type")
      assert html =~ ~s(data-operator="eq")
      assert html =~ ~s(data-expected="pro")
    end
  end

  describe "visible_when with :in operator" do
    test "serializes list values as comma-separated" do
      form = post_form(%{"role" => ""})

      schema = [
        Field.select(:role, options: ["user", "admin", "super"]),
        Field.text_input(:admin_note, visible_when: {:role, :in, ["admin", "super"]})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(data-operator="in")
      assert html =~ ~s(data-expected="admin,super")
    end
  end

  describe "visible_when with :not_in operator" do
    test "serializes list values and uses not_in operator" do
      form = post_form(%{"role" => ""})

      schema = [
        Field.select(:role, options: ["user", "admin", "super"]),
        Field.text_input(:user_note, visible_when: {:role, :not_in, ["admin", "super"]})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(data-operator="not_in")
      assert html =~ ~s(data-expected="admin,super")
    end
  end

  describe "visible_when with :neq operator" do
    test "renders neq operator data attr" do
      form = post_form(%{"status" => ""})

      schema = [
        Field.select(:status, options: ["active", "archived"]),
        Field.text_input(:archive_note, visible_when: {:status, :neq, "active"})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(data-operator="neq")
      assert html =~ ~s(data-expected="active")
    end
  end
end

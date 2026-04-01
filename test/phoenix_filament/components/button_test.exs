defmodule PhoenixFilament.Components.ButtonTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Button

  describe "button/1" do
    test "renders primary button by default" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button>Save</Button.button>")
      assert html =~ "<button"
      assert html =~ "btn"
      assert html =~ "btn-primary"
      assert html =~ "Save"
    end

    test "renders danger variant" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button variant={:danger}>Delete</Button.button>")
      assert html =~ "btn-error"
    end

    test "renders secondary variant" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button variant={:secondary}>Cancel</Button.button>")
      assert html =~ "btn-secondary"
    end

    test "renders ghost variant" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button variant={:ghost}>Skip</Button.button>")
      assert html =~ "btn-ghost"
    end

    test "renders size sm" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button size={:sm}>Small</Button.button>")
      assert html =~ "btn-sm"
    end

    test "renders size lg" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button size={:lg}>Large</Button.button>")
      assert html =~ "btn-lg"
    end

    test "renders loading state" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button loading>Saving...</Button.button>")
      assert html =~ "loading"
      assert html =~ "disabled"
    end

    test "renders disabled state" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button disabled>Disabled</Button.button>")
      assert html =~ "disabled"
    end

    test "defaults to type button" do
      assigns = %{}
      html = rendered_to_string(~H"<Button.button>Click</Button.button>")
      assert html =~ ~s(type="button")
    end

    test "accepts type submit" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button type="submit">Submit</Button.button>
        """)

      assert html =~ ~s(type="submit")
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button class="w-full">Full</Button.button>
        """)

      assert html =~ "btn"
      assert html =~ "w-full"
    end
  end
end

defmodule PhoenixFilament.Components.CardTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Card

  describe "card/1" do
    test "renders card with inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <p>Content here</p>
        </Card.card>
        """)

      assert html =~ "card"
      assert html =~ "bg-base-100"
      assert html =~ "Content here"
    end

    test "renders with title attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card title="Post Details">
          <p>Content</p>
        </Card.card>
        """)

      assert html =~ "card-title"
      assert html =~ "Post Details"
    end

    test "renders with header slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:header>
            <h2>Custom Header</h2>
          </:header>
          <p>Content</p>
        </Card.card>
        """)

      assert html =~ "Custom Header"
    end

    test "renders with footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card title="Title">
          <p>Content</p>
          <:footer>
            <button>Save</button>
          </:footer>
        </Card.card>
        """)

      assert html =~ "Save"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card class="compact">
          <p>Content</p>
        </Card.card>
        """)

      assert html =~ "card"
      assert html =~ "compact"
    end
  end
end

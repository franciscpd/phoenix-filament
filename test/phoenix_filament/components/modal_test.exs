defmodule PhoenixFilament.Components.ModalTest do
  use PhoenixFilament.ComponentCase, async: true
  alias PhoenixFilament.Components.Modal

  describe "modal/1" do
    test "renders modal when show is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show id="test-modal">
          <p>Modal content</p>
        </Modal.modal>
        """)

      assert html =~ "modal"
      assert html =~ "modal-open"
      assert html =~ "Modal content"
    end

    test "does not render modal-open when show is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show={false} id="hidden-modal">
          <p>Hidden</p>
        </Modal.modal>
        """)

      refute html =~ "modal-open"
    end

    test "renders header slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show id="header-modal">
          <:header>Delete Post?</:header>
          <p>This cannot be undone.</p>
        </Modal.modal>
        """)

      assert html =~ "Delete Post?"
    end

    test "renders actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show id="action-modal">
          <p>Confirm?</p>
          <:actions>
            <button>Yes</button>
          </:actions>
        </Modal.modal>
        """)

      assert html =~ "modal-action"
      assert html =~ "Yes"
    end

    test "renders backdrop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show id="backdrop-modal">
          <p>Content</p>
        </Modal.modal>
        """)

      assert html =~ "modal-backdrop"
    end

    test "merges custom class on modal-box" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Modal.modal show id="custom-modal" class="max-w-lg">
          <p>Content</p>
        </Modal.modal>
        """)

      assert html =~ "modal-box"
      assert html =~ "max-w-lg"
    end
  end
end

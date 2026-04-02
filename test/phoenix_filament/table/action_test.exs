defmodule PhoenixFilament.Table.ActionTest do
  use ExUnit.Case, async: true
  alias PhoenixFilament.Table.Action

  describe "%Action{}" do
    test "creates action with type and label" do
      action = %Action{type: :edit, label: "Edit"}
      assert action.type == :edit
      assert action.label == "Edit"
      assert action.confirm == nil
    end

    test "creates delete with confirmation" do
      action = %Action{type: :delete, label: "Delete", confirm: "Are you sure?"}
      assert action.confirm == "Are you sure?"
    end

    test "defaults optional fields to nil" do
      action = %Action{type: :view}
      assert action.label == nil
      assert action.confirm == nil
      assert action.icon == nil
    end
  end
end

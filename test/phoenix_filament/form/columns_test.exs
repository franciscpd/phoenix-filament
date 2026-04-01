defmodule PhoenixFilament.Form.ColumnsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Form.Columns
  alias PhoenixFilament.Field

  describe "%Columns{}" do
    test "creates columns with count and items" do
      fields = [Field.text_input(:first_name), Field.text_input(:last_name)]
      cols = %Columns{count: 2, items: fields}

      assert cols.count == 2
      assert length(cols.items) == 2
    end

    test "defaults to empty items" do
      cols = %Columns{count: 3}

      assert cols.items == []
    end
  end
end

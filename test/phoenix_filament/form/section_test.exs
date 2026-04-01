defmodule PhoenixFilament.Form.SectionTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Form.Section
  alias PhoenixFilament.Field

  describe "%Section{}" do
    test "creates section with label and items" do
      fields = [Field.text_input(:title), Field.textarea(:body)]
      section = %Section{label: "Basic Info", items: fields}

      assert section.label == "Basic Info"
      assert length(section.items) == 2
      assert match?(%Field{name: :title}, hd(section.items))
    end

    test "defaults to empty items" do
      section = %Section{label: "Empty"}

      assert section.items == []
      assert section.visible_when == nil
    end

    test "supports visible_when" do
      section = %Section{
        label: "Advanced",
        visible_when: {:type, :in, ["pro", "enterprise"]},
        items: [Field.toggle(:feature_x)]
      }

      assert section.visible_when == {:type, :in, ["pro", "enterprise"]}
    end
  end
end

defmodule PhoenixFilament.Plugins.WidgetPluginTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Plugins.WidgetPlugin

  describe "register/2" do
    test "passes through widget list" do
      widgets = [%{module: StatsWidget, sort: 1, column_span: 12}]
      result = WidgetPlugin.register(nil, widgets: widgets)
      assert result.widgets == widgets
    end

    test "empty widgets returns empty list" do
      result = WidgetPlugin.register(nil, widgets: [])
      assert result.widgets == []
    end

    test "defaults to empty when no widgets option" do
      result = WidgetPlugin.register(nil, [])
      assert result.widgets == []
    end
  end
end

defmodule PhoenixFilament.Test.Widgets.TestTable do
  use PhoenixFilament.Widget.Table

  @impl true
  def heading, do: "Recent Posts"

  @impl true
  def columns do
    [
      %PhoenixFilament.Column{name: :title, label: "Title"},
      %PhoenixFilament.Column{name: :published, label: "Published"}
    ]
  end
end

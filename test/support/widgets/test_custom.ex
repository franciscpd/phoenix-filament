defmodule PhoenixFilament.Test.Widgets.TestCustom do
  use PhoenixFilament.Widget.Custom

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title">Welcome!</h2>
        <p>Custom widget content</p>
      </div>
    </div>
    """
  end
end

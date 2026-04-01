defmodule PhoenixFilament.Components.Card do
  @moduledoc """
  Card component with hybrid slot strategy.
  Simple mode: pass `title` attr. Complex mode: use named slots.
  """
  use Phoenix.Component

  attr(:title, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:header)
  slot(:inner_block, required: true)
  slot(:footer)

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-sm", @class]} {@rest}>
      <div class="card-body">
        <div :if={@header != []} class="card-header">
          {render_slot(@header)}
        </div>
        <h3 :if={@title && @header == []} class="card-title">{@title}</h3>
        {render_slot(@inner_block)}
        <div :if={@footer != []} class="card-actions justify-end mt-4">
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end
end

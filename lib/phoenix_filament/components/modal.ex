defmodule PhoenixFilament.Components.Modal do
  @moduledoc """
  Modal dialog component using daisyUI modal classes.
  Uses `show` boolean and `on_cancel` event for control.
  Designed for LiveView 1.1 portals (Phase 6 integration).
  """
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, :any, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:header)
  slot(:inner_block, required: true)
  slot(:actions)

  def modal(assigns) do
    ~H"""
    <div id={@id} class={["modal", @show && "modal-open"]} {@rest}>
      <div class={["modal-box", @class]}>
        <div :if={@header != []}>
          <h3 class="font-bold text-lg">
            {render_slot(@header)}
          </h3>
        </div>
        <div class="py-4">
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} class="modal-action">
          {render_slot(@actions)}
        </div>
      </div>
      <div class="modal-backdrop" phx-click={@on_cancel}>
        <button>close</button>
      </div>
    </div>
    """
  end
end

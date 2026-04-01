defmodule PhoenixFilament.Components.Button do
  @moduledoc """
  Button component with variant, size, loading, and disabled support.
  Styled with daisyUI 5 semantic classes.
  """
  use Phoenix.Component

  @doc """
  Renders a button with variant, size, loading spinner, and disabled support.

  ## Example

      <.button variant={:primary} phx-click="save">Save</.button>
  """
  attr(:variant, :atom, default: :primary, values: [:primary, :secondary, :danger, :ghost])
  attr(:size, :atom, default: :md, values: [:sm, :md, :lg])
  attr(:loading, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button")
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @variant_classes %{
    primary: "btn-primary",
    secondary: "btn-secondary",
    danger: "btn-error",
    ghost: "btn-ghost"
  }
  @size_classes %{sm: "btn-sm", md: nil, lg: "btn-lg"}

  def button(assigns) do
    assigns =
      assigns
      |> assign(:variant_class, @variant_classes[assigns.variant])
      |> assign(:size_class, @size_classes[assigns.size])

    ~H"""
    <button
      type={@type}
      disabled={@disabled || @loading}
      class={[
        "btn",
        @variant_class,
        @size_class,
        @loading && "loading loading-spinner",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end

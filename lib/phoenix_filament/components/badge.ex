defmodule PhoenixFilament.Components.Badge do
  @moduledoc """
  Badge component with color variants. Styled with daisyUI 5.
  """
  use Phoenix.Component

  @color_classes %{
    neutral: nil,
    primary: "badge-primary",
    success: "badge-success",
    warning: "badge-warning",
    error: "badge-error",
    info: "badge-info"
  }
  @size_classes %{sm: "badge-sm", md: nil, lg: "badge-lg"}

  attr(:color, :atom,
    default: :neutral,
    values: [:neutral, :primary, :success, :warning, :error, :info]
  )

  attr(:size, :atom, default: :md, values: [:sm, :md, :lg])
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    assigns =
      assigns
      |> assign(:color_class, @color_classes[assigns.color])
      |> assign(:size_class, @size_classes[assigns.size])

    ~H"""
    <span class={["badge", @color_class, @size_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end

defmodule PhoenixFilament.Components.Icon do
  @moduledoc """
  Icon component that renders Heroicons using CSS class names.

  Phoenix's default asset pipeline includes Heroicons as CSS classes,
  where `hero-document-text` maps to an SVG via CSS. This component
  renders a `<span>` with the hero icon class name, relying on the
  host app's Tailwind/Heroicons setup.

  ## Usage

      <.icon name="hero-document-text" />
      <.icon name="hero-home" class="h-6 w-6" />
  """
  use Phoenix.Component

  attr(:name, :string, required: true)
  attr(:class, :string, default: "h-5 w-5")

  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end

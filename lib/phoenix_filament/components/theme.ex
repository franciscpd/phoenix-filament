defmodule PhoenixFilament.Components.Theme do
  @moduledoc """
  Theme utilities for daisyUI 5 CSS variable theming.
  """
  use Phoenix.Component

  @color_var_map %{
    primary: "--color-primary",
    primary_content: "--color-primary-content",
    secondary: "--color-secondary",
    secondary_content: "--color-secondary-content",
    accent: "--color-accent",
    accent_content: "--color-accent-content",
    neutral: "--color-neutral",
    neutral_content: "--color-neutral-content",
    base_100: "--color-base-100",
    base_200: "--color-base-200",
    base_300: "--color-base-300",
    base_content: "--color-base-content",
    info: "--color-info",
    info_content: "--color-info-content",
    success: "--color-success",
    success_content: "--color-success-content",
    warning: "--color-warning",
    warning_content: "--color-warning-content",
    error: "--color-error",
    error_content: "--color-error-content"
  }

  @spec css_vars(keyword()) :: String.t()
  def css_vars([]), do: ""

  def css_vars(colors) when is_list(colors) do
    colors
    |> Enum.map(fn {name, value} ->
      var = Map.get(@color_var_map, name, "--color-#{name}")
      "#{var}: #{value}"
    end)
    |> Enum.join("; ")
  end

  @spec theme_attr(atom() | String.t()) :: String.t()
  def theme_attr(theme) when is_atom(theme), do: Atom.to_string(theme)
  def theme_attr(theme) when is_binary(theme), do: theme

  @doc """
  Renders a daisyUI swap toggle that switches between light and dark themes via `theme-controller`.

  ## Example

      <.theme_switcher light_theme="light" dark_theme="dark" />
  """
  attr(:light_theme, :string, default: "light")
  attr(:dark_theme, :string, default: "dark")
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def theme_switcher(assigns) do
    ~H"""
    <label class={["swap swap-rotate", @class]} {@rest}>
      <input
        type="checkbox"
        class="theme-controller"
        value={@dark_theme}
      />
      <svg class="swap-on fill-current w-6 h-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
      </svg>
      <svg class="swap-off fill-current w-6 h-6" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="5" />
        <path d="M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4" />
      </svg>
    </label>
    """
  end
end

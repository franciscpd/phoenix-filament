defmodule PhoenixFilament.Components.Theme do
  @moduledoc """
  Theme utilities for daisyUI 5 CSS variable theming.
  """
  use Phoenix.Component

  @color_var_map %{
    primary: "--p",
    secondary: "--s",
    accent: "--a",
    neutral: "--n",
    base_100: "--b1",
    base_200: "--b2",
    base_300: "--b3",
    info: "--in",
    success: "--su",
    warning: "--wa",
    error: "--er"
  }

  @spec css_vars(keyword()) :: String.t()
  def css_vars([]), do: ""

  def css_vars(colors) when is_list(colors) do
    colors
    |> Enum.map(fn {name, value} ->
      var = Map.get(@color_var_map, name, "--#{name}")
      val = extract_oklch_values(value)
      "#{var}: #{val}"
    end)
    |> Enum.join("; ")
  end

  @spec theme_attr(atom() | String.t()) :: String.t()
  def theme_attr(theme) when is_atom(theme), do: Atom.to_string(theme)
  def theme_attr(theme) when is_binary(theme), do: theme

  defp extract_oklch_values(value) do
    case Regex.run(~r/oklch\((.+)\)/, value) do
      [_, inner] -> inner
      _ -> value
    end
  end
end

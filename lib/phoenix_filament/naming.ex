defmodule PhoenixFilament.Naming do
  @moduledoc """
  Shared naming utilities for humanizing atoms into user-facing labels.
  """

  @doc """
  Converts an atom to a human-readable string.

  Replaces underscores with spaces and capitalizes the first word.

  ## Examples

      iex> PhoenixFilament.Naming.humanize(:published_at)
      "Published at"

      iex> PhoenixFilament.Naming.humanize(:title)
      "Title"
  """
  @spec humanize(atom()) :: String.t()
  def humanize(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end

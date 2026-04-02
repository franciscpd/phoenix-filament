defmodule PhoenixFilament.Table.Filter do
  @moduledoc """
  Represents a table filter declaration. Types: :select, :boolean, :date_range.
  """

  @type t :: %__MODULE__{
          type: :select | :boolean | :date_range,
          field: atom(),
          label: String.t() | nil,
          options: list() | nil,
          composition: :and | :or
        }

  defstruct [:type, :field, :label, :options, composition: :and]
end

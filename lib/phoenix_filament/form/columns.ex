defmodule PhoenixFilament.Form.Columns do
  @moduledoc """
  Arranges form fields in a CSS grid with N columns.

  Renders as a `<div class="grid grid-cols-N gap-4">` in the form builder.
  """

  @type t :: %__MODULE__{
          count: pos_integer(),
          items: [PhoenixFilament.Field.t()]
        }

  defstruct [:count, items: []]
end

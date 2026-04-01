defmodule PhoenixFilament.Form.Section do
  @moduledoc """
  Groups form fields under a labeled heading.

  Renders as a `<fieldset>` with `<legend>` in the form builder.
  Supports `visible_when` for conditional section visibility.
  """

  @type t :: %__MODULE__{
          label: String.t(),
          visible_when: {atom(), atom(), any()} | nil,
          items: [PhoenixFilament.Field.t() | PhoenixFilament.Form.Columns.t()]
        }

  defstruct [:label, :visible_when, items: []]
end

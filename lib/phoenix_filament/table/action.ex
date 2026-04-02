defmodule PhoenixFilament.Table.Action do
  @moduledoc """
  Represents a row action in a table (view, edit, delete, or custom).
  """

  @type t :: %__MODULE__{
          type: atom(),
          label: String.t() | nil,
          confirm: String.t() | nil,
          icon: String.t() | nil
        }

  defstruct [:type, :label, :confirm, :icon]
end

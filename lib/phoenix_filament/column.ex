defmodule PhoenixFilament.Column do
  @moduledoc """
  A plain data struct representing a table column declaration.

  Each column has a name (matching an Ecto schema field), an auto-humanized
  label, and a keyword list of options controlling display and behavior.

  ## Supported Options

    * `sortable: true` — enable column header sorting
    * `searchable: true` — include in global text search
    * `format: fn value, row -> ... end` — custom cell formatting
    * `badge: true` — render cell value as a badge component
    * `visible: false` — hide column by default
    * `preload: :association_name` — preload association for this column
  """

  @type t :: %__MODULE__{
          name: atom(),
          label: String.t() | nil,
          opts: keyword()
        }

  defstruct [:name, :label, opts: []]

  @doc "Creates a new Column struct. Label is auto-humanized from `name` unless provided in `opts`."
  @spec column(atom(), keyword()) :: t()
  def column(name, opts \\ []) do
    {label, opts} = Keyword.pop(opts, :label)
    label = label || humanize(name)
    %__MODULE__{name: name, label: label, opts: opts}
  end

  defp humanize(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end

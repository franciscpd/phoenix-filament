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
          label: String.t(),
          opts: keyword()
        }

  defstruct [:name, :label, opts: []]

  @doc "Creates a new Column struct. Label is auto-humanized from `name` unless provided in `opts`."
  @spec column(atom(), keyword()) :: t()
  def column(name, opts \\ []) do
    {label, opts} = Keyword.pop(opts, :label)
    label = label || PhoenixFilament.Naming.humanize(name)
    %__MODULE__{name: name, label: label, opts: opts}
  end

  @doc "Creates a new Column struct. Alias for `column/2`."
  @spec new(atom(), keyword()) :: t()
  def new(name, opts \\ []), do: column(name, opts)
end

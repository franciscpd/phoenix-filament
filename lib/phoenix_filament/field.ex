defmodule PhoenixFilament.Field do
  @moduledoc """
  A plain data struct representing a form field declaration.

  Each field has a name (matching an Ecto schema field), a type
  that determines which input component renders it, an auto-humanized
  label, and a keyword list of type-specific options.

  ## Supported Field Types

    * `:text_input` — single-line text input
    * `:textarea` — multi-line text input (opts: `rows`)
    * `:number_input` — numeric input (opts: `min`, `max`, `step`)
    * `:select` — dropdown select (opts: `options`)
    * `:checkbox` — boolean checkbox
    * `:toggle` — boolean toggle switch
    * `:date` — date picker
    * `:datetime` — datetime picker
    * `:hidden` — hidden field

  ## Common Options

    * `required: true` — UI hint only (shows asterisk). Real validation is in Ecto changeset.
    * `label: "Custom"` — overrides auto-humanized label
    * `placeholder: "..."` — placeholder text
  """

  @type field_type ::
          :text_input
          | :textarea
          | :number_input
          | :select
          | :checkbox
          | :toggle
          | :date
          | :datetime
          | :hidden

  @type t :: %__MODULE__{
          name: atom(),
          type: field_type(),
          label: String.t() | nil,
          opts: keyword()
        }

  defstruct [:name, :type, :label, opts: []]

  @doc "Creates a new Field struct. Label is auto-humanized from `name` unless provided in `opts`."
  @spec new(atom(), field_type(), keyword()) :: t()
  def new(name, type, opts) do
    {label, opts} = Keyword.pop(opts, :label)
    label = label || humanize(name)
    %__MODULE__{name: name, type: type, label: label, opts: opts}
  end

  @doc "Creates a `:text_input` field."
  @spec text_input(atom(), keyword()) :: t()
  def text_input(name, opts \\ []), do: new(name, :text_input, opts)

  @doc "Creates a `:textarea` field."
  @spec textarea(atom(), keyword()) :: t()
  def textarea(name, opts \\ []), do: new(name, :textarea, opts)

  @doc "Creates a `:number_input` field."
  @spec number_input(atom(), keyword()) :: t()
  def number_input(name, opts \\ []), do: new(name, :number_input, opts)

  @doc "Creates a `:select` field."
  @spec select(atom(), keyword()) :: t()
  def select(name, opts \\ []), do: new(name, :select, opts)

  @doc "Creates a `:checkbox` field."
  @spec checkbox(atom(), keyword()) :: t()
  def checkbox(name, opts \\ []), do: new(name, :checkbox, opts)

  @doc "Creates a `:toggle` field."
  @spec toggle(atom(), keyword()) :: t()
  def toggle(name, opts \\ []), do: new(name, :toggle, opts)

  @doc "Creates a `:date` field."
  @spec date(atom(), keyword()) :: t()
  def date(name, opts \\ []), do: new(name, :date, opts)

  @doc "Creates a `:datetime` field."
  @spec datetime(atom(), keyword()) :: t()
  def datetime(name, opts \\ []), do: new(name, :datetime, opts)

  @doc "Creates a `:hidden` field."
  @spec hidden(atom(), keyword()) :: t()
  def hidden(name, opts \\ []), do: new(name, :hidden, opts)

  defp humanize(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end

defmodule PhoenixFilament.Resource.Options do
  @moduledoc false

  @schema NimbleOptions.new!([
            schema: [type: :atom, required: true, doc: "The Ecto schema module"],
            repo: [type: :atom, required: true, doc: "The Ecto repo module"],
            label: [type: :string, doc: "Human-readable resource name (auto-derived from schema if omitted)"],
            plural_label: [type: :string, doc: "Plural form of label"],
            icon: [type: :string, doc: "Icon name for panel navigation"]
          ])

  def schema, do: @schema
end

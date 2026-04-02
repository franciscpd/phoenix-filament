defmodule PhoenixFilament.Resource.Options do
  @moduledoc false

  @schema NimbleOptions.new!(
            schema: [type: :atom, required: true, doc: "The Ecto schema module"],
            repo: [type: :atom, required: true, doc: "The Ecto repo module"],
            label: [
              type: :string,
              doc: "Human-readable resource name (auto-derived from schema if omitted)"
            ],
            plural_label: [type: :string, doc: "Plural form of label"],
            icon: [type: :string, doc: "Icon name for panel navigation"],
            create_changeset: [
              type: {:or, [{:tuple, [:atom, :atom]}, nil]},
              default: nil,
              doc:
                "Changeset function as `{Module, :function_name}` tuple for create. Called as Module.function_name(struct, params). Default: `{schema, :changeset}`"
            ],
            update_changeset: [
              type: {:or, [{:tuple, [:atom, :atom]}, nil]},
              default: nil,
              doc:
                "Changeset function as `{Module, :function_name}` tuple for update. Called as Module.function_name(record, params). Default: `{schema, :changeset}`"
            ]
          )

  def schema, do: @schema
end

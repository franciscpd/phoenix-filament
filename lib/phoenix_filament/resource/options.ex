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
              type: {:or, [{:fun, 2}, nil]},
              default: nil,
              doc:
                "Optional 2-arity function (record, params) used to build the changeset on create. Defaults to nil (auto-inferred or schema default)."
            ],
            update_changeset: [
              type: {:or, [{:fun, 2}, nil]},
              default: nil,
              doc:
                "Optional 2-arity function (record, params) used to build the changeset on update. Defaults to nil (auto-inferred or schema default)."
            ]
          )

  def schema, do: @schema
end

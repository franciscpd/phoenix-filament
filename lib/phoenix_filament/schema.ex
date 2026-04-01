defmodule PhoenixFilament.Schema do
  @moduledoc """
  Introspects Ecto schemas at runtime to extract field metadata,
  associations, embeds, and virtual fields.

  All functions use `__schema__/1` at runtime — no compile-time
  dependency is created on the schema module.
  """

  @excluded_fields [:id, :inserted_at, :updated_at]
  @excluded_suffixes ["_hash", "_digest", "_token"]

  @doc "Returns all non-virtual fields with their Ecto types."
  @spec fields(module()) :: [%{name: atom(), type: atom()}]
  def fields(schema) do
    ensure_schema!(schema)

    schema.__schema__(:fields)
    |> Enum.map(fn name ->
      %{name: name, type: schema.__schema__(:type, name)}
    end)
  end

  @doc "Returns all associations (belongs_to, has_many, has_one) with related module."
  @spec associations(module()) :: [%{name: atom(), type: atom(), related: module()}]
  def associations(schema) do
    ensure_schema!(schema)

    schema.__schema__(:associations)
    |> Enum.map(fn name ->
      assoc = schema.__schema__(:association, name)
      %{name: name, type: association_type(assoc), related: assoc.queryable}
    end)
  end

  @doc "Returns all embeds (embeds_one, embeds_many) with cardinality and related module."
  @spec embeds(module()) :: [%{name: atom(), cardinality: :one | :many, related: module()}]
  def embeds(schema) do
    ensure_schema!(schema)

    schema.__schema__(:embeds)
    |> Enum.map(fn name ->
      embed = schema.__schema__(:embed, name)
      %{name: name, cardinality: embed.cardinality, related: embed.related}
    end)
  end

  @doc "Returns all virtual fields with their types."
  @spec virtual_fields(module()) :: [%{name: atom(), type: atom()}]
  def virtual_fields(schema) do
    ensure_schema!(schema)

    schema.__schema__(:virtual_fields)
    |> Enum.map(fn name ->
      %{name: name, type: schema.__schema__(:virtual_type, name)}
    end)
  end

  @doc """
  Returns visible fields for auto-discovery.

  Excludes: `id`, timestamps (`inserted_at`, `updated_at`), foreign keys
  (ending in `_id`), and sensitive fields (ending in `_hash`, `_digest`, `_token`).
  """
  @spec visible_fields(module()) :: [%{name: atom(), type: atom()}]
  def visible_fields(schema) do
    fields(schema)
    |> Enum.reject(fn %{name: name} -> excluded_field?(name) end)
  end

  @doc "Maps an Ecto type to a default form field type."
  @spec type_to_field_type(atom()) :: PhoenixFilament.Field.field_type()
  def type_to_field_type(:string), do: :text_input
  def type_to_field_type(:integer), do: :number_input
  def type_to_field_type(:float), do: :number_input
  def type_to_field_type(:decimal), do: :number_input
  def type_to_field_type(:boolean), do: :toggle
  def type_to_field_type(:date), do: :date
  def type_to_field_type(:time), do: :text_input
  def type_to_field_type(:naive_datetime), do: :datetime
  def type_to_field_type(:naive_datetime_usec), do: :datetime
  def type_to_field_type(:utc_datetime), do: :datetime
  def type_to_field_type(:utc_datetime_usec), do: :datetime
  def type_to_field_type(_), do: :text_input

  defp association_type(%Ecto.Association.BelongsTo{}), do: :belongs_to
  defp association_type(%Ecto.Association.Has{cardinality: :many}), do: :has_many
  defp association_type(%Ecto.Association.Has{cardinality: :one}), do: :has_one

  defp excluded_field?(name) do
    name_str = Atom.to_string(name)

    name in @excluded_fields or
      String.ends_with?(name_str, "_id") or
      Enum.any?(@excluded_suffixes, &String.ends_with?(name_str, &1))
  end

  defp ensure_schema!(schema) do
    Code.ensure_loaded!(schema)

    unless function_exported?(schema, :__schema__, 1) do
      raise ArgumentError,
            "#{inspect(schema)} is not an Ecto schema. " <>
              "Expected a module that uses Ecto.Schema."
    end
  end
end

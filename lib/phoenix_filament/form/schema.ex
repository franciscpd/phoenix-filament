defmodule PhoenixFilament.Form.Schema do
  @moduledoc false

  @doc """
  Extracts a flat list of `%Field{}` structs from a nested form schema.
  """
  @spec extract_fields([
          PhoenixFilament.Field.t()
          | PhoenixFilament.Form.Section.t()
          | PhoenixFilament.Form.Columns.t()
        ]) ::
          [PhoenixFilament.Field.t()]
  def extract_fields(schema) when is_list(schema) do
    Enum.flat_map(schema, &extract_fields_from_item/1)
  end

  defp extract_fields_from_item(%PhoenixFilament.Field{} = field), do: [field]

  defp extract_fields_from_item(%PhoenixFilament.Form.Section{items: items}),
    do: extract_fields(items)

  defp extract_fields_from_item(%PhoenixFilament.Form.Columns{items: items}),
    do: extract_fields(items)
end

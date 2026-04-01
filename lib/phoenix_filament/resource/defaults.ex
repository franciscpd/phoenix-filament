defmodule PhoenixFilament.Resource.Defaults do
  @moduledoc false

  def form_fields(schema) do
    PhoenixFilament.Schema.visible_fields(schema)
    |> Enum.map(fn %{name: name, type: ecto_type} ->
      field_type = PhoenixFilament.Schema.type_to_field_type(ecto_type)
      PhoenixFilament.Field.new(name, field_type, [])
    end)
  end

  def table_columns(schema) do
    PhoenixFilament.Schema.visible_fields(schema)
    |> Enum.map(fn %{name: name} ->
      PhoenixFilament.Column.column(name, sortable: true)
    end)
  end
end

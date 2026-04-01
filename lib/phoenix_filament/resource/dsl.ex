defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  defmacro form(do: block) do
    quote do
      import PhoenixFilament.Resource.DSL.FormFields
      unquote(block)
      import PhoenixFilament.Resource.DSL.FormFields, only: []
    end
  end

  defmacro table(do: block) do
    quote do
      import PhoenixFilament.Resource.DSL.TableColumns
      unquote(block)
      import PhoenixFilament.Resource.DSL.TableColumns, only: []
    end
  end
end

defmodule PhoenixFilament.Resource.DSL.FormFields do
  @moduledoc false

  defmacro text_input(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.text_input(unquote(name), unquote(opts))
    end
  end

  defmacro textarea(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.textarea(unquote(name), unquote(opts))
    end
  end

  defmacro number_input(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.number_input(unquote(name), unquote(opts))
    end
  end

  defmacro select(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.select(unquote(name), unquote(opts))
    end
  end

  defmacro checkbox(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.checkbox(unquote(name), unquote(opts))
    end
  end

  defmacro toggle(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.toggle(unquote(name), unquote(opts))
    end
  end

  defmacro date(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.date(unquote(name), unquote(opts))
    end
  end

  defmacro datetime(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.datetime(unquote(name), unquote(opts))
    end
  end

  defmacro hidden(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.hidden(unquote(name), unquote(opts))
    end
  end
end

defmodule PhoenixFilament.Resource.DSL.TableColumns do
  @moduledoc false

  defmacro column(name, opts \\ []) do
    quote do
      @_phx_filament_table_columns PhoenixFilament.Column.column(unquote(name), unquote(opts))
    end
  end
end

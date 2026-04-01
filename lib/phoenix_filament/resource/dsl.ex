defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  defmacro form(do: block) do
    quote do
      # Initialize the context stack with one empty list (the root context)
      @_phx_filament_form_context [[]]

      import PhoenixFilament.Resource.DSL.FormFields
      unquote(block)
      import PhoenixFilament.Resource.DSL.FormFields, only: []

      # Pop the root context and set the form schema (reverse to preserve declaration order)
      [root_items] = @_phx_filament_form_context
      @_phx_filament_form_schema Enum.reverse(root_items)

      # Also populate @_phx_filament_form_fields for backward compatibility
      for item <- PhoenixFilament.Form.Schema.extract_fields(@_phx_filament_form_schema) do
        @_phx_filament_form_fields item
      end
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

  @doc false
  defmacro __push_to_context__(item) do
    quote do
      [current | rest] = @_phx_filament_form_context
      @_phx_filament_form_context [[unquote(item) | current] | rest]
    end
  end

  defmacro section(label, opts \\ [], do: block) do
    quote do
      # Push a new empty context for the section's children
      @_phx_filament_form_context [[] | @_phx_filament_form_context]

      unquote(block)

      # Pop the children context and wrap in Section struct
      [children | rest] = @_phx_filament_form_context
      @_phx_filament_form_context rest

      section_struct = %PhoenixFilament.Form.Section{
        label: unquote(label),
        visible_when: unquote(opts)[:visible_when],
        items: Enum.reverse(children)
      }

      # Push the section struct to the parent context
      [parent | grandparent] = @_phx_filament_form_context
      @_phx_filament_form_context [[section_struct | parent] | grandparent]
    end
  end

  defmacro columns(count, do: block) do
    quote do
      # Push a new empty context for the columns' children
      @_phx_filament_form_context [[] | @_phx_filament_form_context]

      unquote(block)

      # Pop the children context and wrap in Columns struct
      [children | rest] = @_phx_filament_form_context
      @_phx_filament_form_context rest

      columns_struct = %PhoenixFilament.Form.Columns{
        count: unquote(count),
        items: Enum.reverse(children)
      }

      # Push the columns struct to the parent context
      [parent | grandparent] = @_phx_filament_form_context
      @_phx_filament_form_context [[columns_struct | parent] | grandparent]
    end
  end

  defmacro text_input(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.text_input(unquote(name), unquote(opts))
      )
    end
  end

  defmacro textarea(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.textarea(unquote(name), unquote(opts))
      )
    end
  end

  defmacro number_input(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.number_input(unquote(name), unquote(opts))
      )
    end
  end

  defmacro select(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.select(unquote(name), unquote(opts))
      )
    end
  end

  defmacro checkbox(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.checkbox(unquote(name), unquote(opts))
      )
    end
  end

  defmacro toggle(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.toggle(unquote(name), unquote(opts))
      )
    end
  end

  defmacro date(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.date(unquote(name), unquote(opts))
      )
    end
  end

  defmacro datetime(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.datetime(unquote(name), unquote(opts))
      )
    end
  end

  defmacro hidden(name, opts \\ []) do
    quote do
      require PhoenixFilament.Resource.DSL.FormFields

      PhoenixFilament.Resource.DSL.FormFields.__push_to_context__(
        PhoenixFilament.Field.hidden(unquote(name), unquote(opts))
      )
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

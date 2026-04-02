defmodule PhoenixFilament.Resource do
  @moduledoc """
  Declares an admin resource backed by an Ecto schema.

  ## Usage

      defmodule MyApp.Admin.PostResource do
        use PhoenixFilament.Resource,
          schema: MyApp.Blog.Post,
          repo: MyApp.Repo
      end

  ## Options

  #{NimbleOptions.docs(PhoenixFilament.Resource.Options.schema())}
  """

  @valid_resource_keys [
    :schema,
    :repo,
    :opts,
    :form_fields,
    :form_schema,
    :table_columns,
    :table_actions,
    :table_filters
  ]

  @doc """
  Callback to retrieve resource metadata.

  Valid keys: #{inspect([:schema, :repo, :opts, :form_fields, :form_schema, :table_columns, :table_actions, :table_filters])}
  """
  @callback __resource__(:schema) :: module()
  @callback __resource__(:repo) :: module()
  @callback __resource__(:opts) :: keyword()
  @callback __resource__(:form_fields) :: [PhoenixFilament.Field.t()]
  @callback __resource__(:form_schema) ::
              [
                PhoenixFilament.Field.t()
                | PhoenixFilament.Form.Section.t()
                | PhoenixFilament.Form.Columns.t()
              ]
  @callback __resource__(:table_columns) :: [PhoenixFilament.Column.t()]
  @callback __resource__(:table_actions) :: [PhoenixFilament.Table.Action.t()]
  @callback __resource__(:table_filters) :: [PhoenixFilament.Table.Filter.t()]

  defmacro __using__(opts) do
    schema_mod =
      Macro.expand_literals(
        opts[:schema],
        %{__CALLER__ | function: {:__resource__, 1}}
      )

    repo_mod =
      Macro.expand_literals(
        opts[:repo],
        %{__CALLER__ | function: {:__resource__, 1}}
      )

    quote do
      @behaviour PhoenixFilament.Resource

      @_phx_filament_opts NimbleOptions.validate!(
                            unquote(opts),
                            PhoenixFilament.Resource.Options.schema()
                          )

      Module.register_attribute(__MODULE__, :_phx_filament_form_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_table_columns, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_table_actions, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_table_filters, accumulate: true)

      @_phx_filament_form_schema nil
      @_phx_filament_form_context nil

      import PhoenixFilament.Resource.DSL, only: [form: 1, table: 1]

      @before_compile PhoenixFilament.Resource

      @_phx_filament_schema unquote(schema_mod)
      @_phx_filament_repo unquote(repo_mod)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __resource__(:schema), do: @_phx_filament_schema
      def __resource__(:repo), do: @_phx_filament_repo
      def __resource__(:opts), do: @_phx_filament_opts

      def __resource__(:form_schema) do
        case @_phx_filament_form_schema do
          nil -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
          schema -> schema
        end
      end

      def __resource__(:form_fields) do
        case @_phx_filament_form_schema do
          nil ->
            case @_phx_filament_form_fields |> Enum.reverse() do
              [] -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
              fields -> fields
            end

          schema ->
            PhoenixFilament.Form.Schema.extract_fields(schema)
        end
      end

      def __resource__(:table_columns) do
        case @_phx_filament_table_columns |> Enum.reverse() do
          [] -> PhoenixFilament.Resource.Defaults.table_columns(@_phx_filament_schema)
          columns -> columns
        end
      end

      def __resource__(:table_actions) do
        @_phx_filament_table_actions |> Enum.reverse()
      end

      def __resource__(:table_filters) do
        @_phx_filament_table_filters |> Enum.reverse()
      end

      def __resource__(key) do
        raise ArgumentError,
              "unknown resource key #{inspect(key)}. " <>
                "Valid keys are: #{inspect(unquote(Macro.escape(@valid_resource_keys)))}"
      end
    end
  end
end

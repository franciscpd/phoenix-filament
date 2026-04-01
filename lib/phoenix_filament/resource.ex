defmodule PhoenixFilament.Resource do
  @moduledoc """
  Declares an admin resource backed by an Ecto schema.

  ## Usage

      defmodule MyApp.Admin.PostResource do
        use PhoenixFilament.Resource,
          schema: MyApp.Blog.Post,
          repo: MyApp.Repo
      end
  """

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
      @_phx_filament_opts NimbleOptions.validate!(
                            unquote(opts),
                            PhoenixFilament.Resource.Options.schema()
                          )

      Module.register_attribute(__MODULE__, :_phx_filament_form_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_table_columns, accumulate: true)

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

      def __resource__(:form_fields) do
        case @_phx_filament_form_fields |> Enum.reverse() do
          [] -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
          fields -> fields
        end
      end

      def __resource__(:table_columns) do
        case @_phx_filament_table_columns |> Enum.reverse() do
          [] -> PhoenixFilament.Resource.Defaults.table_columns(@_phx_filament_schema)
          columns -> columns
        end
      end
    end
  end
end

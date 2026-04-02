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
      use Phoenix.LiveView

      # Phoenix.LiveView imports Phoenix.Component which defines form/1.
      # We need to exclude it so our DSL form/1 macro doesn't conflict.
      import Phoenix.Component, except: [form: 1]

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

      # --- Default LiveView callbacks (overridable) ---

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        socket = PhoenixFilament.Resource.Lifecycle.init_assigns(socket, __MODULE__)
        {:ok, socket}
      end

      @impl Phoenix.LiveView
      def handle_params(params, _uri, socket) do
        socket =
          PhoenixFilament.Resource.Lifecycle.apply_action(
            socket,
            socket.assigns.live_action,
            params
          )

        {:noreply, socket}
      end

      @impl Phoenix.LiveView
      def handle_event("validate", params, socket) do
        form_params = PhoenixFilament.Resource.__extract_form_params__(params)
        PhoenixFilament.Resource.Lifecycle.handle_validate(socket, form_params)
      end

      @impl Phoenix.LiveView
      def handle_event("save", params, socket) do
        form_params = PhoenixFilament.Resource.__extract_form_params__(params)
        PhoenixFilament.Resource.Lifecycle.handle_save(socket, form_params)
      end

      @impl Phoenix.LiveView
      def handle_event("back", _params, socket) do
        {:noreply,
         Phoenix.LiveView.push_patch(socket,
           to: PhoenixFilament.Resource.Lifecycle.index_path(socket)
         )}
      end

      @impl Phoenix.LiveView
      def handle_info({:table_action, action, id}, socket) do
        PhoenixFilament.Resource.Lifecycle.handle_table_action(socket, action, id)
      end

      @impl Phoenix.LiveView
      def handle_info({:table_patch, params}, socket) do
        PhoenixFilament.Resource.Lifecycle.handle_table_patch(socket, params)
      end

      @impl Phoenix.LiveView
      def render(assigns) do
        PhoenixFilament.Resource.Renderer.render(assigns)
      end

      defoverridable mount: 3,
                     handle_params: 3,
                     handle_event: 3,
                     handle_info: 2,
                     render: 1
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

  @doc false
  def __extract_form_params__(params) do
    params
    |> Map.drop(["_target", "_csrf_token"])
    |> Map.values()
    |> List.first()
    |> case do
      nil -> %{}
      p when is_map(p) -> p
      _ -> %{}
    end
  end
end

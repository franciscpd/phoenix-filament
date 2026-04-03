defmodule PhoenixFilament.Panel do
  @moduledoc """
  Declares an admin panel that wraps Resources in a shell with sidebar navigation,
  breadcrumbs, responsive layout, and a dashboard.

  ## Usage

      defmodule MyApp.Admin do
        use PhoenixFilament.Panel,
          path: "/admin",
          on_mount: {MyAuth, :require_admin},
          brand_name: "My Admin"

        resources do
          resource MyApp.Admin.PostResource,
            icon: "hero-document-text",
            nav_group: "Blog"
        end

        widgets do
          widget MyApp.Admin.StatsWidget, sort: 1
        end
      end

  ## Slug and label derivation

  When no explicit `slug:` option is given to a `resource` declaration, the panel
  auto-derives the slug by appending `"s"` to the underscored schema name
  (e.g. `Post` → `"posts"`, `Category` → `"categorys"`).

  **Limitation:** this is naive English pluralization — it does NOT handle irregular
  plurals (e.g. `Person` → `"persons"` instead of `"people"`, `Category` →
  `"categorys"` instead of `"categories"`). For any irregular or compound schema
  name, pass an explicit `slug:` option:

      resource MyApp.Admin.PersonResource, slug: "people"
      resource MyApp.Admin.CategoryResource, slug: "categories"

  The same naive pluralization is applied to `plural_label` when no explicit
  `plural_label:` is set in the resource's options.

  ## Options

  #{NimbleOptions.docs(PhoenixFilament.Panel.Options.panel_schema())}
  """

  @callback __panel__(:opts) :: keyword()
  @callback __panel__(:path) :: String.t()
  @callback __panel__(:resources) :: [map()]
  @callback __panel__(:widgets) :: [map()]
  @callback __panel__(:all_nav_items) :: [map()]
  @callback __panel__(:all_routes) :: [map()]
  @callback __panel__(:all_widgets) :: [map()]
  @callback __panel__(:all_hooks) :: [{atom(), function()}]
  @callback __panel__(:plugins) :: [{module(), keyword()}]

  defmacro __using__(opts) do
    quote do
      @behaviour PhoenixFilament.Panel

      @_phx_filament_panel_opts NimbleOptions.validate!(
                                  unquote(opts),
                                  PhoenixFilament.Panel.Options.panel_schema()
                                )

      if is_nil(@_phx_filament_panel_opts[:on_mount]) and Mix.env() != :test do
        IO.warn(
          "Panel #{inspect(__MODULE__)} has no on_mount configured. Add on_mount for production use."
        )
      end

      Module.register_attribute(__MODULE__, :_phx_filament_panel_resources, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_panel_widgets, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_panel_plugins, accumulate: true)

      import PhoenixFilament.Panel.DSL

      @before_compile PhoenixFilament.Panel
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # Pre-compute enriched resources to avoid calling __MODULE__.__panel__/1 at compile time
      @_phx_filament_enriched_resources @_phx_filament_panel_resources
                                        |> Enum.reverse()
                                        |> Enum.map(fn {mod, opts} ->
                                          resource_opts = mod.__resource__(:opts)
                                          schema = mod.__resource__(:schema)
                                          schema_name = schema |> Module.split() |> List.last()

                                          %{
                                            module: mod,
                                            icon: opts[:icon],
                                            nav_group: opts[:nav_group],
                                            # Naive pluralization: appends "s". Use explicit slug: for irregular plurals.
                                            slug:
                                              opts[:slug] ||
                                                schema_name
                                                |> Macro.underscore()
                                                |> Kernel.<>("s"),
                                            label:
                                              resource_opts[:label] ||
                                                PhoenixFilament.Naming.humanize(
                                                  schema_name
                                                  |> Macro.underscore()
                                                  |> String.to_atom()
                                                ),
                                            plural_label:
                                              resource_opts[:plural_label] ||
                                                schema_name
                                                |> Macro.underscore()
                                                |> Kernel.<>("s")
                                                |> String.replace("_", " ")
                                                |> String.capitalize()
                                          }
                                        end)

      # Pre-compute enriched widgets to avoid calling __MODULE__.__panel__/1 at compile time
      @_phx_filament_enriched_widgets @_phx_filament_panel_widgets
                                      |> Enum.reverse()
                                      |> Enum.map(fn {mod, opts} ->
                                        %{
                                          module: mod,
                                          sort: opts[:sort] || 0,
                                          column_span:
                                            case opts[:column_span] do
                                              :full -> 12
                                              n -> n || 12
                                            end,
                                          id:
                                            mod
                                            |> Module.split()
                                            |> List.last()
                                            |> Macro.underscore()
                                        }
                                      end)
                                      |> Enum.sort_by(& &1.sort)

      @impl PhoenixFilament.Panel
      def __panel__(:opts), do: @_phx_filament_panel_opts

      @impl PhoenixFilament.Panel
      def __panel__(:path), do: @_phx_filament_panel_opts[:path]

      @impl PhoenixFilament.Panel
      def __panel__(:resources), do: @_phx_filament_enriched_resources

      @impl PhoenixFilament.Panel
      def __panel__(:widgets), do: @_phx_filament_enriched_widgets

      # Build full plugin list: built-in first, then community
      @_phx_filament_all_plugins (if @_phx_filament_enriched_resources != [] do
                                    [
                                      {PhoenixFilament.Plugins.ResourcePlugin,
                                       [
                                         resources: @_phx_filament_enriched_resources,
                                         panel_path: @_phx_filament_panel_opts[:path]
                                       ]}
                                    ]
                                  else
                                    []
                                  end) ++
                                   (if @_phx_filament_enriched_widgets != [] do
                                      [
                                        {PhoenixFilament.Plugins.WidgetPlugin,
                                         [widgets: @_phx_filament_enriched_widgets]}
                                      ]
                                    else
                                      []
                                    end) ++
                                   (@_phx_filament_panel_plugins |> Enum.reverse())

      @_phx_filament_resolved PhoenixFilament.Plugin.Resolver.resolve(
                                @_phx_filament_all_plugins,
                                __MODULE__
                              )

      @impl PhoenixFilament.Panel
      def __panel__(:all_nav_items), do: @_phx_filament_resolved.all_nav_items

      @impl PhoenixFilament.Panel
      def __panel__(:all_routes), do: @_phx_filament_resolved.all_routes

      @impl PhoenixFilament.Panel
      def __panel__(:all_widgets), do: @_phx_filament_resolved.all_widgets

      @impl PhoenixFilament.Panel
      def __panel__(:all_hooks), do: @_phx_filament_resolved.all_hooks

      @impl PhoenixFilament.Panel
      def __panel__(:plugins), do: @_phx_filament_all_plugins

      def __panel__(key) do
        raise ArgumentError,
              "unknown panel key #{inspect(key)}. Valid keys are: #{inspect([:opts, :path, :resources, :widgets, :all_nav_items, :all_routes, :all_widgets, :all_hooks, :plugins])}"
      end
    end
  end

  @doc """
  Broadcasts session revocation for a user, disconnecting all their active panel sessions.

  Requires a non-nil `user_id`. Calling with `nil` would broadcast to
  `"user_sessions:"` and affect all sessions without a user — the guard prevents that.
  """
  def revoke_sessions(pubsub, user_id) when not is_nil(user_id) do
    Phoenix.PubSub.broadcast(pubsub, "user_sessions:#{user_id}", :session_revoked)
  end
end

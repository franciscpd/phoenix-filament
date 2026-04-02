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

  ## Options

  #{NimbleOptions.docs(PhoenixFilament.Panel.Options.panel_schema())}
  """

  @callback __panel__(:opts) :: keyword()
  @callback __panel__(:path) :: String.t()
  @callback __panel__(:resources) :: [map()]
  @callback __panel__(:widgets) :: [map()]

  defmacro __using__(opts) do
    quote do
      @behaviour PhoenixFilament.Panel

      @_phx_filament_panel_opts NimbleOptions.validate!(
                                   unquote(opts),
                                   PhoenixFilament.Panel.Options.panel_schema()
                                 )

      if is_nil(@_phx_filament_panel_opts[:on_mount]) do
        IO.warn(
          "Panel #{inspect(__MODULE__)} has no on_mount configured. Add on_mount for production use."
        )
      end

      Module.register_attribute(__MODULE__, :_phx_filament_panel_resources, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_panel_widgets, accumulate: true)

      import PhoenixFilament.Panel.DSL

      @before_compile PhoenixFilament.Panel
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl PhoenixFilament.Panel
      def __panel__(:opts), do: @_phx_filament_panel_opts

      @impl PhoenixFilament.Panel
      def __panel__(:path), do: @_phx_filament_panel_opts[:path]

      @impl PhoenixFilament.Panel
      def __panel__(:resources) do
        @_phx_filament_panel_resources
        |> Enum.reverse()
        |> Enum.map(fn {mod, opts} ->
          resource_opts = mod.__resource__(:opts)
          schema = mod.__resource__(:schema)
          schema_name = schema |> Module.split() |> List.last()

          %{
            module: mod,
            icon: opts[:icon],
            nav_group: opts[:nav_group],
            slug:
              opts[:slug] || schema_name |> Macro.underscore() |> Kernel.<>("s"),
            label:
              resource_opts[:label] ||
                PhoenixFilament.Naming.humanize(
                  schema_name |> Macro.underscore() |> String.to_atom()
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
      end

      @impl PhoenixFilament.Panel
      def __panel__(:widgets) do
        @_phx_filament_panel_widgets
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
            id: mod |> Module.split() |> List.last() |> Macro.underscore()
          }
        end)
        |> Enum.sort_by(& &1.sort)
      end

      def __panel__(key) do
        raise ArgumentError,
              "unknown panel key #{inspect(key)}. Valid keys are: #{inspect([:opts, :path, :resources, :widgets])}"
      end
    end
  end

  @doc """
  Broadcasts session revocation for a user, disconnecting all their active panel sessions.
  """
  def revoke_sessions(pubsub, user_id) do
    Phoenix.PubSub.broadcast(pubsub, "user_sessions:#{user_id}", :session_revoked)
  end
end

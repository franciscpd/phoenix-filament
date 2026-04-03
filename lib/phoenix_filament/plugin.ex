defmodule PhoenixFilament.Plugin do
  @moduledoc """
  Plugin behaviour for extending PhoenixFilament panels.

  > #### Experimental {: .warning}
  >
  > The Plugin API is experimental. Breaking changes may occur in
  > minor versions until this notice is removed. Pin your
  > `phoenix_filament` dependency to a specific version when using plugins.

  ## Quick Start

  Create a plugin module:

      defmodule MyApp.AnalyticsPlugin do
        use PhoenixFilament.Plugin

        @impl true
        def register(_panel, _opts) do
          %{
            nav_items: [
              nav_item("Analytics",
                path: "/analytics",
                icon: "hero-chart-bar",
                nav_group: "Reports")
            ],
            routes: [
              route("/analytics", MyApp.AnalyticsLive, :index)
            ]
          }
        end
      end

  Register it in your panel:

      defmodule MyApp.Admin do
        use PhoenixFilament.Panel, path: "/admin"

        plugins do
          plugin MyApp.AnalyticsPlugin
        end
      end

  ## Callbacks

  ### `register/2` (required)

  Called at compile time. Returns a map with any of these optional keys:

  - `:nav_items` — sidebar navigation entries (use `nav_item/2` helper)
  - `:routes` — custom live routes (use `route/3` helper)
  - `:widgets` — dashboard widgets (`%{module, sort, column_span}`)
  - `:hooks` — lifecycle hooks (`{:handle_event, &fun/3}`, `{:handle_info, &fun/2}`, `{:handle_params, &fun/3}`, `{:after_render, &fun/1}`)

  ### `boot/1` (optional)

  Called at runtime on each LiveView mount. Receives the socket, returns
  the socket. Use for runtime initialization (assigns, PubSub subscriptions).

  Cannot halt the mount — authentication is the Panel's responsibility.

  ## Stability Roadmap

  - **v0.1.x** — `@experimental`, may break in minor versions
  - **v0.2+** — stabilize based on community feedback
  - **v1.0** — stable, semver-protected
  """

  @type nav_item :: %{
          label: String.t(),
          path: String.t(),
          icon: String.t() | nil,
          nav_group: String.t() | nil,
          icon_fallback: String.t()
        }

  @type route :: %{
          path: String.t(),
          live_view: module(),
          live_action: atom()
        }

  @type register_result :: %{
          optional(:nav_items) => [nav_item()],
          optional(:routes) => [route()],
          optional(:widgets) => [map()],
          optional(:hooks) => [{atom(), function()}]
        }

  @callback register(panel :: module(), opts :: keyword()) :: register_result()
  @callback boot(socket :: Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  @optional_callbacks [boot: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour PhoenixFilament.Plugin
      import PhoenixFilament.Plugin, only: [nav_item: 2, route: 3]
    end
  end

  @doc "Builds a navigation item map for sidebar entries."
  @spec nav_item(String.t(), keyword()) :: nav_item()
  def nav_item(label, opts) do
    %{
      label: label,
      path: opts[:path],
      icon: opts[:icon],
      nav_group: opts[:nav_group],
      icon_fallback: String.first(label)
    }
  end

  @doc "Builds a route map for custom live routes."
  @spec route(String.t(), module(), atom()) :: route()
  def route(path, live_view, live_action) do
    %{path: path, live_view: live_view, live_action: live_action}
  end
end

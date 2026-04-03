defmodule PhoenixFilament.Panel.Router do
  @moduledoc """
  Provides the `phoenix_filament_panel/2` router macro.

  ## Usage

  In your router:

      import PhoenixFilament.Panel.Router

      scope "/" do
        pipe_through [:browser]
        phoenix_filament_panel "/admin", MyApp.Admin
      end

  ## HTTP-level authentication

  HTTP-level plug authentication (e.g. `EnsureAuthenticated`) should be
  configured via `pipe_through` in your router scope surrounding the
  `phoenix_filament_panel` call. This is the standard Phoenix pattern:

      scope "/admin" do
        pipe_through [:browser, :require_authenticated_user]
        phoenix_filament_panel "/", MyApp.Admin
      end

  For LiveView-level auth, configure `:on_mount` in your panel module:

      use PhoenixFilament.Panel,
        path: "/admin",
        on_mount: {MyAppWeb.UserAuth, :require_authenticated_user}

  The `:plug` panel option is kept for documentation purposes but cannot be
  automatically injected by this macro due to Phoenix Router compile-time
  constraints. Use `pipe_through` in your router instead.
  """

  defmacro phoenix_filament_panel(path, panel_module) do
    quote bind_quoted: [path: path, panel_module: panel_module] do
      opts = panel_module.__panel__(:opts)
      resources = panel_module.__panel__(:resources)
      session_name = :"phoenix_filament_#{:erlang.phash2(panel_module)}"

      on_mount_hooks =
        case opts[:on_mount] do
          nil -> [{PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
          hook -> [hook, {PhoenixFilament.Panel.Hook, {:panel, panel_module}}]
        end

      dashboard_module = opts[:dashboard] || PhoenixFilament.Panel.Dashboard

      scope path do
        live_session session_name,
          on_mount: on_mount_hooks,
          layout: {PhoenixFilament.Panel.Layout, :panel} do
          live "/", dashboard_module, :index

          for resource <- resources do
            slug = resource.slug
            mod = resource.module

            live "/#{slug}", mod, :index
            live "/#{slug}/new", mod, :new
            live "/#{slug}/:id", mod, :show
            live "/#{slug}/:id/edit", mod, :edit
          end
        end
      end
    end
  end
end

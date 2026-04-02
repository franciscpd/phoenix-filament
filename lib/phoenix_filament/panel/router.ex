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

      scope path do
        live_session session_name,
          on_mount: on_mount_hooks,
          layout: {PhoenixFilament.Panel.Layout, :panel} do
          live "/", PhoenixFilament.Panel.Dashboard, :index

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

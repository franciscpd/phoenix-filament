defmodule PhoenixFilament.Panel.Hook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  alias PhoenixFilament.Panel.Navigation

  def on_mount({:panel, panel_module}, _params, _session, socket) do
    opts = panel_module.__panel__(:opts)
    resources = panel_module.__panel__(:resources)
    panel_path = opts[:path]
    current_path = current_path_from_socket(socket)

    socket =
      socket
      |> assign(:panel_module, panel_module)
      |> assign(:panel_brand, opts[:brand_name])
      |> assign(:panel_logo, opts[:logo])
      |> assign(:panel_theme, opts[:theme])
      |> assign(:panel_theme_switcher, opts[:theme_switcher])
      |> assign(:panel_path, panel_path)
      |> assign(:panel_nav, Navigation.build_tree(resources, panel_path, current_path))
      |> assign(:current_resource, match_resource(resources, panel_path, current_path))
      |> assign(:breadcrumbs, build_breadcrumbs(opts, resources, panel_path, current_path))

    socket = maybe_subscribe_pubsub(socket, opts)

    socket =
      Phoenix.LiveView.attach_hook(socket, :panel_nav_update, :handle_params, fn
        _params, uri, socket ->
          path = URI.parse(uri).path
          nav = Navigation.build_tree(resources, panel_path, path)
          crumbs = build_breadcrumbs(opts, resources, panel_path, path)
          resource = match_resource(resources, panel_path, path)

          {:cont,
           socket
           |> assign(:panel_nav, nav)
           |> assign(:current_resource, resource)
           |> assign(:breadcrumbs, crumbs)}
      end)

    socket =
      Phoenix.LiveView.attach_hook(socket, :panel_session_revoke, :handle_info, fn
        :session_revoked, socket ->
          {:halt,
           socket
           |> Phoenix.LiveView.put_flash(:error, "Session revoked")
           |> Phoenix.LiveView.redirect(to: opts[:path] || "/")}

        _other, socket ->
          {:cont, socket}
      end)

    {:cont, socket}
  end

  defp current_path_from_socket(%{host_uri: %URI{path: path}}) when is_binary(path), do: path
  defp current_path_from_socket(_), do: "/"

  defp match_resource(resources, panel_path, current_path) do
    Enum.find(resources, fn r ->
      String.starts_with?(current_path, "#{panel_path}/#{r.slug}")
    end)
  end

  defp build_breadcrumbs(opts, resources, panel_path, current_path) do
    base = [%{label: opts[:brand_name], path: panel_path}]

    case match_resource(resources, panel_path, current_path) do
      nil ->
        base

      resource ->
        base ++ [%{label: resource.plural_label, path: "#{panel_path}/#{resource.slug}"}]
    end
  end

  defp maybe_subscribe_pubsub(socket, opts) do
    pubsub = opts[:pubsub]
    current_user = Map.get(socket.assigns, :current_user)

    if pubsub && current_user && Map.has_key?(current_user, :id) do
      Phoenix.PubSub.subscribe(pubsub, "user_sessions:#{current_user.id}")
    end

    socket
  end
end

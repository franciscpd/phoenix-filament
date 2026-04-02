defmodule PhoenixFilament.Resource.Lifecycle do
  @moduledoc """
  LiveView lifecycle management for Resource CRUD pages.

  Handles mount, apply_action per live_action, event handling,
  and info message routing. Called by thin callbacks injected
  into the Resource module.
  """

  import Phoenix.Component, only: [assign: 3, to_form: 1]

  alias PhoenixFilament.Resource.{CRUD, Authorize}

  @doc "Initializes resource assigns on mount."
  def init_assigns(socket, resource_module) do
    opts = resource_module.__resource__(:opts)

    socket
    |> assign(:resource, resource_module)
    |> assign(:schema, resource_module.__resource__(:schema))
    |> assign(:repo, resource_module.__resource__(:repo))
    |> assign(:opts, opts)
    |> assign(:form_schema, resource_module.__resource__(:form_schema))
    |> assign(:columns, resource_module.__resource__(:table_columns))
    |> assign(:table_actions, resource_module.__resource__(:table_actions))
    |> assign(:table_filters, resource_module.__resource__(:table_filters))
    |> assign(:page_title, nil)
    |> assign(:record, nil)
    |> assign(:form, nil)
    |> assign(:changeset_fn, nil)
    |> assign(:params, %{})
  end

  @doc "Applies action based on live_action, setting appropriate assigns."
  def apply_action(socket, :index, params) do
    label = plural_label(socket)

    socket
    |> assign(:page_title, label)
    |> assign(:params, params)
    |> assign(:record, nil)
    |> assign(:form, nil)
  end

  def apply_action(socket, :new, _params) do
    label = singular_label(socket)
    schema = socket.assigns.schema
    changeset_fn = resolve_changeset_fn(socket, :create)
    changeset = changeset_fn.(struct(schema), %{})

    socket
    |> assign(:page_title, "New #{label}")
    |> assign(:record, nil)
    |> assign(:changeset_fn, changeset_fn)
    |> assign(:form, to_form(changeset))
  end

  def apply_action(socket, :edit, %{"id" => id}) do
    label = singular_label(socket)
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)
    changeset_fn = resolve_changeset_fn(socket, :update)
    changeset = changeset_fn.(record, %{})

    socket
    |> assign(:page_title, "Edit #{label}")
    |> assign(:record, record)
    |> assign(:changeset_fn, changeset_fn)
    |> assign(:form, to_form(changeset))
  end

  def apply_action(socket, :show, %{"id" => id}) do
    label = singular_label(socket)
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)

    socket
    |> assign(:page_title, label)
    |> assign(:record, record)
  end

  @doc "Handles validate event — rebuilds changeset from params."
  def handle_validate(socket, params) do
    changeset_fn = socket.assigns.changeset_fn
    record = socket.assigns.record || struct(socket.assigns.schema)

    changeset =
      record
      |> changeset_fn.(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @doc "Handles save event — authorizes then creates or updates."
  def handle_save(socket, params) do
    resource = socket.assigns.resource
    user = socket.assigns[:current_user]

    if socket.assigns.record do
      Authorize.authorize!(resource, :update, socket.assigns.record, user)

      case CRUD.update(
             socket.assigns.record,
             socket.assigns.repo,
             socket.assigns.changeset_fn,
             params
           ) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(
             :info,
             "#{singular_label(socket)} updated successfully"
           )
           |> Phoenix.LiveView.push_patch(to: index_path(socket))}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      Authorize.authorize!(resource, :create, nil, user)

      case CRUD.create(
             socket.assigns.schema,
             socket.assigns.repo,
             socket.assigns.changeset_fn,
             params
           ) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(
             :info,
             "#{singular_label(socket)} created successfully"
           )
           |> Phoenix.LiveView.push_patch(to: index_path(socket))}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  rescue
    PhoenixFilament.Resource.UnauthorizedError ->
      {:noreply,
       Phoenix.LiveView.put_flash(
         socket,
         :error,
         "You are not authorized to perform this action"
       )}
  end

  @doc "Handles table action messages from TableLive."
  def handle_table_action(socket, :view, id) do
    {:noreply, Phoenix.LiveView.push_navigate(socket, to: show_path(socket, id))}
  end

  def handle_table_action(socket, :edit, id) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: edit_path(socket, id))}
  end

  def handle_table_action(socket, :delete, id) do
    resource = socket.assigns.resource
    user = socket.assigns[:current_user]
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)

    Authorize.authorize!(resource, :delete, record, user)
    {:ok, _} = CRUD.delete(record, socket.assigns.repo)

    {:noreply,
     socket
     |> Phoenix.LiveView.put_flash(
       :info,
       "#{singular_label(socket)} deleted successfully"
     )
     |> Phoenix.LiveView.push_patch(to: index_path(socket))}
  rescue
    PhoenixFilament.Resource.UnauthorizedError ->
      {:noreply,
       Phoenix.LiveView.put_flash(
         socket,
         :error,
         "You are not authorized to delete this record"
       )}
  end

  @doc "Handles table patch messages (URL state sync)."
  def handle_table_patch(socket, params) do
    {:noreply,
     Phoenix.LiveView.push_patch(socket, to: index_path_with_params(socket, params))}
  end

  @doc "Returns the index path for the resource. Public for use in injected callbacks."
  def index_path(socket) do
    socket.assigns[:index_path] || "/"
  end

  # --- Private helpers ---

  defp singular_label(socket) do
    opts = socket.assigns.opts
    opts[:label] || socket.assigns.schema |> Module.split() |> List.last()
  end

  defp plural_label(socket) do
    opts = socket.assigns.opts
    opts[:plural_label] || "#{singular_label(socket)}s"
  end

  defp resolve_changeset_fn(socket, :create) do
    opts = socket.assigns.opts
    opts[:create_changeset] || default_changeset_fn(socket.assigns.schema)
  end

  defp resolve_changeset_fn(socket, :update) do
    opts = socket.assigns.opts
    opts[:update_changeset] || default_changeset_fn(socket.assigns.schema)
  end

  defp default_changeset_fn(schema) do
    fn struct_or_record, params -> schema.changeset(struct_or_record, params) end
  end

  defp index_path_with_params(socket, params) do
    base = index_path(socket)
    query = URI.encode_query(params)
    if query == "", do: base, else: "#{base}?#{query}"
  end

  defp show_path(socket, id) do
    "#{index_path(socket)}/#{id}"
  end

  defp edit_path(socket, id) do
    "#{index_path(socket)}/#{id}/edit"
  end
end

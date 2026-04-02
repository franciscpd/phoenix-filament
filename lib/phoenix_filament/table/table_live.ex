defmodule PhoenixFilament.Table.TableLive do
  @moduledoc """
  LiveComponent that renders a complete data table.

  Manages Ecto queries, LiveView streams, sort/pagination/search/filters,
  row actions, and URL state persistence.

  ## Example

      <.live_component
        module={PhoenixFilament.Table.TableLive}
        id="posts-table"
        schema={Post}
        repo={Repo}
        columns={@columns}
        params={@params}
      />

  ## Assigns

    * `schema` — Ecto schema module (required)
    * `repo` — Ecto repo module (required)
    * `columns` — list of `%PhoenixFilament.Column{}` (required)
    * `params` — raw URL params map (optional, default `%{}`)
    * `base_query` — custom base query to use instead of schema (optional)
    * `actions` — list of `%PhoenixFilament.Table.Action{}` (optional, default `[]`)
    * `filters` — list of `%PhoenixFilament.Table.Filter{}` (optional, default `[]`)
    * `page_sizes` — list of allowed page sizes (optional, default `[25, 50, 100]`)
    * `empty_message` — message for empty state (optional, default `"No records found"`)
    * `empty_action` — map with `:label` and `:event` for empty state CTA (optional)

  ## Parent Messages

  The parent LiveView must handle these messages:

    * `{:table_action, action_type, id}` — when a row action is clicked
    * `{:table_patch, query_params}` — when table state changes (sort, page, etc.)

  Handle `:table_patch` by calling `push_patch/2`:

      def handle_info({:table_patch, params}, socket) do
        {:noreply, push_patch(socket, to: ~p"/posts?\#{params}")}
      end
  """

  use Phoenix.LiveComponent

  alias PhoenixFilament.Table.{QueryBuilder, Params, TableRenderer}
  import PhoenixFilament.Components.Modal, only: [modal: 1]

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    page_sizes = socket.assigns[:page_sizes] || [25, 50, 100]

    params =
      Params.parse(
        socket.assigns[:params] || %{},
        page_sizes: page_sizes
      )

    columns = socket.assigns.columns
    filters = socket.assigns[:filters] || []
    schema = socket.assigns[:base_query] || socket.assigns.schema
    repo = socket.assigns.repo

    query = QueryBuilder.build_query(schema, params, columns, filters)
    {rows, meta} = QueryBuilder.execute(query, repo, params)

    has_search = Enum.any?(columns, fn col -> Keyword.get(col.opts, :searchable, false) end)

    socket =
      socket
      |> assign(:parsed_params, params)
      |> assign(:meta, meta)
      |> assign(:has_search, has_search)
      |> assign_new(:confirm_delete, fn -> nil end)
      |> assign_new(:actions, fn -> [] end)
      |> assign_new(:filters, fn -> [] end)
      |> assign_new(:page_sizes, fn -> page_sizes end)
      |> assign_new(:empty_message, fn -> "No records found" end)
      |> assign_new(:empty_action, fn -> nil end)
      |> stream(:rows, rows, reset: true)

    {:ok, socket}
  end

  @impl true
  def handle_event("sort", %{"column" => column}, socket) do
    col = String.to_existing_atom(column)
    params = socket.assigns.parsed_params

    {sort_by, sort_dir} =
      if params.sort_by == col do
        {col, if(params.sort_dir == :asc, do: :desc, else: :asc)}
      else
        {col, :asc}
      end

    new_params = %{params | sort_by: sort_by, sort_dir: sort_dir, page: 1}
    push_table_patch(socket, new_params)
  end

  def handle_event("search", %{"search" => term}, socket) do
    new_params = %{socket.assigns.parsed_params | search: term, page: 1}
    push_table_patch(socket, new_params)
  end

  def handle_event("filter", params, socket) do
    filter_params = Map.get(params, "filter", %{})

    new_filters =
      Map.new(filter_params, fn {k, v} ->
        {String.to_existing_atom(k), v}
      end)

    new_params = %{socket.assigns.parsed_params | filters: new_filters, page: 1}
    push_table_patch(socket, new_params)
  rescue
    ArgumentError -> {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    new_params = %{socket.assigns.parsed_params | page: String.to_integer(page)}
    push_table_patch(socket, new_params)
  end

  def handle_event("per_page", %{"per_page" => per_page}, socket) do
    new_params = %{
      socket.assigns.parsed_params
      | per_page: String.to_integer(per_page),
        page: 1
    }

    push_table_patch(socket, new_params)
  end

  def handle_event("row_action", %{"action" => "delete", "id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete, id)}
  end

  def handle_event("row_action", %{"action" => action, "id" => id}, socket) do
    send(self(), {:table_action, String.to_existing_atom(action), id})
    {:noreply, socket}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    send(self(), {:table_action, :delete, id})
    {:noreply, assign(socket, :confirm_delete, nil)}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, nil)}
  end

  defp push_table_patch(socket, params) do
    query_string = Params.to_query_string(params)
    send(self(), {:table_patch, query_string})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <TableRenderer.search_bar
        :if={@has_search}
        search={@parsed_params.search}
        target={@myself}
      />

      <TableRenderer.filter_bar
        :if={@filters != []}
        filters={@filters}
        filter_values={@parsed_params.filters}
        target={@myself}
      />

      <div :if={@meta.total > 0} class="overflow-x-auto">
        <table class="table table-zebra">
          <TableRenderer.table_header
            columns={@columns}
            sort_by={@parsed_params.sort_by}
            sort_dir={@parsed_params.sort_dir}
            actions={@actions}
            target={@myself}
          />
          <tbody id={"#{@id}-rows"} phx-update="stream">
            <TableRenderer.table_row
              :for={{dom_id, row} <- @streams.rows}
              id={dom_id}
              columns={@columns}
              row={row}
              actions={@actions}
              target={@myself}
            />
          </tbody>
        </table>
      </div>

      <TableRenderer.empty_state
        :if={@meta.total == 0}
        message={@empty_message}
        action={@empty_action}
      />

      <TableRenderer.pagination
        :if={@meta.total > 0}
        page={@meta.page}
        per_page={@meta.per_page}
        total={@meta.total}
        page_sizes={@page_sizes}
        target={@myself}
      />

      <.modal
        :if={@confirm_delete}
        show={@confirm_delete != nil}
        id={"#{@id}-delete-modal"}
        on_cancel={nil}
      >
        <:header>Confirm Delete</:header>
        <p>Are you sure you want to delete this record? This action cannot be undone.</p>
        <:actions>
          <button
            class="btn btn-error"
            phx-click="confirm_delete"
            phx-value-id={@confirm_delete}
            phx-target={@myself}
          >
            Delete
          </button>
          <button class="btn btn-ghost" phx-click="cancel_delete" phx-target={@myself}>
            Cancel
          </button>
        </:actions>
      </.modal>
    </div>
    """
  end
end

defmodule PhoenixFilament.Table.TableRenderer do
  @moduledoc """
  Stateless function components for table UI elements.

  Renders search bar, filter bar, table header, table rows, pagination, and
  empty state using daisyUI semantic classes. All components accept a `target`
  attribute for `phx-target` to support LiveComponent targeting.
  """
  use Phoenix.Component

  import PhoenixFilament.Components.Button, only: [button: 1]

  alias PhoenixFilament.Table.Action

  # ---------------------------------------------------------------------------
  # search_bar/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders a search input with phx-change and debounce.

  ## Attributes

    * `search` — current search string (required)
    * `target` — phx-target value for LiveComponent targeting (optional)
    * `placeholder` — input placeholder text (optional, default "Search...")

  ## Example

      <TableRenderer.search_bar search={@params.search} target={@myself} />
  """
  attr(:search, :string, required: true)
  attr(:target, :any, default: nil)
  attr(:placeholder, :string, default: "Search...")

  def search_bar(assigns) do
    ~H"""
    <div class="form-control w-full max-w-xs">
      <form phx-change="search" phx-submit="search" phx-target={@target}>
        <input
          type="search"
          name="search"
          value={@search}
          placeholder={@placeholder}
          class="input input-bordered input-sm w-full"
          phx-debounce="300"
        />
      </form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # filter_bar/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders filter controls for a list of `%Filter{}` structs.

  Dispatches by `filter.type`:

    * `:select` — `<select>` dropdown
    * `:boolean` — checkbox input
    * `:date_range` — two date inputs (from/to)

  ## Attributes

    * `filters` — list of `%PhoenixFilament.Table.Filter{}` (required)
    * `filter_values` — map of current filter values keyed by field atom (required)
    * `target` — phx-target value (optional)

  ## Example

      <TableRenderer.filter_bar filters={@filters} filter_values={@params.filters} target={@myself} />
  """
  attr(:filters, :list, required: true)
  attr(:filter_values, :map, required: true)
  attr(:target, :any, default: nil)

  def filter_bar(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-3 items-end">
      <%= for filter <- @filters do %>
        {render_filter(filter, @filter_values, @target)}
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # table_header/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders a `<thead>` with column headers.

  Sortable columns receive `phx-click="sort"` and `phx-value-column`. The
  active sort column displays ▲ (asc) or ▼ (desc). An "Actions" column is
  appended when `actions` is non-empty.

  ## Attributes

    * `columns` — list of `%PhoenixFilament.Column{}` (required)
    * `sort_by` — atom identifying the currently sorted column (required)
    * `sort_dir` — `:asc` or `:desc` (required)
    * `actions` — list of `%PhoenixFilament.Table.Action{}` (required)
    * `target` — phx-target value (optional)

  ## Example

      <TableRenderer.table_header
        columns={@columns}
        sort_by={@params.sort_by}
        sort_dir={@params.sort_dir}
        actions={@actions}
        target={@myself}
      />
  """
  attr(:columns, :list, required: true)
  attr(:sort_by, :atom, required: true)
  attr(:sort_dir, :atom, required: true)
  attr(:actions, :list, required: true)
  attr(:target, :any, default: nil)

  def table_header(assigns) do
    ~H"""
    <thead>
      <tr>
        <%= for col <- @columns do %>
          <th>
            <%= if col.opts[:sortable] do %>
              <button
                class="flex items-center gap-1 font-semibold hover:underline"
                phx-click="sort"
                phx-value-column={col.name}
                phx-target={@target}
              >
                {col.label}
                <%= if @sort_by == col.name do %>
                  <span>{if @sort_dir == :asc, do: "▲", else: "▼"}</span>
                <% end %>
              </button>
            <% else %>
              <span class="font-semibold">{col.label}</span>
            <% end %>
          </th>
        <% end %>
        <%= if @actions != [] do %>
          <th><span class="font-semibold">Actions</span></th>
        <% end %>
      </tr>
    </thead>
    """
  end

  # ---------------------------------------------------------------------------
  # table_row/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders a `<tr>` for a single data row.

  Cell rendering priority:
  1. `format` callback — `fn value, row -> html_or_string end`
  2. `badge: true` — renders value as a `<span class="badge badge-sm">`
  3. Default — `to_string(value || "")`

  Action buttons use `phx-click="row_action"`, `phx-value-action`, and
  `phx-value-id`. Delete actions receive `variant={:danger}`; others receive
  `variant={:ghost}`. All action buttons are `size={:sm}`.

  ## Attributes

    * `row` — map or struct for the data row (must have `:id`) (required)
    * `columns` — list of `%PhoenixFilament.Column{}` (required)
    * `actions` — list of `%PhoenixFilament.Table.Action{}` (required)
    * `target` — phx-target value (optional)

  ## Example

      <TableRenderer.table_row
        row={row}
        columns={@columns}
        actions={@actions}
        target={@myself}
      />
  """
  attr(:id, :string, default: nil)
  attr(:row, :map, required: true)
  attr(:columns, :list, required: true)
  attr(:actions, :list, required: true)
  attr(:target, :any, default: nil)

  def table_row(assigns) do
    ~H"""
    <tr id={@id} class="hover">
      <%= for col <- @columns do %>
        <td>{render_cell(col, @row)}</td>
      <% end %>
      <%= if @actions != [] do %>
        <td>
          <div class="flex gap-1">
            <%= for action <- @actions do %>
              <.button
                variant={action_button_variant(action)}
                size={:sm}
                phx-click="row_action"
                phx-value-action={action.type}
                phx-value-id={@row.id}
                phx-target={@target}
              >
                {action.label || action.type |> Atom.to_string() |> String.capitalize()}
              </.button>
            <% end %>
          </div>
        </td>
      <% end %>
    </tr>
    """
  end

  # ---------------------------------------------------------------------------
  # pagination/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders page navigation controls, a per-page selector, and "Showing X-Y of Z".

  Sends `phx-click="paginate"` with `phx-value-page`, and `phx-change="per_page"`
  on the per-page selector.

  ## Attributes

    * `page` — current page number (integer, required)
    * `per_page` — current page size (integer, required)
    * `total` — total number of records (integer, required)
    * `target` — phx-target value (optional)

  ## Example

      <TableRenderer.pagination page={@params.page} per_page={@params.per_page} total={@total} target={@myself} />
  """
  attr(:page, :integer, required: true)
  attr(:per_page, :integer, required: true)
  attr(:total, :integer, required: true)
  attr(:page_sizes, :list, default: [10, 25, 50, 100])
  attr(:target, :any, default: nil)

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:range_start, (assigns.page - 1) * assigns.per_page + 1)
      |> assign(:range_end, min(assigns.page * assigns.per_page, assigns.total))
      |> assign(:total_pages, ceil(assigns.total / assigns.per_page))

    ~H"""
    <div class="flex items-center justify-between gap-4 flex-wrap">
      <div class="text-sm text-base-content/70">
        Showing {@range_start}-{@range_end} of {@total}
      </div>

      <div class="flex items-center gap-2">
        <.button
          variant={:ghost}
          size={:sm}
          disabled={@page <= 1}
          phx-click="paginate"
          phx-value-page={@page - 1}
          phx-target={@target}
        >
          Previous
        </.button>

        <span class="text-sm">
          Page {@page} of {@total_pages}
        </span>

        <.button
          variant={:ghost}
          size={:sm}
          disabled={@page >= @total_pages}
          phx-click="paginate"
          phx-value-page={@page + 1}
          phx-target={@target}
        >
          Next
        </.button>
      </div>

      <div class="flex items-center gap-2 text-sm">
        <label>Per page:</label>
        <select
          name="per_page"
          class="select select-sm select-bordered"
          phx-change="per_page"
          phx-target={@target}
        >
          <%= for opt <- @page_sizes do %>
            <option value={opt} selected={opt == @per_page}>{opt}</option>
          <% end %>
        </select>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # empty_state/1
  # ---------------------------------------------------------------------------

  @doc """
  Renders an empty state alert with an optional call-to-action button.

  ## Attributes

    * `message` — message string to display (required)
    * `action` — optional map with `:label` and `:event` keys, or `nil` (default nil)

  ## Example

      <TableRenderer.empty_state
        message="No posts yet."
        action={%{label: "Create Post", event: "new"}}
      />
  """
  attr(:message, :string, required: true)
  attr(:action, :map, default: nil)

  def empty_state(assigns) do
    ~H"""
    <div class="alert alert-info">
      <span>{@message}</span>
      <%= if @action do %>
        <button
          type="button"
          class="btn btn-sm btn-primary"
          phx-click={@action.event}
        >
          {@action.label}
        </button>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp render_cell(col, row) do
    value = Map.get(row, col.name)

    cond do
      col.opts[:format] ->
        col.opts[:format].(value, row)

      col.opts[:badge] ->
        badge_text(value)

      true ->
        to_string(value || "")
    end
  end

  defp badge_text(value) do
    text = to_string(value || "")
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="badge badge-sm">#{escaped}</span>))
  end

  defp action_button_variant(%Action{type: :delete}), do: :danger
  defp action_button_variant(_action), do: :ghost

  defp render_filter(filter, filter_values, target) do
    current = Map.get(filter_values, filter.field, "")
    label = filter.label || filter.field |> Atom.to_string() |> String.capitalize()
    field_name = to_string(filter.field)

    case filter.type do
      :select ->
        options = filter.options || []

        assigns = %{
          label: label,
          field_name: field_name,
          options: options,
          current: current,
          target: target,
          filter: filter
        }

        Phoenix.LiveView.TagEngine.component(
          &render_select_filter/1,
          assigns,
          {__ENV__.file, __ENV__.line}
        )

      :boolean ->
        assigns = %{
          label: label,
          field_name: field_name,
          current: current,
          target: target,
          filter: filter
        }

        Phoenix.LiveView.TagEngine.component(
          &render_boolean_filter/1,
          assigns,
          {__ENV__.file, __ENV__.line}
        )

      :date_range ->
        assigns = %{
          label: label,
          field_name: field_name,
          current: current,
          target: target,
          filter: filter
        }

        Phoenix.LiveView.TagEngine.component(
          &render_date_range_filter/1,
          assigns,
          {__ENV__.file, __ENV__.line}
        )

      _ ->
        Phoenix.HTML.raw("")
    end
  end

  defp render_select_filter(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label label-text text-xs">{@label}</label>
      <select
        name={"filter[#{@field_name}]"}
        class="select select-sm select-bordered"
        phx-change="filter"
        phx-target={@target}
      >
        <option value="">All</option>
        <%= for opt <- @options do %>
          <option value={opt} selected={to_string(opt) == to_string(@current)}>{opt}</option>
        <% end %>
      </select>
    </div>
    """
  end

  defp render_boolean_filter(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label cursor-pointer gap-2">
        <span class="label-text text-xs">{@label}</span>
        <input
          type="checkbox"
          name={"filter[#{@field_name}]"}
          class="checkbox checkbox-sm"
          checked={@current == "true" or @current == true}
          phx-change="filter"
          phx-target={@target}
        />
      </label>
    </div>
    """
  end

  defp render_date_range_filter(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label label-text text-xs">{@label}</label>
      <div class="flex gap-2">
        <input
          type="date"
          name={"filter[#{@field_name}][from]"}
          class="input input-sm input-bordered"
          phx-change="filter"
          phx-target={@target}
        />
        <input
          type="date"
          name={"filter[#{@field_name}][to]"}
          class="input input-sm input-bordered"
          phx-change="filter"
          phx-target={@target}
        />
      </div>
    </div>
    """
  end
end

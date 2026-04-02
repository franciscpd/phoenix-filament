defmodule PhoenixFilament.Resource.Renderer do
  @moduledoc """
  Renders Resource CRUD pages based on live_action.

  This module is a `Phoenix.Component` that receives all assigns from the
  Resource LiveView socket and renders the appropriate view: index (table),
  form modal (new/edit), or show (record detail).

  ## Usage

  In your Resource LiveView's render/1 callback:

      def render(assigns) do
        PhoenixFilament.Resource.Renderer.render(assigns)
      end
  """
  use Phoenix.Component

  import PhoenixFilament.Form.FormBuilder, only: [form_builder: 1]
  import PhoenixFilament.Components.Modal, only: [modal: 1]
  import PhoenixFilament.Components.Button, only: [button: 1]

  @doc """
  Renders the correct CRUD view based on `@live_action`.

  Expects the following assigns from the Resource LiveView socket:

    * `live_action` — one of `:index`, `:new`, `:edit`, `:show`
    * `page_title` — string title for the page header
    * `resource` — the Resource module atom
    * `schema` — the Ecto schema module
    * `repo` — the Ecto repo module
    * `columns` — list of `%PhoenixFilament.Column{}`
    * `table_actions` — list of table action structs
    * `table_filters` — list of table filter structs
    * `params` — raw URL params map
    * `record` — the current record (for show/edit) or nil
    * `form` — a `Phoenix.HTML.Form` (for new/edit) or nil
    * `form_schema` — list of `%PhoenixFilament.Field{}` for the form
  """
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-4">{@page_title}</h1>

      <.index_view :if={@live_action in [:index, :new, :edit]} {assigns} />
      <.form_modal :if={@live_action in [:new, :edit]} {assigns} />
      <.show_view :if={@live_action == :show} {assigns} />
    </div>
    """
  end

  defp index_view(assigns) do
    resource_id = resource_slug(assigns.resource)

    assigns = assign(assigns, :resource_id, resource_id)

    ~H"""
    <.live_component
      module={PhoenixFilament.Table.TableLive}
      id={"#{@resource_id}-table"}
      schema={@schema}
      repo={@repo}
      columns={@columns}
      actions={@table_actions}
      filters={@table_filters}
      params={@params || %{}}
    />
    """
  end

  defp form_modal(assigns) do
    resource_id = resource_slug(assigns.resource)
    assigns = assign(assigns, :resource_id, resource_id)

    ~H"""
    <.modal show id={"#{@resource_id}-form-modal"}>
      <:header>{@page_title}</:header>
      <.form_builder
        form={@form}
        schema={@form_schema}
        phx-change="validate"
        phx-submit="save"
      />
    </.modal>
    """
  end

  defp show_view(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body">
        <dl class="space-y-4">
          <div :for={col <- @columns} class="grid grid-cols-3 gap-4">
            <dt class="font-semibold text-base-content/70">{col.label}</dt>
            <dd class="col-span-2">{show_value(@record, col)}</dd>
          </div>
        </dl>
      </div>
    </div>
    <div class="mt-4">
      <.button variant={:ghost} phx-click="back">Back</.button>
    </div>
    """
  end

  # Converts a module atom to a URL-safe slug for use in HTML IDs.
  # e.g. MyApp.PostResource -> "MyApp-PostResource"
  defp resource_slug(resource) when is_atom(resource) do
    resource
    |> Module.split()
    |> Enum.join("-")
  end

  defp show_value(record, col) do
    value = Map.get(record, col.name)

    cond do
      col.opts[:format] -> col.opts[:format].(value, record)
      true -> to_string(value || "")
    end
  end
end

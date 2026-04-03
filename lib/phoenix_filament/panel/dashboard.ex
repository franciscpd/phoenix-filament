defmodule PhoenixFilament.Panel.Dashboard do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    panel_module = socket.assigns[:panel_module]

    widgets =
      if panel_module do
        panel_module.__panel__(:widgets)
      else
        []
      end

    socket =
      socket
      |> assign(:widgets, widgets)
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-6">Dashboard</h1>

      <div :if={@widgets != []} class="grid grid-cols-12 gap-4">
        <div :for={w <- @widgets} class={"col-span-#{w.column_span}"}>
          <.live_component module={w.module} id={"widget-#{w.id}"} />
        </div>
      </div>

      <div :if={@widgets == []} class="text-center py-12 text-base-content/50">
        <p class="text-lg">No widgets configured</p>
        <p class="text-sm mt-2">Add widgets to your panel module to populate this dashboard.</p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:widget_refresh, widget_module}, socket) do
    widget_id = widget_module |> Module.split() |> List.last() |> Macro.underscore()
    send_update(widget_module, id: "widget-#{widget_id}")
    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end

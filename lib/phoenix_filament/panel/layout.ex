defmodule PhoenixFilament.Panel.Layout do
  @moduledoc false
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import PhoenixFilament.Components.Icon

  # panel/1 — root layout
  # Uses assigns directly (not attr declarations) since this is a layout function
  # that receives all socket assigns
  def panel(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open" data-theme={assigns[:panel_theme]}>
      <input id="panel-sidebar" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col min-h-screen">
        <.topbar brand={assigns[:panel_brand] || "Admin"} />
        <.breadcrumbs items={assigns[:breadcrumbs] || []} />
        <main class="flex-1 p-6">
          {@inner_content}
        </main>
        <.flash_group flash={assigns[:flash] || %{}} />
      </div>
      <div class="drawer-side z-40">
        <label for="panel-sidebar" aria-label="close sidebar" class="drawer-overlay"></label>
        <.sidebar
          nav={assigns[:panel_nav] || %{groups: [], ungrouped: []}}
          brand={assigns[:panel_brand] || "Admin"}
          logo={assigns[:panel_logo]}
          path={assigns[:panel_path] || "/"}
          theme_switcher={assigns[:panel_theme_switcher] || false}
          theme_switcher_target={assigns[:panel_theme_switcher_target] || "dark"}
        />
      </div>
    </div>
    """
  end

  # sidebar/1 — declare attrs
  attr(:nav, :map, required: true)
  attr(:brand, :string, required: true)
  attr(:logo, :string, default: nil)
  attr(:path, :string, required: true)
  attr(:theme_switcher, :boolean, default: false)
  attr(:theme_switcher_target, :string, default: "dark")

  def sidebar(assigns) do
    ~H"""
    <aside class="menu bg-base-200 text-base-content w-64 min-h-full p-4">
      <%!-- Brand header --%>
      <div class="flex items-center gap-3 px-2 mb-6">
        <img :if={@logo} src={@logo} alt={@brand} class="w-8 h-8 rounded" />
        <div
          :if={!@logo}
          class="w-8 h-8 bg-primary rounded flex items-center justify-center text-primary-content font-bold text-sm"
        >
          {String.first(@brand)}
        </div>
        <span class="font-semibold text-lg">{@brand}</span>
      </div>

      <%!-- Dashboard link --%>
      <ul class="menu">
        <li>
          <a href={@path}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
              />
            </svg>
            Dashboard
          </a>
        </li>
      </ul>

      <%!-- Nav groups --%>
      <div :for={group <- @nav.groups} class="mt-4">
        <li class="menu-title text-xs uppercase tracking-wider">{group.label}</li>
        <ul class="menu">
          <li :for={item <- group.items}>
            <a href={item.path} class={item.active && "active"}>
              <.icon :if={item.icon} name={item.icon} />
              <span
                :if={!item.icon}
                class="w-5 h-5 bg-base-300 rounded flex items-center justify-center text-xs"
              >
                {item.icon_fallback}
              </span>
              {item.label}
            </a>
          </li>
        </ul>
      </div>

      <%!-- Ungrouped items --%>
      <ul :if={@nav.ungrouped != []} class="menu mt-4">
        <li :for={item <- @nav.ungrouped}>
          <a href={item.path} class={item.active && "active"}>
            <.icon :if={item.icon} name={item.icon} />
            <span
              :if={!item.icon}
              class="w-5 h-5 bg-base-300 rounded flex items-center justify-center text-xs"
            >
              {item.icon_fallback}
            </span>
            {item.label}
          </a>
        </li>
      </ul>

      <%!-- Theme switcher --%>
      <div :if={@theme_switcher} class="mt-auto pt-4 border-t border-base-300">
        <label class="swap swap-rotate">
          <input type="checkbox" class="theme-controller" value={@theme_switcher_target} />
          <span class="swap-on">🌙</span>
          <span class="swap-off">☀️</span>
        </label>
      </div>
    </aside>
    """
  end

  # topbar/1
  attr(:brand, :string, default: "Admin")

  def topbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 border-b border-base-300 lg:hidden">
      <div class="flex-none">
        <label for="panel-sidebar" class="btn btn-square btn-ghost">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            />
          </svg>
        </label>
      </div>
      <div class="flex-1">
        <span class="font-semibold">{@brand}</span>
      </div>
    </div>
    """
  end

  # breadcrumbs/1
  attr(:items, :list, required: true)

  def breadcrumbs(assigns) do
    assigns =
      assigns
      |> assign(:init_items, Enum.slice(assigns.items, 0..-2//1))
      |> assign(:last_item, List.last(assigns.items))

    ~H"""
    <div :if={@items != []} class="breadcrumbs text-sm px-6 pt-4">
      <ul>
        <li :for={item <- @init_items}>
          <a href={item.path}>{item.label}</a>
        </li>
        <li :if={@last_item}>{@last_item.label}</li>
      </ul>
    </div>
    """
  end

  # flash_group/1
  attr(:flash, :map, required: true)

  def flash_group(assigns) do
    ~H"""
    <div class="toast toast-end z-50">
      <div
        :if={msg = Phoenix.Flash.get(@flash, :info)}
        id="flash-info"
        class="alert alert-success"
        phx-mounted={JS.hide(transition: {"transition-opacity ease-out duration-1000", "opacity-100", "opacity-0"}, time: 5000)}
        phx-click={JS.push("lv:clear-flash", value: %{key: "info"}) |> JS.hide(to: "#flash-info")}
      >
        <span>{msg}</span>
      </div>
      <div
        :if={msg = Phoenix.Flash.get(@flash, :error)}
        id="flash-error"
        class="alert alert-error"
        phx-mounted={JS.hide(transition: {"transition-opacity ease-out duration-1000", "opacity-100", "opacity-0"}, time: 5000)}
        phx-click={JS.push("lv:clear-flash", value: %{key: "error"}) |> JS.hide(to: "#flash-error")}
      >
        <span>{msg}</span>
      </div>
    </div>
    """
  end
end

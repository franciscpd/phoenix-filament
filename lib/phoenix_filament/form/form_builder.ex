defmodule PhoenixFilament.Form.FormBuilder do
  @moduledoc """
  Renders a complete form from a form schema.

  Supports flat field lists as well as nested `%Section{}` and `%Columns{}`
  layout primitives. Conditional visibility via `visible_when` is handled by
  the `PhoenixFilament.Form.Visibility` helper.

  ## Example

      <.form_builder form={@form} schema={@schema} phx-change="validate" phx-submit="save" />
  """
  use Phoenix.Component

  alias PhoenixFilament.Field
  alias PhoenixFilament.Form.{Section, Columns}
  import PhoenixFilament.Components.FieldRenderer, only: [render_field: 1]
  import PhoenixFilament.Components.Button, only: [button: 1]

  @grid_classes %{
    1 => "grid-cols-1",
    2 => "grid-cols-2",
    3 => "grid-cols-3",
    4 => "grid-cols-4"
  }

  attr(:form, :any, required: true)
  attr(:schema, :list, required: true)
  attr(:submit_label, :string, default: "Save")
  attr(:submit, :boolean, default: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(phx-change phx-submit))

  def form_builder(assigns) do
    ~H"""
    <.form for={@form} class={@class} {@rest}>
      <.render_items items={@schema} form={@form} />
      <div :if={@submit} class="mt-6">
        <.button type="submit">{@submit_label}</.button>
      </div>
    </.form>
    """
  end

  # Private components for recursive rendering

  attr(:items, :list, required: true)
  attr(:form, :any, required: true)

  defp render_items(assigns) do
    ~H"""
    <div :for={item <- @items}>
      <.render_item item={item} form={@form} />
    </div>
    """
  end

  attr(:item, :any, required: true)
  attr(:form, :any, required: true)

  defp render_item(%{item: %Field{opts: opts} = field} = assigns) do
    case Keyword.get(opts, :visible_when) do
      nil ->
        ~H"""
        <div class="mb-4">
          <.render_field pf_field={@item} form={@form} />
        </div>
        """

      condition ->
        vis = PhoenixFilament.Form.Visibility.attrs(condition, assigns.form, field.name)
        assigns = assign(assigns, :vis, vis)

        ~H"""
        <div
          class="mb-4"
          id={@vis.id}
          style={@vis.style}
          phx-hook={@vis[:"phx-hook"]}
          data-controlling-id={@vis[:"data-controlling-id"]}
          data-operator={@vis[:"data-operator"]}
          data-expected={@vis[:"data-expected"]}
        >
          <.render_field pf_field={@item} form={@form} />
        </div>
        """
    end
  end

  defp render_item(%{item: %Section{visible_when: nil}} = assigns) do
    ~H"""
    <fieldset class="fieldset bg-base-200/50 border border-base-300 rounded-box p-4">
      <legend class="fieldset-legend font-semibold">{@item.label}</legend>
      <.render_items items={@item.items} form={@form} />
    </fieldset>
    """
  end

  defp render_item(%{item: %Section{visible_when: condition} = section} = assigns) do
    slug = section.label |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
    vis = PhoenixFilament.Form.Visibility.attrs(condition, assigns.form, "section-#{slug}")
    assigns = assign(assigns, :vis, vis)

    ~H"""
    <div
      id={@vis.id}
      style={@vis.style}
      phx-hook={@vis[:"phx-hook"]}
      data-controlling-id={@vis[:"data-controlling-id"]}
      data-operator={@vis[:"data-operator"]}
      data-expected={@vis[:"data-expected"]}
    >
      <fieldset class="fieldset bg-base-200/50 border border-base-300 rounded-box p-4">
        <legend class="fieldset-legend font-semibold">{@item.label}</legend>
        <.render_items items={@item.items} form={@form} />
      </fieldset>
    </div>
    """
  end

  defp render_item(%{item: %Columns{} = columns} = assigns) do
    grid_class = Map.get(@grid_classes, columns.count, "grid-cols-2")
    assigns = assign(assigns, :grid_class, grid_class)

    ~H"""
    <div class={["grid gap-4", @grid_class]}>
      <.render_items items={@item.items} form={@form} />
    </div>
    """
  end
end

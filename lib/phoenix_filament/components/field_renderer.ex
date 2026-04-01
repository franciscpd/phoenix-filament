defmodule PhoenixFilament.Components.FieldRenderer do
  @moduledoc """
  Dispatches %PhoenixFilament.Field{} structs to input components.
  Bridges Phase 1 data structures to Phase 2 UI components.
  """
  use Phoenix.Component
  import PhoenixFilament.Components.Input

  attr(:pf_field, PhoenixFilament.Field, required: true)
  attr(:form, :any, required: true)

  def render_field(%{pf_field: %{type: type} = pf_field, form: form} = assigns) do
    field = form[pf_field.name]

    # Build a clean assigns map with only the keys the Input components expect.
    # Drop :pf_field and :form to prevent them leaking into @rest global attrs
    # and being serialized as HTML attributes (Phoenix.HTML.Safe not implemented
    # for Phoenix.HTML.Form).
    base_assigns =
      assigns
      |> Map.drop([:pf_field, :form])
      |> assign(:field, field)
      |> assign(:label, pf_field.label)

    assigns = merge_field_opts(base_assigns, pf_field.opts)

    dispatch(type, assigns)
  end

  defp dispatch(:text_input, assigns) do
    assigns =
      assigns
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    text_input(assigns)
  end

  defp dispatch(:textarea, assigns) do
    assigns =
      assigns
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:rows, fn -> 3 end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    textarea(assigns)
  end

  defp dispatch(:number_input, assigns) do
    assigns =
      assigns
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:min, fn -> nil end)
      |> assign_new(:max, fn -> nil end)
      |> assign_new(:step, fn -> nil end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    number_input(assigns)
  end

  defp dispatch(:select, assigns) do
    assigns =
      assigns
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:prompt, fn -> nil end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    select(assigns)
  end

  defp dispatch(:checkbox, assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> nil end)

    checkbox(assigns)
  end

  defp dispatch(:toggle, assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> nil end)

    toggle(assigns)
  end

  defp dispatch(:date, assigns) do
    assigns =
      assigns
      |> assign_new(:min, fn -> nil end)
      |> assign_new(:max, fn -> nil end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    date(assigns)
  end

  defp dispatch(:datetime, assigns) do
    assigns =
      assigns
      |> assign_new(:min, fn -> nil end)
      |> assign_new(:max, fn -> nil end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)

    datetime(assigns)
  end

  defp dispatch(:hidden, assigns), do: hidden(assigns)

  defp merge_field_opts(assigns, opts) do
    Enum.reduce(opts, assigns, fn {key, value}, acc ->
      assign(acc, key, value)
    end)
  end
end

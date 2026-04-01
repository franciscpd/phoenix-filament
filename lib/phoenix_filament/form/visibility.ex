defmodule PhoenixFilament.Form.Visibility do
  @moduledoc """
  Helpers for rendering visible_when conditional visibility.

  Produces HTML data attributes consumed by the `PFVisibility` JS hook,
  which shows or hides the wrapped element based on the controlling field's
  current value.
  """

  @doc """
  Builds a map of HTML attributes for a visibility wrapper `<div>`.

  The wrapper starts hidden (`display:none`) and the `PFVisibility` JS hook
  evaluates the condition on page load and on subsequent input events.

  ## Parameters

    - `condition` — a `{controlling_field, operator, value}` tuple
    - `form` — the current `Phoenix.HTML.Form`
    - `target_name` — a unique string used as the wrapper's `id`

  ## Operators

    - `:eq` — show when field value equals expected value
    - `:neq` — show when field value differs from expected value
    - `:in` — show when field value is one of a list of expected values
  """
  @spec attrs({atom(), atom(), any()}, Phoenix.HTML.Form.t(), atom() | String.t()) :: map()
  def attrs({controlling_field, operator, value}, form, target_name) do
    %{
      id: "field-#{target_name}",
      style: "display:none",
      "phx-hook": "PFVisibility",
      "data-controlling-id": "#{form.id}_#{controlling_field}",
      "data-operator": to_string(operator),
      "data-expected": serialize_value(value)
    }
  end

  defp serialize_value(values) when is_list(values), do: Enum.join(values, ",")
  defp serialize_value(value), do: to_string(value)
end

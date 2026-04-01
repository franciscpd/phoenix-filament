defmodule PhoenixFilament.Components.Input do
  @moduledoc """
  Form input components styled with daisyUI 5.

  Each component accepts a `Phoenix.HTML.FormField` and renders the
  appropriate HTML input with label, error display, and accessibility
  attributes built in.
  """

  use Phoenix.Component

  # --- text_input/1 ---

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def text_input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="text"
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value("text", @field.value)}
        placeholder={@placeholder}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- textarea/1 ---

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:rows, :integer, default: 3)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def textarea(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <textarea
        id={@field.id}
        name={@field.name}
        placeholder={@placeholder}
        rows={@rows}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["textarea textarea-bordered w-full", @field.errors != [] && "textarea-error", @class]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- number_input/1 ---

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:min, :integer, default: nil)
  attr(:max, :integer, default: nil)
  attr(:step, :integer, default: nil)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def number_input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="number"
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value("number", @field.value)}
        placeholder={@placeholder}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- shared error rendering ---

  defp field_errors(assigns) do
    ~H"""
    <p
      :for={error <- @field.errors}
      id={"#{@field.id}-error"}
      role="alert"
      class="text-error text-sm mt-1"
    >
      {error}
    </p>
    """
  end
end

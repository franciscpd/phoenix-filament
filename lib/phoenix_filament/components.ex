defmodule PhoenixFilament.Components do
  @moduledoc """
  Imports all PhoenixFilament UI components.

  ## Usage

      defmodule MyAppWeb.PostLive do
        use PhoenixFilament.Components
        # Available: <.text_input>, <.button>, <.modal>, etc.
      end

  For selective import:

      import PhoenixFilament.Components.Input
      import PhoenixFilament.Components.Button
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixFilament.Components.Input
      import PhoenixFilament.Components.Button
      import PhoenixFilament.Components.Badge
      import PhoenixFilament.Components.Card
      import PhoenixFilament.Components.Modal
      import PhoenixFilament.Components.Theme
      import PhoenixFilament.Components.FieldRenderer, only: [render_field: 1]
      import PhoenixFilament.Form.FormBuilder, only: [form_builder: 1]
    end
  end
end

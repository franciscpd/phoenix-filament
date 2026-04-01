defmodule PhoenixFilament.ComponentCase do
  @moduledoc """
  Test case for rendering Phoenix function components.
  Provides helpers for building form fields in tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

      @doc "Creates a Phoenix.HTML.Form from a params map for testing."
      def make_form(params, opts \\ []) do
        as = Keyword.get(opts, :as, :test)
        to_form(params, as: as)
      end
    end
  end
end

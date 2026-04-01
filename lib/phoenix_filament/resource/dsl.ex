defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  defmacro form(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro table(do: block) do
    quote do
      unquote(block)
    end
  end
end

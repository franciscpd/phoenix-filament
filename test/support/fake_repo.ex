defmodule PhoenixFilament.Test.FakeRepo do
  @moduledoc false

  def get!(schema, id) do
    struct(schema, %{id: id, title: "Test Record", body: "Test body"})
  end
end

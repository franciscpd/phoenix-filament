defmodule PhoenixFilament.Resource.CRUD do
  @moduledoc "Pure CRUD operations against an Ecto repo."

  def create(schema, repo, changeset_fn, params) do
    schema |> struct() |> changeset_fn.(params) |> repo.insert()
  end

  def update(record, repo, changeset_fn, params) do
    record |> changeset_fn.(params) |> repo.update()
  end

  def delete(record, repo) do
    repo.delete(record)
  end

  def get!(schema, repo, id) do
    repo.get!(schema, id)
  end
end

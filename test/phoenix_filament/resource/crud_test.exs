defmodule PhoenixFilament.Resource.CRUDTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.CRUD

  defmodule MockRepo do
    def insert(changeset), do: {:ok, %{id: 1, changeset: changeset}}
    def update(changeset), do: {:ok, %{id: 1, changeset: changeset}}
    def delete(record), do: {:ok, record}
    def get!(schema, id), do: %{__struct__: schema, id: id}
  end

  defmodule MockSchema do
    defstruct [:id, :name, :email]
  end

  defp identity_changeset(record, params), do: {record, params}

  describe "create/4" do
    test "calls changeset_fn with struct and params, then repo.insert" do
      params = %{name: "Alice"}
      {:ok, result} = CRUD.create(MockSchema, MockRepo, &identity_changeset/2, params)

      assert result.id == 1
      {record, ^params} = result.changeset
      assert %MockSchema{} = record
    end

    test "builds a struct from the schema before calling changeset_fn" do
      params = %{email: "a@b.com"}

      {:ok, result} =
        CRUD.create(MockSchema, MockRepo, fn record, _params -> record end, params)

      # The record passed to changeset_fn is a fresh struct
      assert %MockSchema{} = result.changeset
    end

    test "returns repo.insert result" do
      {:ok, result} = CRUD.create(MockSchema, MockRepo, &identity_changeset/2, %{})
      assert result.id == 1
    end
  end

  describe "update/4" do
    test "calls changeset_fn with existing record and params, then repo.update" do
      record = %MockSchema{id: 42, name: "Old"}
      params = %{name: "New"}
      {:ok, result} = CRUD.update(record, MockRepo, &identity_changeset/2, params)

      assert result.id == 1
      {^record, ^params} = result.changeset
    end

    test "returns repo.update result" do
      {:ok, result} = CRUD.update(%MockSchema{}, MockRepo, &identity_changeset/2, %{})
      assert result.id == 1
    end
  end

  describe "delete/2" do
    test "calls repo.delete with the record" do
      record = %MockSchema{id: 7}
      {:ok, deleted} = CRUD.delete(record, MockRepo)
      assert deleted == record
    end

    test "returns the deleted record" do
      record = %MockSchema{id: 99, name: "Gone"}
      {:ok, result} = CRUD.delete(record, MockRepo)
      assert result.name == "Gone"
    end
  end

  describe "get!/3" do
    test "calls repo.get! with schema and id" do
      result = CRUD.get!(MockSchema, MockRepo, 5)
      assert result.__struct__ == MockSchema
      assert result.id == 5
    end

    test "returns a struct of the given schema" do
      result = CRUD.get!(MockSchema, MockRepo, 100)
      assert %MockSchema{} = result
      assert result.id == 100
    end
  end
end

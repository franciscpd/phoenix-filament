defmodule PhoenixFilament.Resource.OptionsExtendedTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Options

  @required_opts [schema: MyApp.Post, repo: MyApp.Repo]

  describe "create_changeset option" do
    test "defaults to nil" do
      {:ok, validated} = NimbleOptions.validate(@required_opts, Options.schema())
      assert validated[:create_changeset] == nil
    end

    test "accepts a 2-arity function" do
      fun = fn record, params -> {record, params} end

      {:ok, validated} =
        NimbleOptions.validate(@required_opts ++ [create_changeset: fun], Options.schema())

      assert validated[:create_changeset] == fun
    end

    test "rejects non-function values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [create_changeset: :not_a_function],
                 Options.schema()
               )
    end

    test "rejects a 1-arity function" do
      fun = fn _record -> :ok end

      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [create_changeset: fun],
                 Options.schema()
               )
    end

    test "accepts nil explicitly" do
      {:ok, validated} =
        NimbleOptions.validate(@required_opts ++ [create_changeset: nil], Options.schema())

      assert validated[:create_changeset] == nil
    end
  end

  describe "update_changeset option" do
    test "defaults to nil" do
      {:ok, validated} = NimbleOptions.validate(@required_opts, Options.schema())
      assert validated[:update_changeset] == nil
    end

    test "accepts a 2-arity function" do
      fun = fn record, params -> {record, params} end

      {:ok, validated} =
        NimbleOptions.validate(@required_opts ++ [update_changeset: fun], Options.schema())

      assert validated[:update_changeset] == fun
    end

    test "rejects non-function values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [update_changeset: "not_a_function"],
                 Options.schema()
               )
    end

    test "rejects a 3-arity function" do
      fun = fn _a, _b, _c -> :ok end

      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [update_changeset: fun],
                 Options.schema()
               )
    end

    test "accepts nil explicitly" do
      {:ok, validated} =
        NimbleOptions.validate(@required_opts ++ [update_changeset: nil], Options.schema())

      assert validated[:update_changeset] == nil
    end
  end
end

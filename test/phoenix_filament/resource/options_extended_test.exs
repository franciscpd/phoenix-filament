defmodule PhoenixFilament.Resource.OptionsExtendedTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Options

  @required_opts [schema: MyApp.Post, repo: MyApp.Repo]

  describe "create_changeset option" do
    test "defaults to nil" do
      {:ok, validated} = NimbleOptions.validate(@required_opts, Options.schema())
      assert validated[:create_changeset] == nil
    end

    test "accepts {Module, :function} tuple" do
      opts = @required_opts ++ [create_changeset: {MyApp.Post, :create_changeset}]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.schema())
      assert validated[:create_changeset] == {MyApp.Post, :create_changeset}
    end

    test "rejects non-tuple non-nil values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [create_changeset: :not_valid],
                 Options.schema()
               )
    end

    test "rejects string values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [create_changeset: "not_valid"],
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

    test "accepts {Module, :function} tuple" do
      opts = @required_opts ++ [update_changeset: {MyApp.Post, :update_changeset}]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.schema())
      assert validated[:update_changeset] == {MyApp.Post, :update_changeset}
    end

    test "rejects non-tuple non-nil values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [update_changeset: "not_a_function"],
                 Options.schema()
               )
    end

    test "rejects atom values" do
      assert {:error, _} =
               NimbleOptions.validate(
                 @required_opts ++ [update_changeset: :bad_value],
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

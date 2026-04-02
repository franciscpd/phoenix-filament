defmodule PhoenixFilament.Resource.AuthorizeTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Authorize
  alias PhoenixFilament.Resource.UnauthorizedError

  defmodule ResourceWithoutCallback do
    # no authorize/3 defined
  end

  defmodule ResourceAllowAll do
    def authorize(_action, _record, _user), do: :ok
  end

  defmodule ResourceDenyAll do
    def authorize(_action, _record, _user), do: {:error, :forbidden}
  end

  defmodule ResourceDenyWithMessage do
    def authorize(_action, _record, _user), do: {:error, "you shall not pass"}
  end

  describe "authorize!/4" do
    test "module without authorize/3 callback always allows" do
      assert Authorize.authorize!(ResourceWithoutCallback, :create, %{}, %{id: 1}) == :ok
    end

    test "module with authorize/3 returning :ok allows" do
      assert Authorize.authorize!(ResourceAllowAll, :create, %{}, %{id: 1}) == :ok
    end

    test "module with authorize/3 returning {:error, _} raises UnauthorizedError" do
      assert_raise UnauthorizedError, fn ->
        Authorize.authorize!(ResourceDenyAll, :create, %{}, %{id: 1})
      end
    end

    test "error message contains the reason" do
      error =
        assert_raise UnauthorizedError, fn ->
          Authorize.authorize!(ResourceDenyAll, :create, %{}, %{id: 1})
        end

      assert Exception.message(error) =~ "Unauthorized"
      assert Exception.message(error) =~ "forbidden"
    end

    test "error message with string reason is descriptive" do
      error =
        assert_raise UnauthorizedError, fn ->
          Authorize.authorize!(ResourceDenyWithMessage, :update, %{id: 99}, nil)
        end

      assert Exception.message(error) =~ "Unauthorized"
      assert Exception.message(error) =~ "you shall not pass"
    end

    test "nil user with no callback allows" do
      assert Authorize.authorize!(ResourceWithoutCallback, :delete, %{}, nil) == :ok
    end

    test "nil user with allow-all callback allows" do
      assert Authorize.authorize!(ResourceAllowAll, :show, nil, nil) == :ok
    end

    test "different actions are passed through to callback" do
      defmodule ResourceCheckAction do
        def authorize(:admin_only, _record, _user), do: {:error, :admin_required}
        def authorize(_action, _record, _user), do: :ok
      end

      assert Authorize.authorize!(ResourceCheckAction, :create, %{}, nil) == :ok

      assert_raise UnauthorizedError, fn ->
        Authorize.authorize!(ResourceCheckAction, :admin_only, %{}, nil)
      end
    end
  end
end

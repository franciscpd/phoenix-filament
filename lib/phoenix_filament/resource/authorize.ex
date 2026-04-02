defmodule PhoenixFilament.Resource.Authorize do
  @moduledoc "Wraps authorization checks around Resource CRUD operations."

  @spec authorize!(module(), atom(), any(), any()) :: :ok
  def authorize!(resource_module, action, record, user) do
    if function_exported?(resource_module, :authorize, 3) do
      case resource_module.authorize(action, record, user) do
        :ok -> :ok
        {:error, reason} -> raise PhoenixFilament.Resource.UnauthorizedError, reason: reason
      end
    else
      :ok
    end
  end
end

defmodule PhoenixFilament.Resource.UnauthorizedError do
  defexception [:reason]
  def message(%{reason: reason}), do: "Unauthorized: #{inspect(reason)}"
end

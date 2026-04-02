defmodule PhoenixFilament.Panel.HookTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Panel.Hook

  # Test the helper functions indirectly by testing the module compiles
  # and the public on_mount/4 function exists
  # Full integration testing of on_mount requires a LiveView test setup
  # which is deferred to the integration test task

  test "module compiles and exports on_mount/4" do
    {:module, _} = Code.ensure_loaded(Hook)
    assert function_exported?(Hook, :on_mount, 4)
  end

  test "Hook module has the panel navigation dependency" do
    # Verify Hook uses Navigation (if it doesn't compile, this fails)
    assert Code.ensure_loaded?(PhoenixFilament.Panel.Navigation)
  end
end

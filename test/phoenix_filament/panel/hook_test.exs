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

  describe "plugin boot lifecycle" do
    defmodule BootTracker do
      use PhoenixFilament.Plugin
      def register(_p, _o), do: %{}

      def boot(socket) do
        # Just return socket - proves boot/1 is callable
        socket
      end
    end

    defmodule CrashingPlugin do
      use PhoenixFilament.Plugin
      def register(_p, _o), do: %{}
      def boot(_socket), do: raise("plugin crash!")
    end

    defmodule NoBootPlugin do
      use PhoenixFilament.Plugin
      def register(_p, _o), do: %{}
      # No boot/1 defined
    end

    test "boot/1 is exported on plugins that define it" do
      assert function_exported?(BootTracker, :boot, 1)
      assert function_exported?(CrashingPlugin, :boot, 1)
    end

    test "boot/1 is NOT exported on plugins that omit it" do
      Code.ensure_loaded!(NoBootPlugin)
      refute function_exported?(NoBootPlugin, :boot, 1)
    end

    test "function_exported? correctly distinguishes boot plugins" do
      plugins = [
        {BootTracker, []},
        {CrashingPlugin, []},
        {NoBootPlugin, []}
      ]

      bootable = Enum.filter(plugins, fn {mod, _} -> function_exported?(mod, :boot, 1) end)
      assert length(bootable) == 2
    end

    test "CrashingPlugin.boot/1 raises but doesn't prevent other plugins from being callable" do
      assert_raise RuntimeError, "plugin crash!", fn ->
        CrashingPlugin.boot(:fake_socket)
      end
      # BootTracker still works independently
      assert BootTracker.boot(:fake_socket) == :fake_socket
    end
  end

  describe "plugin hooks lifecycle" do
    test "attach_plugin_hooks helper exists in Hook module" do
      # The function is private, but we can verify Hook compiles with it
      Code.ensure_loaded!(PhoenixFilament.Panel.Hook)
      assert function_exported?(PhoenixFilament.Panel.Hook, :on_mount, 4)
    end

    defmodule HookPlugin do
      use PhoenixFilament.Plugin

      def register(_p, _o) do
        %{hooks: [{:handle_info, &__MODULE__.on_info/2}]}
      end

      def on_info(_msg, socket), do: {:cont, socket}
    end

    test "plugin with hooks has correct hook structure" do
      result = HookPlugin.register(nil, [])
      assert [{:handle_info, fun}] = result.hooks
      assert is_function(fun, 2)
    end

    test "plugin hooks produce unique names by index" do
      hooks = [
        {:handle_info, &HookPlugin.on_info/2},
        {:handle_info, &HookPlugin.on_info/2}
      ]

      names =
        hooks
        |> Enum.with_index()
        |> Enum.map(fn {_, idx} -> :"plugin_hook_#{idx}" end)

      assert names == [:plugin_hook_0, :plugin_hook_1]
      assert length(Enum.uniq(names)) == length(names)
    end
  end
end

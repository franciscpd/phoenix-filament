defmodule PhoenixFilament.Form.Hooks do
  @moduledoc """
  JavaScript hooks for PhoenixFilament Form Builder.

  Register these hooks in your LiveView socket configuration:

      # In app.js:
      import { getHooks } from "phoenix_filament"
      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { ...getHooks(), ...Hooks }
      })

  Or copy the hook manually:

      const PFVisibility = PhoenixFilament.Form.Hooks.visibility_hook_js()
  """

  @visibility_hook_js ~S"""
  {
    mounted() {
      const controlling = document.getElementById(this.el.dataset.controllingId)
      if (!controlling) return

      const evaluate = () => {
        const op = this.el.dataset.operator
        const expected = this.el.dataset.expected
        const actual = controlling.type === "checkbox"
          ? String(controlling.checked)
          : controlling.value

        const match = op === "eq" ? actual === expected
                    : op === "neq" ? actual !== expected
                    : op === "in" ? expected.split(",").includes(actual)
                    : op === "not_in" ? !expected.split(",").includes(actual)
                    : false

        this.el.style.display = match ? "" : "none"
      }

      controlling.addEventListener("input", evaluate)
      controlling.addEventListener("change", evaluate)
      evaluate()
    }
  }
  """

  @doc "Returns the PFVisibility hook JavaScript source as a string."
  @spec visibility_hook_js() :: String.t()
  def visibility_hook_js, do: @visibility_hook_js
end

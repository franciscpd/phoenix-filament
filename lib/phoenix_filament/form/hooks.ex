defmodule PhoenixFilament.Form.Hooks do
  @moduledoc """
  JavaScript hooks for PhoenixFilament Form Builder.

  The PFVisibility hook enables client-side conditional field visibility.
  To use it, add the hook to your LiveSocket configuration in your app.js:

      // In assets/js/app.js:
      Hooks.PFVisibility = {
        // Copy the output of PhoenixFilament.Form.Hooks.visibility_hook_js()
        // or use the installer (Phase 8) which sets this up automatically
      }

      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { ...Hooks }
      })
  """

  @visibility_hook_js ~S"""
  {
    mounted() {
      const controlling = document.getElementById(this.el.dataset.controllingId)
      if (!controlling) return

      this._evaluate = () => {
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

      this._controlling = controlling
      controlling.addEventListener("input", this._evaluate)
      controlling.addEventListener("change", this._evaluate)
      this._evaluate()
    },
    destroyed() {
      if (this._controlling && this._evaluate) {
        this._controlling.removeEventListener("input", this._evaluate)
        this._controlling.removeEventListener("change", this._evaluate)
      }
    }
  }
  """

  @doc "Returns the PFVisibility hook JavaScript source as a string."
  @spec visibility_hook_js() :: String.t()
  def visibility_hook_js, do: @visibility_hook_js
end

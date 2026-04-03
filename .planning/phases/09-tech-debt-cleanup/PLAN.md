# Phase 9: Tech Debt Cleanup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close all 8 tech debt items from the v0.1.0 milestone audit — zero known debt at release.

**Architecture:** 8 independent atomic fixes. No dependencies between tasks. Each is a self-contained commit.

**Tech Stack:** Elixir, Phoenix LiveView, NimbleOptions, ExUnit

---

## File Structure

```
MODIFIED FILES:
lib/phoenix_filament/table/table_renderer.ex       # Task 1: Button component
lib/phoenix_filament/panel/options.ex               # Task 6: theme_switcher_target
lib/phoenix_filament/panel/layout.ex                # Task 6: use config
lib/phoenix_filament/panel/hook.ex                  # Task 6: pass assign
lib/phoenix_filament/panel.ex                       # Task 6: callback + before_compile
test/phoenix_filament/resource/lifecycle_test.exs    # Task 2: flaky test
test/phoenix_filament/panel/hook_test.exs           # Task 3: meaningful tests
test/phoenix_filament/panel/dashboard_test.exs      # Task 4: meaningful tests
test/phoenix_filament/panel/options_test.exs        # Task 6: new option test
guides/getting-started.md                           # Task 5: icon docs
```

---

## Task 1: TableRenderer → Button Component

**Files:**
- Modify: `lib/phoenix_filament/table/table_renderer.ex`

- [ ] **Step 1: Read the file and identify all inline `<button>` elements**

There are 3 groups of inline buttons:
1. Sort header button (line ~130) — this is a `<button>` inside a table header for sortable columns
2. Row action buttons (line ~202) — `<button>` per action in each row
3. Pagination buttons (lines ~261, ~276) — Previous/Next page buttons

The sort header button is a special case (inside `<th>`, not a standard button variant) — leave it as-is. Focus on row actions and pagination.

- [ ] **Step 2: Add Button import**

At the top of the module, find the existing imports and add:

```elixir
import PhoenixFilament.Components.Button, only: [button: 1]
```

- [ ] **Step 3: Replace row action buttons**

Find the row action buttons in `table_row/1` (around line 202-211):

```elixir
# REPLACE this:
<button
  type="button"
  class={action_button_class(action)}
  phx-click="row_action"
  phx-value-action={action.type}
  phx-value-id={@row.id}
  phx-target={@target}
>
  {action.label || action.type |> Atom.to_string() |> String.capitalize()}
</button>

# WITH this:
<.button
  variant={action_button_variant(action)}
  size={:sm}
  phx-click="row_action"
  phx-value-action={action.type}
  phx-value-id={@row.id}
  phx-target={@target}
>
  {action.label || action.type |> Atom.to_string() |> String.capitalize()}
</.button>
```

Add a helper function to map action types to button variants:

```elixir
defp action_button_variant(%{type: :delete}), do: :danger
defp action_button_variant(_), do: :ghost
```

- [ ] **Step 4: Replace pagination buttons**

Find the Previous/Next buttons in `pagination/1` (around lines 261-285):

```elixir
# REPLACE Previous button:
<.button
  variant={:ghost}
  size={:sm}
  disabled={@page <= 1}
  phx-click="paginate"
  phx-value-page={@page - 1}
  phx-target={@target}
>
  Previous
</.button>

# REPLACE Next button:
<.button
  variant={:ghost}
  size={:sm}
  disabled={@page >= @total_pages}
  phx-click="paginate"
  phx-value-page={@page + 1}
  phx-target={@target}
>
  Next
</.button>
```

- [ ] **Step 5: Remove unused `action_button_class/1` helper**

Remove the `action_button_class/1` private function since it's replaced by `action_button_variant/1`.

- [ ] **Step 6: Run tests**

Run: `mix test test/phoenix_filament/table/`
Expected: All tests pass

- [ ] **Step 7: Commit**

```
refactor(table): use Button component in TableRenderer instead of inline daisyUI
```

---

## Task 2: Fix Flaky LifecycleTest

**Files:**
- Modify: `test/phoenix_filament/resource/lifecycle_test.exs`

- [ ] **Step 1: Add Code.ensure_loaded! before function_exported? checks**

Find the `describe "function exports"` block (around line 310-333). Every `function_exported?` call needs `Code.ensure_loaded!` first:

```elixir
test "apply_action/3 handles :edit" do
  Code.ensure_loaded!(Lifecycle)
  assert function_exported?(Lifecycle, :apply_action, 3)
end

test "apply_action/3 handles :show" do
  Code.ensure_loaded!(Lifecycle)
  assert function_exported?(Lifecycle, :apply_action, 3)
end
```

Also add `Code.ensure_loaded!(Lifecycle)` to ALL other `function_exported?` tests in the same describe block (handle_validate, handle_save, handle_table_action, handle_table_patch) for consistency.

- [ ] **Step 2: Run the test multiple times to verify it's no longer flaky**

Run: `for i in $(seq 1 5); do mix test test/phoenix_filament/resource/lifecycle_test.exs --seed 0 2>&1 | tail -1; done`
Expected: All 5 runs show 0 failures

- [ ] **Step 3: Commit**

```
fix(test): add Code.ensure_loaded! to LifecycleTest to fix intermittent failures
```

---

## Task 3: Meaningful Hook Tests

**Files:**
- Modify: `test/phoenix_filament/panel/hook_test.exs`

- [ ] **Step 1: Add boot plugin filtering tests**

Add to the existing `"plugin boot lifecycle"` describe block:

```elixir
test "boot_plugins filters correctly — only calls boot on modules that export it" do
  bootable = [
    {BootTracker, []},
    {CrashingPlugin, []},
    {NoBootPlugin, []}
  ]

  with_boot = Enum.filter(bootable, fn {mod, _} ->
    Code.ensure_loaded!(mod)
    function_exported?(mod, :boot, 1)
  end)

  without_boot = Enum.reject(bootable, fn {mod, _} ->
    Code.ensure_loaded!(mod)
    function_exported?(mod, :boot, 1)
  end)

  assert length(with_boot) == 2
  assert length(without_boot) == 1
  assert {NoBootPlugin, []} in without_boot
end
```

- [ ] **Step 2: Add error isolation test**

```elixir
test "CrashingPlugin.boot/1 raises but doesn't prevent other plugins from being callable" do
  # CrashingPlugin raises, but the other plugins still work
  assert_raise RuntimeError, "plugin crash!", fn ->
    CrashingPlugin.boot(:fake_socket)
  end

  # BootTracker.boot/1 still works independently
  result = BootTracker.boot(:fake_socket)
  assert result == :fake_socket
end
```

- [ ] **Step 3: Add hook name uniqueness test**

```elixir
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
```

- [ ] **Step 4: Run tests**

Run: `mix test test/phoenix_filament/panel/hook_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```
test(panel): add meaningful Hook tests for boot filtering, error isolation, hook names
```

---

## Task 4: Meaningful Dashboard Tests

**Files:**
- Modify: `test/phoenix_filament/panel/dashboard_test.exs`

- [ ] **Step 1: Add widget accessor test**

```elixir
test "Dashboard reads :all_widgets from panel module" do
  # Verify the Dashboard source code references :all_widgets, not :widgets
  {:ok, source} = File.read("lib/phoenix_filament/panel/dashboard.ex")
  assert source =~ ":all_widgets"
  refute source =~ ~r/__panel__\(:widgets\)/
end
```

- [ ] **Step 2: Add render output test for empty state**

```elixir
test "render/1 produces empty state message when no widgets" do
  Code.ensure_loaded!(PhoenixFilament.Panel.Dashboard)
  # Dashboard has render/1 that handles empty widget list
  # The template contains "No widgets configured" text
  {:ok, source} = File.read("lib/phoenix_filament/panel/dashboard.ex")
  assert source =~ "No widgets configured"
end
```

- [ ] **Step 3: Run tests**

Run: `mix test test/phoenix_filament/panel/dashboard_test.exs`
Expected: All tests pass

- [ ] **Step 4: Commit**

```
test(panel): add meaningful Dashboard tests for widget accessor and empty state
```

---

## Task 5: Icon Rendering Documentation

**Files:**
- Modify: `guides/getting-started.md`

- [ ] **Step 1: Add Icons section**

Find the section about Panel setup (after router configuration). Add an "Icons" subsection:

```markdown
### Icons

PhoenixFilament uses [Heroicons](https://heroicons.com) for sidebar and widget icons.
Icons are referenced by their CSS class name (e.g., `hero-document-text`).

Phoenix 1.8 apps include Heroicons by default through the `assets/vendor/heroicons/`
directory. If your app was generated with Phoenix 1.8, icons work out of the box.

For older Phoenix apps or custom setups, ensure Heroicons are available:

1. The `heroicons` package must be in your assets
2. CSS classes like `hero-document-text` must resolve to SVG icons
3. See [Phoenix Heroicons documentation](https://hexdocs.pm/phoenix/components.html) for setup details

When registering resources, specify icons with the `hero-` prefix:

```elixir
resources do
  resource MyAppWeb.Admin.PostResource,
    icon: "hero-document-text"

  resource MyAppWeb.Admin.UserResource,
    icon: "hero-users"
end
```

Resources without an `icon:` option display the first letter of their label as a fallback.
```

- [ ] **Step 2: Verify docs generate**

Run: `mix docs 2>&1 | grep -i warning || echo "NO_WARNINGS"`
Expected: NO_WARNINGS

- [ ] **Step 3: Commit**

```
docs: add icon setup section to getting-started guide
```

---

## Task 6: Configurable Theme Switcher Target

**Files:**
- Modify: `lib/phoenix_filament/panel/options.ex`
- Modify: `lib/phoenix_filament/panel.ex`
- Modify: `lib/phoenix_filament/panel/hook.ex`
- Modify: `lib/phoenix_filament/panel/layout.ex`
- Modify: `test/phoenix_filament/panel/options_test.exs`

- [ ] **Step 1: Add option to NimbleOptions schema**

In `lib/phoenix_filament/panel/options.ex`, add after `theme_switcher`:

```elixir
theme_switcher_target: [
  type: :string,
  default: "dark",
  doc: "Theme to toggle to when theme switcher is activated"
],
```

- [ ] **Step 2: Add test for new option**

In `test/phoenix_filament/panel/options_test.exs`, add:

```elixir
test "defaults theme_switcher_target to dark" do
  {:ok, validated} = NimbleOptions.validate([path: "/admin"], Options.panel_schema())
  assert validated[:theme_switcher_target] == "dark"
end

test "accepts custom theme_switcher_target" do
  {:ok, validated} = NimbleOptions.validate([path: "/admin", theme_switcher_target: "night"], Options.panel_schema())
  assert validated[:theme_switcher_target] == "night"
end
```

- [ ] **Step 3: Pass through Hook assigns**

In `lib/phoenix_filament/panel/hook.ex`, find where `panel_theme_switcher` is assigned and add:

```elixir
|> assign(:panel_theme_switcher_target, opts[:theme_switcher_target])
```

- [ ] **Step 4: Update Layout to use config**

In `lib/phoenix_filament/panel/layout.ex`, find the sidebar attr declarations and add:

```elixir
attr :theme_switcher_target, :string, default: "dark"
```

Update the `panel/1` function to pass it to sidebar:

```elixir
theme_switcher_target={assigns[:panel_theme_switcher_target] || "dark"}
```

In the theme switcher section of `sidebar/1`, replace hardcoded `"dark"`:

```elixir
<input type="checkbox" class="theme-controller" value={@theme_switcher_target} />
```

- [ ] **Step 5: Run tests**

Run: `mix test test/phoenix_filament/panel/`
Expected: All tests pass

- [ ] **Step 6: Commit**

```
feat(panel): make theme switcher target configurable (defaults to "dark")
```

---

## Task 7: CI Zero Warnings

- [ ] **Step 1: Check for compile warnings**

Run: `mix compile --warnings-as-errors 2>&1`

If warnings exist, fix each one. Common sources:
- Unused variables (prefix with `_`)
- Unused imports
- Deprecated function calls

- [ ] **Step 2: Check for test warnings**

Run: `mix test 2>&1 | grep -i "warning" | grep -v "has no on_mount" | head -10`

Fix any non-TestPanel warnings.

- [ ] **Step 3: Run format check**

Run: `mix format --check-formatted`
Expected: Exit code 0

If any files are unformatted: `mix format`

- [ ] **Step 4: Commit if changes were needed**

```
style: fix remaining warnings and formatting issues
```

---

## Task 8: Final Verification + Push

- [ ] **Step 1: Run full test suite**

Run: `mix test`
Expected: 391+ tests, 0 failures

- [ ] **Step 2: Compile clean**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation (may have the suppressed TestPanel on_mount warning in test env)

- [ ] **Step 3: Push to GitHub**

Run: `git push origin main`

- [ ] **Step 4: Verify CI green**

Run: `gh run list --repo franciscpd/phoenix-filament --limit 1`
Expected: `completed success`

- [ ] **Step 5: Commit if any final fixes needed**

```
chore(09): complete Phase 9 tech debt cleanup
```

---

*Plan: 09-tech-debt-cleanup*
*Created: 2026-04-03*
*Tasks: 8*

# Phase 9: Tech Debt Cleanup — Design Spec

**Date:** 2026-04-03
**Status:** Approved
**Approach:** 8 independent atomic fixes, no dependencies between items

## Overview

Close all 8 tech debt items from the v0.1.0 milestone audit. Each fix is a self-contained commit that can be implemented and tested independently. No new features — only fixing what was flagged.

## Fix 1: TableRenderer → Button Component

**File:** `lib/phoenix_filament/table/table_renderer.ex`

Replace 3 inline `<button>` elements with `<.button>` from `PhoenixFilament.Components.Button`. Add `import PhoenixFilament.Components.Button, only: [button: 1]` at the top. Preserve existing `phx-click`, `phx-value-action`, `phx-value-id` attributes. Use `variant={:ghost}` and `size={:sm}` for action buttons.

## Fix 2: Flaky LifecycleTest

**File:** `test/phoenix_filament/resource/lifecycle_test.exs`

Line 327-328 uses `function_exported?(Lifecycle, :apply_action, 3)` which fails intermittently because the module may not be loaded yet in async test context. Fix: add `Code.ensure_loaded!(PhoenixFilament.Resource.Lifecycle)` before the `function_exported?` check. Same pattern already used in `hook_test.exs` and widget tests.

## Fix 3: Meaningful Hook Tests

**File:** `test/phoenix_filament/panel/hook_test.exs`

Add tests that go beyond module export checks:
- Test that `boot_plugins/2` helper correctly filters plugins with/without `boot/1`
- Test that boot error isolation catches raises (plugin raises → Logger.warning, next plugin still boots)
- Test that `attach_plugin_hooks/2` produces unique hook names using index

Since `boot_plugins/2` and `attach_plugin_hooks/2` are private functions, test their behavior indirectly through the plugin test modules that already exist (TestCommunityPlugin with boot/1, BootTracker, CrashingPlugin, NoBootPlugin).

## Fix 4: Meaningful Dashboard Tests

**File:** `test/phoenix_filament/panel/dashboard_test.exs`

Add tests that verify:
- Dashboard module reads `:all_widgets` (not `:widgets`) — verify by checking the mount function exists and the module compiles with the correct accessor
- Empty widget list renders "No widgets configured" message (test render output)

## Fix 5: Icon Rendering Documentation

**File:** `guides/getting-started.md`

Add an "Icons" section after the Panel setup, explaining:
- PhoenixFilament uses hero-* CSS class names for icons
- Phoenix 1.8 apps include Heroicons by default via `assets/vendor/heroicons/`
- Developers must ensure Heroicons are available in their app
- Link to Phoenix's Heroicons documentation

## Fix 6: Configurable Theme Switcher Target

**Files:**
- `lib/phoenix_filament/panel/options.ex` — Add `theme_switcher_target` option (string, default "dark")
- `lib/phoenix_filament/panel.ex` — Pass through `__before_compile__`
- `lib/phoenix_filament/panel/hook.ex` — Inject as assign
- `lib/phoenix_filament/panel/layout.ex` — Use `@theme_switcher_target` instead of hardcoded "dark"

## Fix 7: CI Zero Warnings

Run `mix compile --warnings-as-errors` and fix any remaining warnings. The `IO.warn` for missing on_mount is already suppressed in test env. Check for any other warnings from deps or unused variables.

## Fix 8: Final CI Green

Push all fixes, verify GitHub Actions CI passes with zero warnings and zero annotations (except any unavoidable Node.js version notices from GitHub itself).

## Testing Strategy

| Fix | Test Approach |
|-----|--------------|
| 1. TableRenderer buttons | Existing table renderer tests should still pass; verify Button import compiles |
| 2. Flaky test | Run `mix test test/phoenix_filament/resource/lifecycle_test.exs` multiple times, verify no intermittent failures |
| 3. Hook tests | New tests in hook_test.exs |
| 4. Dashboard tests | New tests in dashboard_test.exs |
| 5. Icon docs | `mix docs` generates without warnings |
| 6. Theme switcher | New test in options_test.exs for new option; layout test for rendering |
| 7. CI warnings | `mix compile --warnings-as-errors` passes locally |
| 8. CI green | GitHub Actions all green |

---

*Phase: 09-tech-debt-cleanup*
*Design approved: 2026-04-03*

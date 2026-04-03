# Phase 9: Tech Debt Cleanup - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Close all 8 tech debt items identified in the v0.1.0 milestone audit. Fix component consistency (TableRenderer → Button), flaky test (LifecycleTest race condition), shallow test coverage (Hook, Dashboard, Plugin boot/hooks), icon rendering documentation, configurable theme switcher, and CI cleanliness. No new features — only fixing what was flagged.

</domain>

<decisions>
## Implementation Decisions

### Item 1: TableRenderer → Use Button Component
- **D-01:** Replace inline `<button>` tags with daisyUI classes in `table_renderer.ex` with `<.button>` from `PhoenixFilament.Components.Button`. Maintains visual consistency with the rest of the framework.

### Item 2: Fix Flaky LifecycleTest
- **D-02:** The `apply_action/3 :edit` test fails intermittently due to async module loading race condition. Fix by adding `Code.ensure_loaded!/1` before `function_exported?` check, or restructure the test to avoid the race.

### Item 3: Meaningful Hook/Dashboard Tests
- **D-03:** Add tests that verify Panel.Hook actually injects assigns (panel_brand, panel_nav, breadcrumbs) using a minimal socket-like structure. Test Dashboard renders empty state and widget grid structure.

### Item 4: Plugin Boot/Hook Lifecycle Tests
- **D-04:** Add tests that verify boot/1 is called on plugins with `function_exported?` and that error isolation works (one plugin raise doesn't crash others). Test hook attachment produces correct hook names.

### Item 5: Icon Rendering Documentation
- **D-05:** Add a section in guides/getting-started.md explaining that icons use hero-* CSS classes that require Heroicons setup in the host app. Reference Phoenix 1.8's default Heroicons configuration.

### Item 6: Configurable Theme Switcher Target
- **D-06:** Add `theme_switcher_target` option to Panel NimbleOptions (defaults to "dark"). The theme toggle switches between the panel's `theme` and this target. Update Layout to use the config.

### Item 7: CI Zero Warnings
- **D-07:** Ensure `mix format --check-formatted` and `mix test` produce zero warnings in CI. The `IO.warn` for missing on_mount is already suppressed in test env. Verify no other warnings exist.

### Claude's Discretion
- Exact test implementations for Hook/Dashboard/Plugin
- How to restructure LifecycleTest to fix the race condition
- Whether to use Phoenix.LiveViewTest or mock sockets for Hook tests

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit Source
- `.planning/v1.0-MILESTONE-AUDIT.md` — All 8 tech debt items with descriptions

### Files to Modify
- `lib/phoenix_filament/table/table_renderer.ex` — Item 1 (Button component)
- `test/phoenix_filament/resource/lifecycle_test.exs` — Item 2 (flaky test)
- `test/phoenix_filament/panel/hook_test.exs` — Item 3 (Hook tests)
- `test/phoenix_filament/panel/dashboard_test.exs` — Item 3 (Dashboard tests)
- `test/phoenix_filament/panel/hook_test.exs` — Item 4 (Plugin boot/hook tests)
- `guides/getting-started.md` — Item 5 (icon docs)
- `lib/phoenix_filament/panel/options.ex` — Item 6 (theme_switcher_target)
- `lib/phoenix_filament/panel/layout.ex` — Item 6 (use config)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PhoenixFilament.Components.Button` — Already exists with variants (primary, secondary, danger)
- `PhoenixFilament.ComponentCase` — Test helper for rendering function components
- Existing test patterns in `test/phoenix_filament/panel/` for reference

### Integration Points
- TableRenderer imports need to add Button
- Panel.Options needs new option
- Layout theme_switcher section needs to read new config

</code_context>

<specifics>
## Specific Ideas

- This is a cleanup phase — no new features, no new architecture
- Every fix should be small, focused, and independently testable
- CI must be green with zero warnings after all fixes

</specifics>

<deferred>
## Deferred Ideas

None — this phase closes all v0.1.0 debt.

</deferred>

---

*Phase: 09-tech-debt-cleanup*
*Context gathered: 2026-04-03*

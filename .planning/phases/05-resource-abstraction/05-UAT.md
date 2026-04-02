---
status: complete
phase: 05-resource-abstraction
source: [ROADMAP.md success criteria, BRAINSTORM.md deliverables]
started: 2026-04-02T02:00:00Z
updated: 2026-04-02T02:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Zero-code CRUD LiveView from use PhoenixFilament.Resource
expected: `use PhoenixFilament.Resource, schema: Post, repo: Repo` injects mount/3, handle_params/3, handle_event/3, handle_info/2, render/1 — plus __resource__/1 accessors.
result: pass
evidence: All 5 LiveView callbacks exported. Schema and repo accessors return correct modules.

### 2. Auto-discovers fields with sensible types
expected: Resource with no form/table blocks auto-discovers schema fields for both form_schema and table_columns.
result: pass
evidence: form_schema returns list of %Field{} structs, table_columns returns list of %Column{} structs, all auto-discovered from Post schema.

### 3. Override via form/table DSL
expected: Developer can add `form do...end` and `table do...end` blocks to customize. Custom definition replaces auto-generated default.
result: pass
evidence: Custom form with 2 fields (title, body), custom table with 2 columns (title, published) — overrides auto-discovery.

### 4. No compile-time cascade
expected: Touching the Ecto schema file does not trigger recompilation of resource modules.
result: pass
evidence: cascade_test.exs passes (1 test, 0 failures).

### 5. Authorization on every write
expected: `authorize!/4` calls resource's `authorize/3` callback before write. Raises UnauthorizedError on deny. Allows when no callback defined.
result: pass
evidence: No-callback module allows. Deny-callback module raises UnauthorizedError with message.

### 6. Changeset options (MFA tuple format)
expected: `create_changeset: {Module, :function}` and `update_changeset: {Module, :function}` accepted as NimbleOptions. Stored as tuples in opts, resolved to functions at runtime by Lifecycle.
result: pass
evidence: Both options stored correctly as `{PhoenixFilament.Test.Schemas.Post, :changeset}`.

### 7. defoverridable allows custom callbacks
expected: Developer can override render/1 or add custom handle_event clauses. Default callbacks still exist for non-overridden ones.
result: pass
evidence: Custom render/1 defined alongside default mount/3. Both function_exported? returns true.

### 8. Page titles auto-derived from label
expected: Index shows plural_label ("Articles"), New shows "New {label}" ("New Article"). Form and changeset_fn set for :new action.
result: pass
evidence: "Articles" for :index, "New Article" for :new, form and changeset_fn both non-nil.

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none]

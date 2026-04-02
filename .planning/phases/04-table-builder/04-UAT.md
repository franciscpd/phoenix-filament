---
status: complete
phase: 04-table-builder
source: [ROADMAP.md success criteria, BRAINSTORM.md deliverables]
started: 2026-04-02T00:30:00Z
updated: 2026-04-02T00:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. QueryBuilder composes valid Ecto queries (standalone)
expected: QueryBuilder.build_query/4 returns a valid Ecto.Query from schema + params + columns + filters, without any Panel or Resource dependency.
result: pass
evidence: Returns %Ecto.Query{} with correct from clause

### 2. Sort by column header
expected: Sort on sortable column produces correct order_by. Non-sortable column falls back to id DESC.
result: pass
evidence: `asc: p0.title` for title sort, `desc: p0.id` for non-sortable fallback

### 3. Search adds ilike across searchable columns
expected: Non-empty search adds ilike WHERE clause. Empty search skips it.
result: pass
evidence: Query contains "ilike" with search term, omits it when empty

### 4. Filters narrow results with WHERE clauses
expected: Active filter adds WHERE clause. Inactive filter is skipped.
result: pass
evidence: Filter %{published: "true"} produces where clause; empty filters produce no where

### 5. Row actions DSL accumulates
expected: `__resource__(:table_actions)` returns list of Action structs. Empty when no actions block.
result: pass
evidence: Returns list, CascadeResource (no actions block) returns []

### 6. Pagination adds limit/offset
expected: `apply_pagination/2` with page 3, per_page 25 produces query with limit and offset.
result: pass
evidence: Query string contains "limit" and "offset"

### 7. Params parse/encode roundtrip + security
expected: Params.parse/2 correctly parses sort, dir, page, per_page, search, filters from URL params. to_query_string/1 encodes back. Unknown atom keys are dropped (security fix for atom exhaustion).
result: pass
evidence: All fields parse correctly. Unknown filter key "nonexistent_xyz_123" dropped (returns %{}).

### 8. TableRenderer renders correct HTML with daisyUI classes
expected: table_header renders `<th>` with sort indicators and phx-click. empty_state renders alert with CTA button.
result: pass
evidence: Header has `<th>`, "Title", phx-click, sort indicator. Empty state has alert class, message, and CTA button.

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none]

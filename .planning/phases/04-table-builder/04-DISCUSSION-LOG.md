# Phase 4: Table Builder - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-01
**Phase:** 04-table-builder
**Areas discussed:** Table LiveView integration, Sort+Pagination+URL, Row actions, Filters, Empty state, Search, Column formatting

---

## Table LiveView Integration

### Data flow
| Option | Selected |
|--------|----------|
| Table queries DB internally | ✓ |
| Parent provides data | |
| Hybrid LiveComponent | |

### Streams
| Option | Selected |
|--------|----------|
| LiveComponent with streams | ✓ |
| Function component + parent streams | |

## Sort + Pagination + URL State

### URL encoding
| Option | Selected |
|--------|----------|
| Flat query params | ✓ |
| Encoded JSON | |
| Namespace per table | |

### Page sizes
| Option | Selected |
|--------|----------|
| 25/50/100 fixed | |
| 10/25/50/100 | |
| Configurable via DSL | ✓ |

## Row Actions

### DSL
| Option | Selected |
|--------|----------|
| actions/1 block | ✓ |
| Column opts | |
| Callback-based | |

### Delete confirmation
| Option | Selected |
|--------|----------|
| Modal component | ✓ |
| Browser confirm | |
| Inline confirm | |

### Event routing
| Option | Selected |
|--------|----------|
| Send to parent | ✓ |
| Handle internally | |
| Callback attrs | |

## Filters System

### DSL
| Option | Selected |
|--------|----------|
| filters/1 block | ✓ |
| Filter opts on columns | |
| Separate config | |

### Composition
| Option | Selected |
|--------|----------|
| AND | |
| OR | |
| Configurable | ✓ |

## Empty State

| Option | Selected |
|--------|----------|
| daisyUI alert + CTA | ✓ |
| Simple text | |
| Custom slot | |

## Search

| Option | Selected |
|--------|----------|
| searchable: true on columns | ✓ |
| Separate config | |
| Auto all text columns | |

## Column Formatting

| Option | Selected |
|--------|----------|
| format callback | ✓ |
| Render slot | |
| Both | |

## Deferred
- Full-text search, bulk actions, column reorder, CSV export, inline editing, multi-table

# PhoenixFilament

## What This Is

PhoenixFilament is a rapid application development framework for the Elixir/Phoenix ecosystem, inspired by FilamentPHP. It provides declarative DSL-based builders for forms, tables, and CRUD resources — all powered by LiveView and styled with Tailwind CSS. It enables developers to build admin panels and general-purpose interfaces while staying focused on business logic.

## Core Value

Developers can go from an Ecto schema to a fully functional, beautiful admin interface in minutes — with a declarative, idiomatic Elixir API that feels native to the Phoenix ecosystem.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Declarative Form Builder with Ecto changeset integration
- [ ] Declarative Table Builder with sorting, searching, and pagination
- [ ] Resource abstraction for auto-generated CRUD pages from Ecto schemas
- [ ] Admin Panel shell with sidebar navigation and dashboard layout
- [ ] Plugin architecture from day one (internals built as plugins)
- [ ] Theming system via Tailwind CSS v4 CSS variables
- [ ] BYO authentication via Plug-based middleware
- [ ] Hex package with `mix phx_filament.install` generator
- [ ] 100% LiveView components leveraging real-time capabilities
- [ ] Component library (inputs, selects, badges, buttons, modals, etc.)

### Out of Scope

- Built-in authentication system — users bring their own auth (phx.gen.auth, Guardian, etc.)
- Dead view support — 100% LiveView, no fallback to traditional views
- Tenancy/multi-tenant — high complexity, defer to future versions
- Notifications system — defer to v0.2.0+
- Widgets/dashboard builder — defer to v0.2.0+
- Infolists (read-only detail views) — defer to v0.2.0+
- Actions system (bulk actions, row actions) — limited scope in v0.1.0, full system later

## Context

- **Ecosystem gap:** The Elixir/Phoenix ecosystem lacks a FilamentPHP-equivalent. Existing solutions are either too minimal (individual component libraries) or too opinionated (full SaaS frameworks). PhoenixFilament fills the middle ground.
- **FilamentPHP reference:** FilamentPHP is extremely complex. v0.1.0 deliberately ships a lean core — forms, tables, resources, panel, and plugins — leaving advanced features for later versions.
- **API style:** Declarative DSL using Elixir macros, following the same patterns as Ecto schemas, Phoenix Router, and Absinthe. This makes it immediately familiar to Elixir developers.
- **Target audience:** Both experienced Phoenix developers seeking productivity gains AND developers migrating from Laravel/Rails who want a familiar admin panel workflow.
- **LiveView-first:** All components are LiveView components. This simplifies the architecture and unlocks real-time features (live validation, instant search, etc.) without extra complexity.
- **Documentation:** All documentation in English to maximize community reach.

## Constraints

- **Tech stack**: Elixir, Phoenix, LiveView, Tailwind CSS v4, Ecto — no external JS frameworks
- **Distribution**: Hex package with mix task installer (`mix phx_filament.install`)
- **Compatibility**: Must work with standard phx.gen.auth output and common auth libraries
- **API design**: Declarative macro-based DSL — must feel idiomatic to Elixir developers
- **Plugin-first**: Core features should be built using the same plugin API available to the community

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Declarative DSL (macros) over pipe-based or data-config API | Matches Elixir ecosystem conventions (Ecto, Router, Absinthe) | — Pending |
| BYO auth over built-in auth | Reduces scope, respects existing ecosystem choices | — Pending |
| LiveView-only, no dead views | Simplifies architecture, enables real-time features natively | — Pending |
| Plugin architecture from v0.1.0 | Forces good internal boundaries, enables community growth early | — Pending |
| CSS variables for theming (Tailwind v4) | Modern approach, easy customization, aligns with Tailwind v4 direction | — Pending |
| Hex + generator over template | Lower barrier to entry, works with existing Phoenix projects | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-31 after initialization*

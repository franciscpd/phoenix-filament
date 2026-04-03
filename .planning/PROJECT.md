# PhoenixFilament

## What This Is

PhoenixFilament is a rapid application development framework for the Elixir/Phoenix ecosystem, inspired by FilamentPHP. It provides declarative DSL-based builders for forms, tables, and CRUD resources — all powered by LiveView and styled with daisyUI 5 + Tailwind CSS v4. Developers go from an Ecto schema to a fully functional admin panel with sidebar navigation, dashboard widgets, and a plugin system — in minutes.

## Core Value

Developers can go from an Ecto schema to a fully functional, beautiful admin interface in minutes — with a declarative, idiomatic Elixir API that feels native to the Phoenix ecosystem.

## Current State

**Shipped:** v0.1.0 (2026-04-03)
**LOC:** 5,153 Elixir | **Tests:** 396 | **CI:** Green
**Repository:** https://github.com/franciscpd/phoenix-filament

### What's Included in v0.1.0

- Ecto schema introspection with compile-time cascade prevention
- Full daisyUI 5 component library (inputs, buttons, badges, modals, cards)
- Declarative Form Builder with sections, conditional visibility, real-time validation
- Declarative Table Builder with streams, pagination, sort, search, filters
- Zero-code CRUD Resource from Ecto schemas
- Admin Panel shell with daisyUI drawer sidebar, breadcrumbs, flash toasts
- Dashboard with 4 widget types (stats, charts via Chart.js, tables, custom)
- Plugin architecture (behaviour contract, built-in plugins prove the API)
- Igniter-based installer + resource generator
- Comprehensive HexDocs guides (getting-started, resources, plugins, theming)

## Requirements

### Validated

- Declarative Form Builder with Ecto changeset integration — v0.1.0
- Declarative Table Builder with sorting, searching, and pagination — v0.1.0
- Resource abstraction for auto-generated CRUD pages from Ecto schemas — v0.1.0
- Admin Panel shell with sidebar navigation and dashboard layout — v0.1.0
- Plugin architecture from day one (internals built as plugins) — v0.1.0
- Theming system via Tailwind CSS v4 CSS variables — v0.1.0
- BYO authentication via on_mount hook — v0.1.0
- Hex package with `mix phx_filament.install` generator — v0.1.0
- 100% LiveView components leveraging real-time capabilities — v0.1.0
- Component library (inputs, selects, badges, buttons, modals, etc.) — v0.1.0

### Active

(No active requirements — start next milestone to define)

### Out of Scope

- Built-in authentication system — users bring their own auth
- Dead view support — 100% LiveView
- Multi-tenancy — high complexity, defer to future versions
- Mobile native app — web-first, LiveView handles responsive

## Context

- **Ecosystem gap:** The Elixir/Phoenix ecosystem lacks a FilamentPHP-equivalent. PhoenixFilament fills this gap with a lean, idiomatic approach.
- **v0.1.0 shipped:** Foundation through Distribution complete. 61 requirements met. Plugin architecture proven with internals-as-plugins pattern.
- **Tech stack:** Elixir 1.17+, Phoenix 1.7+ (1.8 recommended), LiveView 1.1+, Ecto 3.11+, daisyUI 5, Tailwind v4, Igniter 0.7+
- **Documentation:** All documentation in English. 4 ExDoc guide pages + comprehensive @moduledoc on all public modules.

## Constraints

- **Tech stack**: Elixir, Phoenix, LiveView, Tailwind CSS v4, Ecto — no external JS frameworks
- **Distribution**: Hex package with mix task installer (`mix phx_filament.install`)
- **Compatibility**: Must work with standard phx.gen.auth output and common auth libraries
- **API design**: Declarative macro-based DSL — must feel idiomatic to Elixir developers
- **Plugin-first**: Core features built using the same plugin API available to the community

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Declarative DSL (macros) over pipe-based API | Matches Elixir conventions (Ecto, Router, Absinthe) | Good — natural DX |
| BYO auth over built-in auth | Reduces scope, respects ecosystem choices | Good — clean separation |
| LiveView-only, no dead views | Simplifies architecture, enables real-time features | Good — zero overhead |
| Plugin architecture from v0.1.0 | Forces good internal boundaries, enables community growth | Good — ResourcePlugin/WidgetPlugin prove it |
| daisyUI 5 for styling | Phoenix 1.8 bundles it, 30+ themes free | Good — zero custom CSS needed |
| Igniter for installer | AST-based, idempotent, ecosystem standard | Good — reliable patching |
| Chart.js as vendor asset | No npm needed, vendor pattern standard in Phoenix | Good — zero JS tooling |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-04-03 after v0.1.0 milestone*

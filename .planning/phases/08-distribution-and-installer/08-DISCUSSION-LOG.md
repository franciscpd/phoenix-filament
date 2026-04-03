# Phase 8: Distribution and Installer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-03
**Phase:** 08-distribution-and-installer
**Areas discussed:** Installer, Hex package configuration, Getting-started documentation, CSS/JS asset setup

---

## Installer (mix phx_filament.install)

| Question | Options | Selected |
|----------|---------|----------|
| Igniter or custom Mix.Task? | Igniter / Custom / Claude decides | Igniter |
| Panel module with example or empty? | Empty + comments / With example / Claude decides | Empty + comments |
| gen.resource command? | Yes for v0.1 / Install only / Claude decides | Yes for v0.1 |
| Repo auto-detect? | Auto + override / Always explicit / Claude decides | Auto + override |

## Hex Package Configuration

| Question | Options | Selected |
|----------|---------|----------|
| Phoenix/LiveView optional or required? | Optional with peers / Required / Claude decides | Optional with peers |

## Getting-Started Documentation

| Question | Options | Selected |
|----------|---------|----------|
| Where should docs live? | @moduledoc + ExDoc guides / README only / Claude decides | ExDoc guides |
| Getting-started scope? | Install→Gen→Run (3 steps) / Full tutorial (10+ min) / Claude decides | Full tutorial |

## CSS/JS Asset Setup

| Question | Options | Selected |
|----------|---------|----------|
| How to configure assets? | Patch app.css + copy vendor / Single bundle / Claude decides | Patch + copy vendor |

## Claude's Discretion

- Igniter API specifics
- Host app detection (web module, repo)
- CSS file contents
- Hook JS implementation
- Test strategy
- ExDoc config

## Deferred Ideas

- mix phx_filament.gen.plugin — v0.2
- mix phx_filament.gen.widget — v0.2
- Cheatsheet — v0.2
- Video tutorial — v0.2
- Livebook docs — v0.2

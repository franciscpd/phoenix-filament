# Phase 6: Panel Shell and Auth Hook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 06-panel-shell-and-auth-hook
**Areas discussed:** Panel Declaration and Resource Registration, Layout Shell Architecture, Auth Hook and Session Management, Dashboard and Landing Page

---

## Panel Declaration and Resource Registration

### Q1: How should a developer declare a panel and register resources?

| Option | Description | Selected |
|--------|-------------|----------|
| DSL block com resources | `use PhoenixFilament.Panel` + `resources do...end` block | ✓ |
| Lista simples de módulos | `resources: [PostResource, UserResource]` keyword list | |
| Auto-discovery | Auto-discover all Resource modules | |

**User's choice:** DSL block with `resources do...end`
**Notes:** Follows Phoenix Router DSL conventions. Allows per-resource metadata (icon, nav_group, slug).

### Q2: How should the router macro work?

| Option | Description | Selected |
|--------|-------------|----------|
| Macro gera live routes | `phoenix_filament_panel` auto-generates all live routes | ✓ |
| Macro gera scope, rotas manuais | Macro generates scope, developer declares routes manually | |
| Você decide | Claude decides | |

**User's choice:** Macro generates live routes automatically
**Notes:** Zero manual route declarations. Dashboard route included.

### Q3: Should resources support nav_group in sidebar?

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, com nav_group opcional | Resources grouped by nav_group heading | ✓ |
| Lista flat sem grupos | No grouping | |
| Você decide | Claude decides | |

**User's choice:** Optional nav_group with grouped sidebar headings

### Q4: Should Panel support multiple panels in the same app?

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, múltiplos paineis | Each panel is independent module with own resources/theme/auth | ✓ |
| Um painel só em v0.1 | Single panel, multi deferred to v0.2 | |
| Você decide | Claude decides | |

**User's choice:** Multiple panels from v0.1

### Q5: How should route slugs work?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-derivado + override | Auto from schema name, override with `slug:` option | ✓ |
| Sempre auto-derivado | No override | |
| Sempre explícito | Always declared manually | |

**User's choice:** Auto-derived with override option

### Q6: Panel global options beyond path/on_mount?

| Option | Description | Selected |
|--------|-------------|----------|
| Opções essenciais apenas | path, on_mount, theme, brand_name, logo, theme_switcher | ✓ |
| Mínimo absoluto | Only path and on_mount | |
| Full-featured | All options from v0.1 | |

**User's choice:** Essential options only

---

## Layout Shell Architecture

### Q1: How should the panel shell wrap resources?

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView layout via on_mount | Layout via live_session, on_mount injects assigns | ✓ |
| LiveComponent wrapper | PanelShell LiveComponent wrapping resources | |
| Nested LiveView | Panel as outer LiveView with nested live_render | |

**User's choice:** LiveView layout via on_mount + live_session

### Q2: Should sidebar use daisyUI drawer pattern?

| Option | Description | Selected |
|--------|-------------|----------|
| daisyUI drawer | `drawer` + `drawer-open` with built-in responsiveness | ✓ |
| Custom sidebar component | Custom Tailwind utilities | |
| Você decide | Claude decides | |

**User's choice:** daisyUI drawer pattern

### Q3: How should breadcrumbs work?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-gerado do panel + resource | Brand → plural_label → action, auto-computed | ✓ |
| Sempre manual | Developer declares breadcrumbs explicitly | |
| Você decide | Claude decides | |

**User's choice:** Auto-generated from panel + resource metadata

### Q4: Flash notification style?

| Option | Description | Selected |
|--------|-------------|----------|
| Toast (daisyUI toast) | Fixed position, auto-dismiss, alert-success/error | ✓ |
| Alert inline no topo | Alert bars above content | |
| Você decide | Claude decides | |

**User's choice:** daisyUI toast pattern with auto-dismiss

### Q5: Icon system for sidebar?

| Option | Description | Selected |
|--------|-------------|----------|
| Heroicons com slot de escape | hero-* strings default, slot for custom SVG | ✓ |
| Heroicons apenas | Only hero-* strings | |
| Você decide | Claude decides | |

**User's choice:** Heroicons with escape hatch, fallback to first letter

---

## Auth Hook and Session Management

### Q1: How should on_mount integrate with host app auth?

| Option | Description | Selected |
|--------|-------------|----------|
| on_mount na live_session | Panel generates live_session with developer's on_mount | |
| Plug pipeline | Auth via Plug pipeline only | |
| Ambos (plug + on_mount) | Plug for HTTP + on_mount for LiveView reconnects | ✓ |

**User's choice:** Both plug and on_mount (belt and suspenders)

### Q2: How should plug + on_mount be configured?

| Option | Description | Selected |
|--------|-------------|----------|
| on_mount no Panel, plug manual | Developer adds pipe_through manually | |
| Panel aceita plug + on_mount | Panel configures both, injects plug into scope | ✓ |
| Você decide | Claude decides | |

**User's choice:** Panel accepts both plug and on_mount in configuration

### Q3: How should real-time session revocation work?

| Option | Description | Selected |
|--------|-------------|----------|
| PubSub broadcast via user topic | Subscribe to user topic, broadcast :session_revoked | ✓ |
| LiveView disconnect/2 | Use LiveView 1.1 disconnect function | |
| Sem revogação em v0.1 | Defer to v0.2 | |

**User's choice:** PubSub broadcast via user topic

### Q4: Helper function or just docs for revocation?

| Option | Description | Selected |
|--------|-------------|----------|
| Helper function + docs | `PhoenixFilament.Panel.revoke_sessions/2` helper | ✓ |
| Só documentar o padrão | Docs only, developer implements manually | |
| Você decide | Claude decides | |

**User's choice:** Helper function + documentation

### Q5: Should on_mount be required or optional?

| Option | Description | Selected |
|--------|-------------|----------|
| Opcional com warning | Works without auth, logs warning in dev | ✓ |
| Obrigatório sempre | Compile error without on_mount | |
| Você decide | Claude decides | |

**User's choice:** Optional with compile-time warning

---

## Dashboard and Landing Page

### Q1: How should the dashboard work?

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView simples com slots | Simple LiveView with resource cards | |
| Customização via widgets DSL | DSL with built-in widget types | ✓ |
| Sem dashboard em v0.1 | Redirect to first resource | |

**User's choice:** Widgets DSL (inspired by FilamentPHP's 4 widget types)
**Notes:** User asked "Como é no FilamentPHP?" — researched FilamentPHP widget architecture. Decision based on FilamentPHP reference.

### Q2: Which widget types for v0.1?

| Option | Description | Selected |
|--------|-------------|----------|
| Stat card | Cards with label/value/description/icon/color/sparkline | ✓ |
| Table widget | Reuses Table Builder inside dashboard | ✓ |
| Custom widget | Free-form LiveComponent | ✓ |
| Chart widget | Chart.js via JS hook | ✓ |

**User's choice:** All 4 widget types

### Q3: How should widgets be declared?

| Option | Description | Selected |
|--------|-------------|----------|
| Módulos separados + registro no Panel | Each widget is a module, registered via `widgets do...end` | ✓ |
| Inline DSL no Panel | Widgets declared directly in Panel module | |
| Você decide | Claude decides | |

**User's choice:** Separate modules registered in Panel

### Q4: Which JS chart library?

| Option | Description | Selected |
|--------|-------------|----------|
| Chart.js via JS hook | Chart.js + LiveView colocated hook | ✓ |
| SVG puro | Server-side SVG generation | |
| Você decide | Claude decides | |

**User's choice:** Chart.js via colocated JS hook

### Q5: Dashboard grid layout?

| Option | Description | Selected |
|--------|-------------|----------|
| Grid 12-col com column_span | 12-column Tailwind grid, column_span per widget | ✓ |
| Layout simples (stack) | Vertical stack, no grid | |
| Você decide | Claude decides | |

**User's choice:** 12-column responsive grid with column_span

### Q6: Widget polling support?

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, polling configurável | `@polling_interval` per widget | ✓ |
| Sem polling em v0.1 | Static widgets only | |
| Você decide | Claude decides | |

**User's choice:** Configurable polling per widget

### Q7: Custom dashboard LiveView override?

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, dashboard: CustomLive opcional | Override with custom LiveView, renders inside panel shell | ✓ |
| Sem override em v0.1 | Only widget DSL | |
| Você decide | Claude decides | |

**User's choice:** Optional custom LiveView override

---

## Claude's Discretion

- Internal router macro expansion implementation
- Panel hook module structure
- Widget LiveComponent implementation details
- Chart.js hook specifics
- Tailwind classes for layout/sidebar/breadcrumbs
- Panel metadata storage mechanism (ETS, module attributes, etc.)
- Flash auto-dismiss timing and animation

## Deferred Ideas

- Dashboard global filters (date range form) — v0.2
- Widget lazy loading — v0.2
- Sidebar collapse state persistence — v0.2
- User menu dropdown in topbar — v0.2
- Footer customization — v0.2
- Custom pages per panel — v0.2
- Widget header/footer on Resource list pages — v0.2
- Breadcrumb override callback — v0.2

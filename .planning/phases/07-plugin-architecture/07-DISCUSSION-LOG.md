# Phase 7: Plugin Architecture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-03
**Phase:** 07-plugin-architecture
**Areas discussed:** Plugin behaviour contract, Plugin registration in Panel, Resource as built-in plugin, Plugin developer experience

---

## Plugin Behaviour Contract

### Q1: Which callbacks should the Plugin behaviour have?

| Option | Description | Selected |
|--------|-------------|----------|
| register/1 + boot/1 | register returns metadata, boot receives socket at mount | ✓ |
| init/1 único callback | Single callback returning everything | |
| Você decide | Claude decides | |

**User's choice:** register/1 + boot/1 — separation of declaration vs runtime

### Q2: What should register/1 return?

| Option | Description | Selected |
|--------|-------------|----------|
| Nav + routes + widgets (v0.1 mínimo) | Without lifecycle hooks | |
| Nav + routes + widgets + lifecycle hooks | Including :hooks for attach_hook | ✓ |
| Você decide | Claude decides | |

**User's choice:** Full return including lifecycle hooks

### Q3: boot/1 return type?

| Option | Description | Selected |
|--------|-------------|----------|
| Socket → Socket simples | No halt capability. Auth is Panel's job. | ✓ |
| {:cont, socket} / {:halt, socket} | Can block mount | |
| Você decide | Claude decides | |

**User's choice:** Simple socket → socket. Plugins cannot block mount.

### Q4: Should callbacks be required or optional?

| Option | Description | Selected |
|--------|-------------|----------|
| register required, boot optional | Metadata essential, boot for plugins that need runtime init | ✓ |
| Both required | Both @impl required | |
| Você decide | Claude decides | |

**User's choice:** register/1 required, boot/1 @optional_callbacks

### Q5: Should register return fields be required?

| Option | Description | Selected |
|--------|-------------|----------|
| All optional with defaults | Plugin returns only what it uses | ✓ |
| All required | Always return full map | |
| Você decide | Claude decides | |

**User's choice:** Optional with defaults (framework merges with empty defaults)

---

## Plugin Registration in Panel

### Q1: How to register plugins in Panel?

| Option | Description | Selected |
|--------|-------------|----------|
| DSL block plugins do...end | New block alongside resources/widgets | ✓ |
| Keyword list plugins: [...] | Simple keyword option | |
| Everything via plugins (remove resources/widgets) | Breaking change | |

**User's choice:** DSL block `plugins do...end`

### Q2: Plugin configuration options?

| Option | Description | Selected |
|--------|-------------|----------|
| Keyword list optional | plugin MyPlugin, option: value | ✓ |
| No options in v0.1 | Configuration via Application env | |
| Você decide | Claude decides | |

**User's choice:** Keyword list options passed to register/2

### Q3: Plugin ordering/priority?

| Option | Description | Selected |
|--------|-------------|----------|
| Declaration order | Built-in first, then community in order | ✓ |
| Priority number | Explicit priority: N | |
| Você decide | Claude decides | |

**User's choice:** Declaration order. Built-in always first.

---

## Resource as Built-in Plugin

### Q1: How to make Resource a plugin without breaking API?

| Option | Description | Selected |
|--------|-------------|----------|
| ResourcePlugin implícito | resources do...end auto-generates ResourcePlugin | ✓ |
| Resource explícito como plugin | Breaking change, remove resources block | |
| Você decide | Claude decides | |

**User's choice:** Implicit ResourcePlugin. Developer API unchanged.

### Q2: Same for widgets?

| Option | Description | Selected |
|--------|-------------|----------|
| WidgetPlugin implícito | Same pattern as ResourcePlugin | ✓ |
| Widgets stay as-is | Only resources become plugin | |
| Você decide | Claude decides | |

**User's choice:** Both become implicit plugins

### Q3: How should Router/Hook consume plugins?

| Option | Description | Selected |
|--------|-------------|----------|
| Unified plugin registry | Panel resolves all plugins, merges into unified lists | ✓ |
| Read plugins individually | Router iterates each plugin | |
| Você decide | Claude decides | |

**User's choice:** Unified registry via __panel__(:all_routes), :all_nav_items, etc.

---

## Plugin Developer Experience

### Q1: @experimental stability contract?

| Option | Description | Selected |
|--------|-------------|----------|
| @experimental with breaking change policy | May break in minor versions until stable | ✓ |
| Stable from v0.1 | No breaking changes without major | |
| Você decide | Claude decides | |

**User's choice:** @experimental in v0.1

### Q2: use PhoenixFilament.Plugin macro?

| Option | Description | Selected |
|--------|-------------|----------|
| use macro with helpers | nav_item/2, route/3 helpers imported | ✓ |
| Só @behaviour | Developer builds maps manually | |
| Você decide | Claude decides | |

**User's choice:** use macro with helper functions

### Q3: Plugin developer guide?

| Option | Description | Selected |
|--------|-------------|----------|
| Comprehensive @moduledoc + HexDocs | Full guide covering all plugin capabilities | ✓ |
| Basic @moduledoc only | Minimal docs, full guide in v0.2 | |
| Você decide | Claude decides | |

**User's choice:** Comprehensive guide in @moduledoc + HexDocs

---

## Claude's Discretion

- Struct types for nav_item, route, widget in plugin context
- Plugin resolution merge strategy in __before_compile__
- ResourcePlugin/WidgetPlugin internal implementation
- Helper function implementations
- Test strategy
- Backward-compatible refactor of Router/Hook

## Deferred Ideas

- Plugin dependency resolution — v0.2
- Plugin config validation via NimbleOptions — v0.2
- Plugin hot-reload — v0.2
- Plugin marketplace — v1.0+
- Plugin middleware pipeline — v0.2
- Plugin asset bundling (JS/CSS) — v0.2

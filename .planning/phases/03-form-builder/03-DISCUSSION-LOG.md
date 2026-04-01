# Phase 3: Form Builder - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-01
**Phase:** 03-form-builder
**Areas discussed:** Form LiveView integration, Layout system, Conditional visibility, Changeset integration

---

## Form LiveView Integration

### Render approach

| Option | Description | Selected |
|--------|-------------|----------|
| Function component | Stateless component, parent owns state | ✓ |
| LiveComponent | Stateful, owns changeset internally | |
| Hybrid | Function for v0.1, LiveComponent in v0.2 | |

**User's choice:** Function component

### Component naming

| Option | Description | Selected |
|--------|-------------|----------|
| pf_form | Prefixed to avoid collision with Phoenix <.form> | |
| resource_form | Descriptive but implies Resource coupling | |
| form_builder | Matches module name, explicit | ✓ |

**User's choice:** form_builder

### Form wrapping

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-wrap | form_builder renders <.form> internally | ✓ |
| Developer wraps | form_builder only renders field list | |

**User's choice:** Auto-wrap

### Submit button

| Option | Description | Selected |
|--------|-------------|----------|
| Auto submit button | Configurable label, submit={false} to hide | ✓ |
| No auto button | Developer provides own button | |
| Via :actions slot | Default content with override slot | |

**User's choice:** Auto submit button with configurable label

---

## Layout System (sections/grid)

### Sections

| Option | Description | Selected |
|--------|-------------|----------|
| section/2 macro | Groups fields with heading, renders as fieldset | ✓ |
| Flat fields with group attr | Fields carry group: option | |
| No sections in v0.1 | Defer FORM-05 entirely | |

**User's choice:** section/2 macro

### Multi-column grid

| Option | Description | Selected |
|--------|-------------|----------|
| columns/2 macro | CSS grid with explicit column count | ✓ |
| Column count on field | col_span: option per field | |
| No grid in v0.1 | Defer multi-column | |

**User's choice:** columns/2 macro

---

## Conditional Visibility (visible_when)

### Evaluation mode

| Option | Description | Selected |
|--------|-------------|----------|
| Client-side JS | JS.show/JS.hide, no server round-trip | ✓ |
| Server-side | phx-change event, adds latency | |
| Hybrid | Simple → client, complex → server | |

**User's choice:** Client-side JS

### Condition syntax

| Option | Description | Selected |
|--------|-------------|----------|
| Tuple syntax | {field, operator, value} — :eq, :neq, :in, :not_in | ✓ |
| Function syntax | Anonymous fn, maximum flexibility | |
| Both tuple + function | Two code paths | |

**User's choice:** Tuple syntax

---

## Changeset Integration

### Create vs update changesets

| Option | Description | Selected |
|--------|-------------|----------|
| Resource-level opts | Declared on Resource (Phase 5), form receives @form | ✓ |
| Form-level declaration | Form DSL declares changeset fns | |
| Both levels | Form optional, Resource overrides | |

**User's choice:** Resource-level opts (Form Builder is changeset-agnostic)

### Validation trigger

| Option | Description | Selected |
|--------|-------------|----------|
| phx-change on form | Standard Phoenix pattern | ✓ |
| phx-blur per field | Validates only on blur | |
| Configurable per field | Default change, opt-in blur | |

**User's choice:** phx-change on form

---

## Claude's Discretion

- Internal data structure for sections/columns layout info
- visible_when → JS compilation strategy
- Test strategy for client-side visibility
- Fieldset/legend daisyUI classes

## Deferred Ideas

- LiveComponent wrapper (v0.2+)
- Per-field validate_on: :blur (v0.2+)
- Nested forms / embeds_many (v0.2+)

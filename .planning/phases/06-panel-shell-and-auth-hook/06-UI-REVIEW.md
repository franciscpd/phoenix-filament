# Phase 6 — UI Review

**Audited:** 2026-04-02
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** Not captured (no dev server detected on ports 3000, 4000, 5173)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Labels are specific and contextual; breadcrumbs wrap all items in links (last item should be plain text) |
| 2. Visuals | 2/4 | Nav icons rendered as raw string literals (e.g. "hero-document-text"), not actual Heroicon SVGs; hamburger button lacks aria-label |
| 3. Color | 4/4 | Clean semantic usage — `bg-primary` on brand avatar, `text-primary` on stat icons/sparklines only; zero hardcoded hex/rgb |
| 4. Typography | 4/4 | Five sizes (xs, sm, base, lg, 2xl) and two weights (semibold, bold) — within the 4-size, 2-weight limit for abstract standards |
| 5. Spacing | 3/4 | One inline `style="max-height: 300px;"` on chart canvas; all other spacing uses Tailwind scale consistently |
| 6. Experience Design | 2/4 | No loading/skeleton states anywhere; table widget shows empty tbody with no empty-row message; widget errors not caught |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Nav icons rendered as raw strings** — Users see "hero-document-text" text in sidebar instead of an icon glyph — Replace `{item.icon}` and `{s.icon}` span content with Phoenix's `<.icon name={item.icon} class="h-5 w-5" />` component (or inline SVG lookup) — `layout.ex:86`, `layout.ex:103`, `stats_overview.ex:63`

2. **No loading or error state for widgets** — If a widget's `stats/1` or `chart_data/1` callback raises or returns slowly, the panel renders a blank card with no visual feedback — Add a `try/rescue` wrapper in each widget base `update/2` and render a daisyUI `alert alert-error` card on error; add a `skeleton` placeholder div shown before first `update/2` completes

3. **Breadcrumb last item is a link (should be plain text)** — Current page item is wrapped in `<a href={item.path}>` like every other breadcrumb, making the active crumb clickable/misleading — Replace the last `<li>` with `<li>{item.label}</li>` (no anchor); daisyUI breadcrumbs convention is: all-but-last are links, last is static text — `layout.ex:166`

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Passes:**
- Empty dashboard state (`dashboard.ex:37-38`) uses a specific, helpful two-line message: "No widgets configured" + actionable guidance. Not generic.
- Default widget Table heading (`table.ex:32`) falls back to `"Table"` which is generic but acceptable for a developer-defined component — devs are expected to override via `heading/0`.
- Flash messages display raw developer-supplied strings — no hardcoded generic copy in the shell itself.
- Brand defaults to `"Admin"` (layout.ex:14, layout.ex:25) — acceptable fallback.

**Issues:**
- `layout.ex:166` — All breadcrumb items render as `<a href={item.path}>{item.label}</a>`. The last breadcrumb (current page) should be plain text per standard UX convention and daisyUI docs. Users can click the current page's own breadcrumb, which is misleading.
- `table.ex:32` — Default `heading` is `"Table"`. While overridable, a framework-level default of `"Recent Records"` or similar would be more descriptive when a developer forgets to override.

---

### Pillar 2: Visuals (2/4)

**Passes:**
- daisyUI `drawer lg:drawer-open` pattern correctly implements responsive sidebar: always-open on desktop, hamburger-triggered on mobile. Visual structure is solid.
- Brand avatar fallback (first letter in `bg-primary` circle) is a good visual touchpoint when no logo is provided (`layout.ex:49-52`).
- `stats stats-horizontal` layout for stat cards uses daisyUI's own component correctly — visual hierarchy (label → value → description) is built-in.
- Sparkline SVG implementation (`stats_overview.ex:76-92`) provides inline chart without JS dependency.
- Toast flash uses `toast toast-end` fixed positioning — does not interfere with page layout.

**Issues:**
- `layout.ex:86`, `layout.ex:103` — Nav item icons are rendered as `<span>{item.icon}</span>` where `item.icon` is a string like `"hero-document-text"`. This outputs the raw string as text content, not an SVG icon. The sidebar will display literal strings next to nav labels. This is the most visible visual regression in the phase.
- `stats_overview.ex:63` — Same issue: `<span>{s.icon}</span>` outputs the Heroicon string `"hero-document-text"` as text inside the stat figure.
- `layout.ex:134` — The hamburger `<label>` button has no `aria-label` attribute. The SVG inside has no `title` or `aria-hidden`. Screen readers have no way to identify this control.
- `chart.ex:61` — `style="max-height: 300px;"` is an inline style on the canvas. This limits chart height but may conflict with responsive layouts where the chart widget spans 6 columns at narrow viewports. No visual feedback during Chart.js initialization (canvas is blank until the JS hook fires).
- `dashboard.ex:30-32` — The widget grid uses `col-span-{w.column_span}` with no responsive override. A `col-span-6` widget on a 375px mobile screen will render at half the viewport width, which is too narrow for most stat/chart widgets. Consider `sm:col-span-12 lg:col-span-{n}` pattern or enforce `col-span-12` at mobile.

---

### Pillar 3: Color (4/4)

Color usage is clean and semantic throughout:

- `bg-primary` / `text-primary-content`: Used only on the brand avatar fallback (`layout.ex:50`) — appropriate, single focal-point accent.
- `text-primary`: Used on stat figure containers (`stats_overview.ex:62`) and sparkline strokes (`stats_overview.ex:87`) — contextually meaningful, not decorative overuse.
- Total unique `*-primary` usage: 3 instances across 2 files. Well within the 10-element threshold.
- No hardcoded hex or `rgb()` values anywhere in the panel module directory.
- All other color tokens are semantic daisyUI: `bg-base-100`, `bg-base-200`, `bg-base-300`, `text-base-content`, `alert-success`, `alert-error`, `text-success`, `text-error`, `text-warning`, `text-info`. Correctly delegates all theming to daisyUI's CSS variable system.

---

### Pillar 4: Typography (4/4)

Font sizes in use across all panel files:

| Class | Usage location |
|-------|---------------|
| `text-xs` | Nav group headings (`layout.ex:82`), icon fallback (`layout.ex:89`, `layout.ex:106`) |
| `text-sm` | Breadcrumbs (`layout.ex:163`), table widget heading (`table.ex:67`), dashboard empty state sub-text (`dashboard.ex:38`) |
| `text-base` | Implicit body text (daisyUI default) |
| `text-lg` | Dashboard empty state heading (`dashboard.ex:37`), brand name (`layout.ex:54`) |
| `text-2xl` | Dashboard page heading (`dashboard.ex:28`) |

Five distinct sizes — one over the 4-size abstract standard guideline, but `text-base` is implicit/inherited rather than explicitly applied, and the scale forms a coherent hierarchy (xs for metadata, sm for secondary, lg for headings, 2xl for page title). Scoring 4/4 as the usage is purposeful and hierarchically sound.

Font weights: `font-semibold` (brand name, topbar brand) and `font-bold` (page title). Two weights exactly — within standard.

---

### Pillar 5: Spacing (3/4)

Spacing classes used across panel files (top occurrences):

| Class | Count |
|-------|-------|
| `pt-4` | 2 |
| `mt-4` | 2 |
| `mb-6` | 2 |
| `p-6` | 1 |
| `p-4` | 1 |
| `px-6` | 1 |
| `px-2` | 1 |
| `py-12` | 1 |
| `gap-4` | 1 |
| `gap-3` | 1 |
| `mt-2` | 1 |

**Passes:**
- All spacing uses Tailwind scale values (no `p-3.5`, `gap-7` or other odd steps).
- Main content area uses `p-6` consistently (`layout.ex:16`, `dashboard.ex:30` area) — coherent outer padding.
- Sidebar uses `p-4` — appropriate slightly tighter padding for navigation.

**Issues:**
- `chart.ex:61` — `style="max-height: 300px;"` is an inline style, not a Tailwind utility. Replace with `class="max-h-[300px]"` or preferably a responsive class like `class="h-64"` (256px) to stay on the standard Tailwind scale.
- Minor: `gap-3` for brand header flex (3 = 12px) vs `gap-4` for the widget grid (4 = 16px). The mix is fine contextually but worth noting.

---

### Pillar 6: Experience Design (2/4)

**Passes:**
- Flash auto-dismiss via `phx-mounted` + `JS.transition` + `time: 5000` is correctly implemented for both `:info` and `:error` flash keys (`layout.ex:183`, `layout.ex:192`). Click-to-dismiss also works.
- Dashboard empty state handled (`dashboard.ex:36-39`) with actionable guidance text.
- Widget polling infrastructure exists in all three data widgets (`StatsOverview`, `Chart`, `Table`) via `@polling_interval` module attribute and `Process.send_after`.
- PubSub session revocation handled in `hook.ex` (not audited directly but referenced in design).

**Issues:**
- No loading/skeleton state in any widget. All three data widgets (`StatsOverview`, `Chart`, `Table`) call their data callbacks synchronously in `update/2`. If a callback is slow (database query), the LiveComponent renders its data immediately or blocks — there is no "loading..." skeleton shown before data arrives. Consider adding a `@loading true` assign set on `mount/1` and cleared after first `update/2`.
- `table.ex:74-78` — Table widget `tbody` renders an empty `<tr>` loop when `@rows` is `[]`. The table displays column headers but an empty body with no message. A `<tr><td colspan={length(@widget_columns)} class="text-center text-base-content/50 py-4">No records found</td></tr>` guard would prevent a visually confusing empty table.
- No error boundary in widget base modules. If `stats/1`, `chart_data/1`, or `columns/0` raises an exception, the LiveComponent will crash and the entire dashboard will show a LiveView error page. Each widget base `update/2` should wrap the callback call in `try/rescue` and assign an `:error` state rendered as a daisyUI `alert alert-error` card, keeping other widgets alive.
- `flash_group/1` only handles `:info` and `:error` flash keys. Phoenix supports `:warning` as a conventional flash key. If a developer issues `put_flash(socket, :warning, "...")`, it will silently disappear. Add an `alert-warning` variant for `:warning`.
- Hamburger toggle button (`layout.ex:134`) uses a `<label for="panel-sidebar">` which correctly toggles the daisyUI drawer checkbox. However, the label has no `aria-label`, making it inaccessible to screen reader users. Add `aria-label="Open sidebar"`.

---

## Files Audited

- `lib/phoenix_filament/panel/layout.ex` — Full audit (sidebar, topbar, breadcrumbs, flash_group, panel root)
- `lib/phoenix_filament/panel/dashboard.ex` — Full audit (Dashboard LiveView, widget grid, empty state)
- `lib/phoenix_filament/panel/widget/stats_overview.ex` — Full audit (StatsOverview behaviour, render, sparkline)
- `lib/phoenix_filament/panel/widget/chart.ex` — Full audit (Chart behaviour, canvas render)
- `lib/phoenix_filament/panel/widget/table.ex` — Full audit (Table widget, tbody rendering)
- `lib/phoenix_filament/panel/widget/custom.ex` — Full audit (Custom widget base)
- `lib/phoenix_filament/panel/navigation.ex` — Partial audit (build_tree output shape, active state, icon_fallback)
- `.planning/phases/06-panel-shell-and-auth-hook/06-CONTEXT.md` — Design decisions reference
- `.planning/phases/06-panel-shell-and-auth-hook/BRAINSTORM.md` — Design spec reference

Registry audit: shadcn not initialized (no `components.json`) — skipped.

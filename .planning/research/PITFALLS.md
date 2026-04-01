# Domain Pitfalls

**Domain:** Phoenix/LiveView admin framework with macro-based DSL and plugin system
**Researched:** 2026-03-31
**Confidence:** MEDIUM-HIGH (mix of official docs and community sources)

---

## Critical Pitfalls

Mistakes that cause rewrites or major architectural changes.

---

### Pitfall 1: Macro-Induced Compile-Time Dependency Cascades

**What goes wrong:** Every module that `use`s your DSL macro creates compile-time dependencies on every module argument it receives at macro-expansion time. A change to `MyApp.Authentication` forces recompilation of every resource module that referenced it via DSL — even if it is only a runtime dependency. As the application grows, changing any core DSL macro triggers a full project recompile. Developer feedback loops collapse from seconds to minutes.

**Why it happens:** Elixir macros execute at compile time, and their arguments become compile-time dependencies. When your DSL macro expands `use PhoenixFilament.Resource, schema: MyApp.Post`, the compiler now tracks `MyApp.Post` as a compile-time dependency of the caller. Any change to `MyApp.Post` causes the caller to recompile. At scale, transitive dependency chains can cause 80% of a project to recompile when a single schema changes.

**Consequences:** Projects using PhoenixFilament become slow to iterate on. Plugin authors experience the same pain. The framework gets a reputation for destroying compile times — a common complaint against macro-heavy Elixir frameworks like early Ash versions.

**Prevention:**
- Use `Macro.expand_literals/2` when expanding module references in macro arguments so they resolve as runtime dependencies rather than compile-time dependencies.
- Delay schema inspection to runtime using `Code.ensure_loaded!/1` and `apply/3` instead of calling schema functions at macro expansion time.
- Benchmark compile times early: create a test app with 50 resource modules and measure recompile after touching a schema. If it recompiles everything, fix it before shipping.
- Follow the official Elixir [Meta-programming anti-patterns](https://hexdocs.pm/elixir/macro-anti-patterns.html) guidelines.

**Warning signs:**
- Changing a schema file causes more than 5 modules to recompile.
- CI compile times grow linearly with resource count.
- Users complain about slow `mix compile` after adding more resources.

**Phase to address:** Phase 1 (DSL foundation). Compile-dependency strategy must be decided before any resource macro is written. Retrofitting is painful.

---

### Pitfall 2: Overusing Macros When Data Structures Suffice

**What goes wrong:** Macro-based DSLs are harder to write, test, and debug than equivalent data structure-based approaches. When the entire configuration is captured in macros, dynamic or conditional behavior becomes impossible — you cannot conditionally add a field based on runtime configuration. Users end up writing `if` blocks inside DSL blocks, which macros often do not handle cleanly, leading to confusing error messages and workarounds.

**Why it happens:** The appeal of the Ecto/Router-style macro API is real, but those DSLs work because they describe static, schema-like structures. Admin framework DSLs need runtime flexibility: hide a field based on user permissions, change a column label based on locale, add fields from a plugin at runtime. Pure macros cannot do this cleanly.

**Consequences:** Users report that the DSL "doesn't let me do X." Workarounds proliferate: callback modules, override hooks, escape hatches that bypass the DSL entirely. The framework becomes two systems: the declarative macro path and the "real code" path.

**Prevention:**
- Use macros to register intent (which fields, which columns) into module attributes at compile time, then evaluate that data at runtime using functions.
- The macro's job is to build a data structure (`%FieldDefinition{}`, `%ColumnDefinition{}`). The rendering logic reads that structure at runtime and can apply runtime context (current user, locale, permissions) before rendering.
- The canonical pattern in Elixir: `__using__` macro + `@before_compile` to accumulate module attributes, then a runtime function that reads those attributes and applies dynamic logic.
- Evaluate whether Spark (the DSL builder from the Ash project) is worth adopting — it solves many of these problems at the cost of a heavy dependency.

**Warning signs:**
- DSL blocks cannot contain `if` or `case` expressions.
- Users ask how to "conditionally show a field based on user role" and the answer is "you can't."
- Trying to write tests for DSL behavior requires compiling new modules dynamically.

**Phase to address:** Phase 1 (DSL foundation). This is an architectural decision that affects every subsequent feature.

---

### Pitfall 3: Excessive Code Generation in Macros

**What goes wrong:** Each `use PhoenixFilament.Resource` call expands into hundreds of lines of generated code: render functions, event handlers, change tracking logic, etc. With 50 resources, compile artifacts become enormous. Compilation slows, BEAM bytecode bloats, and runtime memory increases because all generated functions are loaded.

**Why it happens:** It is tempting to generate complete LiveView modules from a DSL definition. The pattern is clean: one macro call produces a full working page. But each macro invocation copies the same boilerplate code inline rather than delegating to shared functions.

**Consequences:** Large applications become slow to compile and deploy. Hot code reloading in development feels sluggish. Code intelligence tools (ElixirLS) struggle with large generated modules.

**Prevention:**
- Move all logic out of `quote/1` blocks into real functions in the framework's core modules.
- The generated code should be thin delegation: `def handle_event(event, params, socket), do: PhoenixFilament.Resource.handle_event(__resource__(), event, params, socket)`.
- Only generate the minimum: the module's `__resource__()` function that returns the compiled DSL configuration struct.
- Test the generated code size: `IO.inspect(Macro.expand(quote(do: use PhoenixFilament.Resource, schema: Post), __ENV__))` should be small.

**Warning signs:**
- `mix compile` output shows individual resource modules as large files.
- Adding a new resource increases overall compile time by >10 seconds.
- ElixirLS or Credo struggles to analyze resource modules.

**Phase to address:** Phase 1 (DSL foundation) and Phase 2 (Resource abstraction). Establish the thin-delegation pattern before building any feature.

---

### Pitfall 4: Plugin API Instability Breaking the Ecosystem

**What goes wrong:** The plugin API ships as part of v0.1.0. A feature needed for v0.2.0 (e.g., infolists, actions) requires changing the plugin callback contract. Every existing plugin now breaks. Plugin authors abandon the project. The ecosystem never forms.

**Why it happens:** Building the plugin API before fully understanding what plugins need to do is premature. The project says "internals built as plugins" — but if the internals change (because they are being built), the plugin API changes too.

**Consequences:** This is the primary ecosystem-killing mistake for open source frameworks. FilamentPHP had multiple major breaking changes between v1→v2→v3 that forced plugin authors to rewrite. The Ash framework had similar growing pains.

**Prevention:**
- Define explicit stability tiers: `@unstable` (no guarantees), `@experimental` (may change with notice), `@stable` (semver-protected).
- Mark the plugin API as `@experimental` in v0.1.0 explicitly in documentation. Users know what they are signing up for.
- Use a single entry-point behaviour for plugins with `@optional_callbacks` for optional hooks so adding new hooks is non-breaking.
- Never remove or rename a callback without a deprecation period of at least one minor version.
- Document the plugin API with `@since` version tags so authors know when things changed.

**Warning signs:**
- Internal "plugins" (forms, tables) need callback signatures that conflict with the current plugin spec.
- You find yourself wanting to add a parameter to a callback that already has usages.
- The `@behaviour` module grows beyond 5-7 required callbacks — split it into composable behaviours.

**Phase to address:** Phase 1 (plugin architecture foundation). Must be established before building any features as plugins.

---

### Pitfall 5: Authorization Checks Only at Mount

**What goes wrong:** The LiveView `mount/3` callback performs the authorization check (is this user an admin?). But every `handle_event` and `handle_info` callback can be invoked by a connected client without going through `mount` again. A savvy user connects to the admin panel legitimately, then sends crafted WebSocket events to delete arbitrary records.

**Why it happens:** The HTTP mental model — check auth at the gate, then you are in — does not map to LiveView's persistent connection model. Mount is the gate, but the WebSocket is open indefinitely after mount.

**Consequences:** Admin panel with security vulnerabilities in the framework itself. Every app using PhoenixFilament is potentially vulnerable. This is a critical security issue for a framework targeting admin panels which control sensitive data.

**Prevention:**
- Build authorization as a first-class concern in the resource abstraction layer, not an afterthought.
- Every generated `handle_event` must call an authorization check before performing the action: `authorize!(socket, :delete, record)`.
- Provide an explicit `can?/3` or `authorize/3` callback that resource modules must implement (or use a default policy).
- Document the [LiveView security model](https://hexdocs.pm/phoenix_live_view/security-model.html) prominently. Users must understand that LiveView auth is not just a router-level concern.
- Implement `live_socket_id` and broadcast-based session revocation so admin access can be revoked in real time.

**Warning signs:**
- Resource `handle_event` callbacks do not check the current user before performing writes.
- Removing a user from the admin role does not disconnect their active LiveView session.
- Authorization logic lives only in `on_mount` hooks on the router.

**Phase to address:** Phase 2 (Resource abstraction). Authorization must be baked into the resource lifecycle, not bolted on later.

---

## Moderate Pitfalls

---

### Pitfall 6: Storing Large Ecto Structs in Socket Assigns

**What goes wrong:** Resource list pages load all records from the database and store the full Ecto struct list in socket assigns. With 10,000 records and 500 concurrent admin users, server memory explodes. Diff calculations transmit entire records to the browser on any change.

**Why it happens:** The obvious implementation of a table is `assigns.records`. Developers pull the records in `mount`, store them, and render. This works in development with 50 records and disappears as a problem until staging load tests.

**Consequences:** Memory usage grows O(records × users). Server crashes under moderate load. Real-time updates are slow because diffs include full record data.

**Prevention:**
- Use LiveView streams (`stream/3`, `stream_insert/3`) for all list views by default — not optional, not a configuration flag.
- Paginate at the database level; never load more than one page of data into memory.
- Store only IDs or minimal display fields in assigns; fetch full records only on demand (e.g., for edit forms).
- Use `temporary_assigns: [form_errors: []]` for transient data like validation error lists.

**Warning signs:**
- Table components receive full schema structs rather than minimal display projections.
- No mention of `stream/3` in the table component implementation.
- Memory profiler shows socket assigns as the largest memory consumer.

**Phase to address:** Phase 2 (Table builder). Default to streams in the first implementation.

---

### Pitfall 7: N+1 Queries in Table and Form Rendering

**What goes wrong:** A table component renders rows that include association data (e.g., `post.author.name`). Each row triggers a separate database query to load the author. With 25 rows per page, that is 26 queries per page load.

**Why it happens:** The DSL hides the query from the user. The user declares `column :author_name, value: fn row -> row.author.name end` and the framework calls that function during render. Nothing in the DSL surface warns that `row.author` might not be preloaded.

**Consequences:** Admin panel feels slow. Database is hammered. Monitoring shows bursts of hundreds of queries per page load.

**Prevention:**
- Provide a `preload:` option on column definitions: `column :author_name, preload: :author`.
- Aggregate all `preload:` declarations from active columns and apply them in the data-loading query.
- Log a warning (or raise in dev) when an association is accessed on a record that was not preloaded.
- Document the preloading system prominently in the first table builder documentation.

**Warning signs:**
- Table column definitions that access associations have no `preload:` mechanism.
- `Ecto.Association.NotLoaded` errors appear in development.
- Database query count scales with row count rather than being constant per page.

**Phase to address:** Phase 2 (Table builder). The preload aggregation must be in the initial query layer.

---

### Pitfall 8: LiveView Rendering Inefficiency from Improper Component Boundaries

**What goes wrong:** A single large render function handles the entire admin page. When search input changes (a single field), LiveView re-evaluates and diffs the entire page's template. With complex form layouts, this creates perceptible UI lag even for simple interactions.

**Why it happens:** Building the "quick demo" version of a form or table as a single render function is fast to write. Splitting into properly scoped function components with explicit assign signatures is more work and the performance difference is invisible in development with simple data.

**Consequences:** Admin panels with large forms or complex tables feel sluggish in production. Live validation (typing in a search field) triggers full page re-renders.

**Prevention:**
- Each form field component must be a function component with explicit, typed assigns — never pass the entire form assigns map.
- Use explicit attribute syntax: `<.text_input value={@field.value} error={@field.error} />` not `<.text_input {assigns} />` or `<.text_input field={@field} />` where `@field` contains everything.
- Table rows that need per-row event handling should be live components with `:id` set to the record ID so LiveView's change tracking can skip unchanged rows.
- Benchmark with `phx-debug` enabled on a table with 50 rows and a column sort event — every row should not re-render.

**Warning signs:**
- Component `attr` declarations use `map` types accepting the full assigns.
- Spread syntax `{assigns}` or `{%{...}}` appears in component calls.
- `phx-debug` overlay shows full-page re-renders on isolated field changes.

**Phase to address:** Phase 1 (Component library) and Phase 2 (Table/Form builders). Change-tracking discipline must be established at the component level before building complex structures.

---

### Pitfall 9: Tailwind CSS Dynamic Class Purging

**What goes wrong:** Status badges, color-coded columns, or theme-switched components use dynamic Tailwind class names assembled at runtime (e.g., `"bg-#{status_color}-500"`). In production, Tailwind's content scanner never saw these strings as static classes and purges them. Components render without styles.

**Why it happens:** Framework code generates class strings programmatically. The Tailwind scanner is a static analysis tool — it finds classes in source code text. It cannot follow runtime string interpolation.

**Consequences:** Production deployments have broken styling. The bug is invisible in development when the full Tailwind stylesheet is loaded.

**Prevention:**
- Never use string interpolation for Tailwind class names in framework code.
- Use complete class strings and switch between them: `if green, do: "bg-green-500", else: "bg-red-500"`.
- For any color variant the framework might use, add them to the Tailwind `safelist` in the installer-generated configuration.
- Document this restriction for plugin authors. Plugins that use dynamic classes must also follow this rule or safelist their classes.

**Warning signs:**
- Any `"#{variable}"` string interpolation inside a class attribute in framework templates.
- Components that look correct in development but have missing styles in production.
- Plugin documentation that shows dynamic class construction.

**Phase to address:** Phase 1 (Component library). Establish the no-interpolation rule from the first component written.

---

### Pitfall 10: Blocking the LiveView Process with Database Queries

**What goes wrong:** A table with a complex filter triggers a slow database query (2 seconds). The LiveView process handling that user is blocked for 2 seconds. No events from that user can be processed. If the query happens in `handle_event`, the entire UI freezes.

**Why it happens:** The natural implementation calls the database directly in `handle_event` or `mount`. Elixir's synchronous call model makes this feel fine — it just takes a moment. The problem is that the LiveView process cannot handle any other message while waiting.

**Consequences:** UI appears frozen during data loads. Users click multiple times (queuing more slow requests). Timeouts. Poor perceived performance.

**Prevention:**
- For potentially slow operations (filter application, large exports), use `Task.async` and send results back via `send(self(), {:query_result, result})`.
- Show a loading state immediately in the UI; update on `handle_info({:query_result, result}, socket)`.
- Keep `handle_event` fast: validate params, start async work, update loading state, return immediately.
- Framework documentation should show the async pattern as the default approach for data loading, not an advanced optimization.

**Warning signs:**
- `handle_event` callbacks contain `Repo.all()` or `Repo.one()` calls directly.
- No loading/skeleton states in table or form components.
- No `handle_info` callbacks in the resource LiveView for async operation results.

**Phase to address:** Phase 2 (Resource abstraction, Table builder). Design the resource data-loading lifecycle with async as the default.

---

### Pitfall 11: HTML Form Encoding Cannot Represent Empty Association Lists

**What goes wrong:** A form with a `has_many` relationship (e.g., post tags) allows the user to add and remove tags. When the user removes all tags, the form submission contains no keys for that field — it is simply absent from params. `cast_assoc` sees no tags key and treats the existing tags as unchanged, leaving them in the database.

**Why it happens:** This is a fundamental limitation of HTML's `application/x-www-form-urlencoded` encoding: an empty list cannot be represented. There is no `tags=[]` in the HTTP request.

**Consequences:** Users cannot clear all related records through the admin form. Deleting the last item in a has-many relationship is silently ignored.

**Prevention:**
- Include a hidden input that always submits an empty sentinel value for the association, so `cast_assoc` sees the key even when the list is empty.
- Use `inputs_for` with `Ecto.Changeset.cast_assoc/3` and the `sort_param` / `drop_param` options (added in Ecto 3.10) which use explicit sort and drop keys rather than relying on list encoding.
- Write integration tests that specifically test "remove all items from a has-many field."

**Warning signs:**
- Nested form components with no hidden sentinel inputs for the association.
- Tests do not cover the "delete all items" case.
- Users report that removing the last tag/item does not save.

**Phase to address:** Phase 2 (Form builder with nested form support).

---

### Pitfall 12: Installer Generator That Requires Invasive Manual Changes

**What goes wrong:** `mix phx_filament.install` generates instructions like "add this line to your router," "modify this in your config," "update your assets/app.js." Users follow 12 steps, miss one, and spend hours debugging. Each Phoenix version update breaks the manual integration instructions.

**Why it happens:** Admin frameworks require integration at multiple touch points: router, layout, assets, config, authentication middleware. A generator that only creates new files cannot handle modifications to existing files cleanly.

**Consequences:** High installation friction. The first experience of the framework is frustrating. Backpex, which has similar integration requirements, is specifically called out for having an install process "rife with gotchas."

**Prevention:**
- Use `Mix.Generator` and `Igniter` (the Elixir installer library) to perform code injection into existing files automatically, not just file generation.
- If `Igniter` is not used, generate complete diff examples for each file that needs modification — not prose instructions.
- Provide a `--dry-run` flag that shows what will change before making changes.
- Keep the install footprint minimal: if the user must modify 5 files manually, the installer is not doing its job.
- Write integration tests that run against a fresh `mix phx.new` app to verify the installer produces a working setup.

**Warning signs:**
- The install guide has more than 5 manual steps.
- The README's "Getting Started" section contains code snippets labeled "add this to your router."
- No test that runs `mix phx_filament.install` on a blank Phoenix app and verifies the result compiles and renders.

**Phase to address:** Final phase (Distribution/Installer). Design the installer API contract early so integration points are minimal and automatable.

---

## Minor Pitfalls

---

### Pitfall 13: Overly Broad `use` Macro Injecting Hidden Imports

**What goes wrong:** `use PhoenixFilament.Resource` imports helper functions, aliases modules, and `import`s macros broadly into the user's module. A function name in PhoenixFilament's DSL helpers collides with a function the user defined. The conflict produces a confusing compile warning or silent override.

**Prevention:** Prefer explicit `import PhoenixFilament.DSL.Helpers, only: [form: 1, table: 1]` over injecting everything via `use`. Document exactly what `use PhoenixFilament.Resource` injects. Namespace all injected functions with a distinctive prefix if they must be injected.

**Warning signs:** Users report compile warnings about "redefining" or "conflicting" function names after adding framework `use`.

**Phase to address:** Phase 1 (DSL design).

---

### Pitfall 14: Alpine.js State Loss on LiveView DOM Patches

**What goes wrong:** Dropdown menus, date pickers, and other client-side interactive components built with Alpine.js lose their state (e.g., open/closed) when LiveView patches the DOM in response to server events.

**Prevention:**
- Wrap Alpine.js-managed DOM subtrees with `phx-update="ignore"` so LiveView skips patching those elements.
- Use LiveView JS commands (`JS.toggle`, `JS.add_class`) for simple show/hide interactions instead of Alpine to eliminate the dependency entirely.
- When Alpine is necessary (complex date pickers, drag-and-drop), use the `mounted` and `updated` LiveView hook lifecycle to reinitialize Alpine via `Alpine.initTree(el)`.

**Warning signs:** Dropdown menus close unexpectedly after server events. Component demos work in isolation but break in the full admin layout.

**Phase to address:** Phase 1 (Component library).

---

### Pitfall 15: Inherited LiveView Latency Misrepresented as Framework Overhead

**What goes wrong:** LiveView requires a round-trip to the server for every interaction. In high-latency environments (>100ms RTT), forms feel slow. Users blame the admin framework rather than understanding this is a LiveView property.

**Prevention:**
- Use `phx-debounce` on all text inputs in the framework's form components by default — never leave debounce as opt-in.
- Show optimistic UI updates for well-defined operations (toggle, delete, status change) that update the DOM before the server confirms.
- Document expected latency characteristics clearly so operators with high-latency deployments can configure debounce values.

**Warning signs:** Form inputs send server events on every keystroke with no debounce configured in the framework defaults.

**Phase to address:** Phase 1 (Component library).

---

### Pitfall 16: Plugin Dependency on Framework Internals Rather Than Public API

**What goes wrong:** A plugin that ships with v0.1.0 calls internal framework functions (e.g., `PhoenixFilament.Resource.Internal.build_query/2`). In v0.2.0, that function is refactored. The plugin silently breaks at runtime.

**Prevention:**
- Establish a clear public/private module boundary from the start: all public API lives in `PhoenixFilament.*`, all internal implementation lives in `PhoenixFilament.Internal.*` or uses `@moduledoc false`.
- Use `@doc false` to hide internal functions from documentation.
- Write a "plugin development guide" that only references documented public functions.
- Consider providing a `PhoenixFilament.TestHelpers` module for plugin authors to use in their own tests.

**Warning signs:** Plugin examples in documentation call modules under `PhoenixFilament.Resource.*` rather than `PhoenixFilament.*`.

**Phase to address:** Phase 1 (Plugin architecture).

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| DSL foundation (macros) | Compile-time dependency cascades | Use `Macro.expand_literals/2`; test compile times with 50+ resources early |
| DSL foundation (macros) | Excessive code generation | Extract logic to functions; use thin delegation pattern |
| Plugin architecture | Plugin API instability | Mark API as `@experimental`; use `@optional_callbacks` for extensibility |
| Component library | Tailwind class purging | Never interpolate Tailwind classes; safelist dynamic variants |
| Component library | Component render inefficiency | Explicit assign attrs; never spread `assigns` map; benchmark with phx-debug |
| Table builder | N+1 queries from associations | Aggregate `preload:` declarations at the column definition level |
| Table builder | Memory explosion from assigns | Use LiveView streams by default for all list views |
| Form builder | Empty has-many encoding | Use Ecto `drop_param`/`sort_param` or hidden sentinel inputs |
| Form builder | Blocking the LiveView process | Async data loading with `Task.async` + `handle_info` pattern |
| Resource abstraction | Authorization only at mount | Auth in every `handle_event`; provide `authorize!/3` callback |
| Admin panel shell | Session revocation for LiveView | `live_socket_id` + broadcast disconnect on logout |
| Installer/distribution | Complex manual installation steps | Use Igniter for code injection; verify with blank-app integration test |

---

## Sources

- [Meta-programming anti-patterns — Elixir v1.19.5](https://hexdocs.pm/elixir/macro-anti-patterns.html) — HIGH confidence (official docs)
- [Security considerations — Phoenix LiveView v1.1.25](https://hexdocs.pm/phoenix_live_view/security-model.html) — HIGH confidence (official docs)
- [Library guidelines — Elixir v1.19.5](https://hexdocs.pm/elixir/library-guidelines.html) — HIGH confidence (official docs)
- [LiveView rendering pitfalls and how to avoid them — DockYard](https://dockyard.com/blog/2022/08/18/liveview-rendering-pitfalls-and-how-to-avoid-them) — MEDIUM confidence (community, verified against official docs)
- [LiveView Assigns: Three Common Pitfalls — AppSignal Blog](https://blog.appsignal.com/2022/06/28/liveview-assigns-three-common-pitfalls-and-their-solutions.html) — MEDIUM confidence (community)
- [The Ten Biggest Mistakes Made With Phoenix LiveView — Hex Shift](https://hexshift.medium.com/the-ten-biggest-mistakes-made-with-phoenix-liveview-and-how-to-fix-them-cbe2afda4c36) — MEDIUM confidence (community compilation, patterns verified)
- [Ash Framework: Lessons from its DSL — Joe Koski](https://www.joekoski.com/blog/2025/12/01/ash_dsl_1.html) — MEDIUM confidence (practitioner experience)
- [Building Beautiful Admin Dashboards with Backpex — James Carr](https://james-carr.org/posts/2024-08-27-phoenix-admin-with-backpex/) — MEDIUM confidence (practitioner experience)
- [How Filament Saved (or Complicated) My Admin Panel — DEV Community](https://dev.to/tonegabes/how-filament-saved-or-complicated-my-admin-panel-an-honest-review-156b) — LOW-MEDIUM confidence (individual review, cross-ecosystem comparison)
- [Plugins in Elixir Applications](https://rocket-science.ru/hacking/2022/02/12/plugins-in-elixir-apps) — MEDIUM confidence (community pattern analysis)
- [How to speed up Elixir compile times — Multiverse Tech](https://medium.com/multiverse-tech/how-to-speed-up-your-elixir-compile-times-part-1-understanding-elixir-compilation-64d44a32ec6e) — MEDIUM confidence (community, consistent with official docs)
- [Understanding Tailwind CSS Safelist — Perficient](https://blogs.perficient.com/2025/08/19/understanding-tailwind-css-safelist-keep-your-dynamic-classes-safe/) — HIGH confidence (well-documented Tailwind behavior)

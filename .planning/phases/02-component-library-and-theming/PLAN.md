# Phase 2: Component Library and Theming — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build all LiveView UI primitives (inputs, button, badge, card, modal) as stateless Phoenix.Component function components styled with daisyUI 5, plus a theming system with CSS variables and a Field dispatcher bridging Phase 1 structs to components.

**Architecture:** Bottom-Up — standalone components first (accepting `Phoenix.HTML.FormField`), then a thin `FieldRenderer` dispatcher that maps `%Field{}` structs to the appropriate component. Components know nothing about PhoenixFilament data structures. Theming uses daisyUI semantic classes and CSS variables with `data-theme`.

**Tech Stack:** Elixir 1.19+, Phoenix.Component (LiveView 1.1), Phoenix.HTML.FormField, daisyUI 5 semantic classes, Tailwind v4 CSS variables

---

## File Structure

### Source Files (create all)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/components/input.ex` | All 9 input function components: text_input, textarea, number_input, select, checkbox, toggle, date, datetime, hidden |
| `lib/phoenix_filament/components/button.ex` | Button with variant, size, loading, disabled |
| `lib/phoenix_filament/components/badge.ex` | Badge with color variants |
| `lib/phoenix_filament/components/card.ex` | Card with hybrid slots (title attr + named slots) |
| `lib/phoenix_filament/components/modal.ex` | Modal with LiveView portal, show/on_cancel |
| `lib/phoenix_filament/components/theme.ex` | css_vars/1, theme_attr/1, theme_switcher/1 |
| `lib/phoenix_filament/components/field_renderer.ex` | render_field/1 dispatching %Field{} → component |
| `lib/phoenix_filament/components.ex` | `use PhoenixFilament.Components` imports all component modules |

### Test Files (create all)

| File | Responsibility |
|------|---------------|
| `test/phoenix_filament/components/input_test.exs` | All 9 input components |
| `test/phoenix_filament/components/button_test.exs` | Button variants, sizes, states |
| `test/phoenix_filament/components/badge_test.exs` | Badge color variants |
| `test/phoenix_filament/components/card_test.exs` | Card hybrid slots |
| `test/phoenix_filament/components/modal_test.exs` | Modal show/hide, portal |
| `test/phoenix_filament/components/theme_test.exs` | Theme helpers |
| `test/phoenix_filament/components/field_renderer_test.exs` | %Field{} → component dispatch |

---

## Task 1: Test Helper for Component Rendering

**Files:**
- Modify: `test/test_helper.exs`
- Create: `test/support/component_case.ex`

- [ ] **Step 1: Create ComponentCase test helper**

```elixir
# test/support/component_case.ex
defmodule PhoenixFilament.ComponentCase do
  @moduledoc """
  Test case for rendering Phoenix function components.

  Provides `render_component/2` and `make_form/2` helpers.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.Component, only: [to_form: 2]
      import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

      @doc "Creates a Phoenix.HTML.Form from a params map for testing."
      def make_form(params, opts \\ []) do
        as = Keyword.get(opts, :as, :test)
        to_form(params, as: as)
      end
    end
  end
end
```

- [ ] **Step 2: Update test_helper.exs to include cascade exclude**

Verify `test/test_helper.exs` has:

```elixir
ExUnit.start(exclude: [:cascade])
```

If not already present, update it.

- [ ] **Step 3: Verify helper compiles**

Run: `mix compile`
Expected: Clean compilation, no warnings

- [ ] **Step 4: Commit**

```bash
git add test/support/component_case.ex test/test_helper.exs
git commit -m "test: add ComponentCase helper for component rendering tests"
```

---

## Task 2: Input Components — text_input, textarea, number_input

**Files:**
- Create: `lib/phoenix_filament/components/input.ex`
- Create: `test/phoenix_filament/components/input_test.exs`

- [ ] **Step 1: Write failing tests for text_input, textarea, number_input**

```elixir
# test/phoenix_filament/components/input_test.exs
defmodule PhoenixFilament.Components.InputTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.Component, only: [to_form: 2]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.Input

  defp form_field(params \\ %{}, field_name, opts \\ []) do
    as = Keyword.get(opts, :as, :post)
    form = to_form(params, as: to_string(as))
    form[field_name]
  end

  describe "text_input/1" do
    test "renders input with correct type and daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{"title" => "Hello"}, :title)} />
        """)

      assert html =~ ~s(type="text")
      assert html =~ ~s(class="input input-bordered)
      assert html =~ ~s(value="Hello")
    end

    test "renders label when provided" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} label="Title" />
        """)

      assert html =~ "<label"
      assert html =~ "Title"
    end

    test "omits label when nil" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} />
        """)

      refute html =~ "<label"
    end

    test "renders required asterisk" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} label="Title" required />
        """)

      assert html =~ "*"
    end

    test "renders placeholder" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} placeholder="Enter title" />
        """)

      assert html =~ ~s(placeholder="Enter title")
    end

    test "renders disabled state" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} disabled />
        """)

      assert html =~ "disabled"
    end

    test "merges custom class with defaults" do
      html =
        rendered_to_string(~H"""
        <Input.text_input field={form_field(%{}, :title)} class="mt-4" />
        """)

      assert html =~ "input input-bordered"
      assert html =~ "mt-4"
    end

    test "renders errors with role alert" do
      field = %Phoenix.HTML.FormField{
        id: "post_title",
        name: "post[title]",
        value: "",
        errors: ["can't be blank"],
        field: :title,
        form: %Phoenix.HTML.Form{source: %{}, impl: Phoenix.HTML.FormData.Map, id: "post", name: "post", data: %{}, action: nil, hidden: [], params: %{}, errors: [], options: [], index: nil}
      }

      html =
        rendered_to_string(~H"""
        <Input.text_input field={field} label="Title" />
        """)

      assert html =~ "can&#39;t be blank"
      assert html =~ ~s(role="alert")
      assert html =~ "input-error"
    end
  end

  describe "textarea/1" do
    test "renders textarea with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.textarea field={form_field(%{"body" => "Content"}, :body)} />
        """)

      assert html =~ "<textarea"
      assert html =~ "textarea textarea-bordered"
      assert html =~ "Content"
    end

    test "renders with custom rows" do
      html =
        rendered_to_string(~H"""
        <Input.textarea field={form_field(%{}, :body)} rows={5} />
        """)

      assert html =~ ~s(rows="5")
    end
  end

  describe "number_input/1" do
    test "renders number input with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.number_input field={form_field(%{"views" => "42"}, :views)} />
        """)

      assert html =~ ~s(type="number")
      assert html =~ "input input-bordered"
    end

    test "renders with min, max, step" do
      html =
        rendered_to_string(~H"""
        <Input.number_input field={form_field(%{}, :views)} min={0} max={100} step={1} />
        """)

      assert html =~ ~s(min="0")
      assert html =~ ~s(max="100")
      assert html =~ ~s(step="1")
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: Compilation error — `PhoenixFilament.Components.Input` module not found

- [ ] **Step 3: Implement input.ex with text_input, textarea, number_input**

```elixir
# lib/phoenix_filament/components/input.ex
defmodule PhoenixFilament.Components.Input do
  @moduledoc """
  Form input components styled with daisyUI 5.

  Each component accepts a `Phoenix.HTML.FormField` and renders the
  appropriate HTML input with label, error display, and accessibility
  attributes built in.
  """

  use Phoenix.Component

  # --- text_input/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def text_input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="text"
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value("text", @field.value)}
        placeholder={@placeholder}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- textarea/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :rows, :integer, default: 3
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def textarea(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <textarea
        id={@field.id}
        name={@field.name}
        placeholder={@placeholder}
        rows={@rows}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["textarea textarea-bordered w-full", @field.errors != [] && "textarea-error", @class]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- number_input/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :min, :integer, default: nil
  attr :max, :integer, default: nil
  attr :step, :integer, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def number_input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="number"
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value("number", @field.value)}
        placeholder={@placeholder}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- shared error rendering ---

  defp field_errors(assigns) do
    ~H"""
    <p
      :for={error <- @field.errors}
      id={"#{@field.id}-error"}
      role="alert"
      class="text-error text-sm mt-1"
    >
      {error}
    </p>
    """
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/input.ex test/phoenix_filament/components/input_test.exs test/support/component_case.ex
git commit -m "feat(components): add text_input, textarea, number_input with daisyUI styling"
```

---

## Task 3: Input Components — select, checkbox, toggle

**Files:**
- Modify: `lib/phoenix_filament/components/input.ex`
- Modify: `test/phoenix_filament/components/input_test.exs`

- [ ] **Step 1: Write failing tests for select, checkbox, toggle**

Append to `test/phoenix_filament/components/input_test.exs`:

```elixir
  describe "select/1" do
    test "renders select with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "draft"}, :status)}
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        />
        """)

      assert html =~ "<select"
      assert html =~ "select select-bordered"
      assert html =~ "<option"
      assert html =~ "Draft"
    end

    test "renders prompt option" do
      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{}, :status)}
          options={[{"Draft", "draft"}]}
          prompt="Choose status"
        />
        """)

      assert html =~ "Choose status"
    end

    test "renders string options" do
      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "draft"}, :status)}
          options={["draft", "published", "archived"]}
        />
        """)

      assert html =~ "draft"
      assert html =~ "published"
    end

    test "marks selected option" do
      html =
        rendered_to_string(~H"""
        <Input.select
          field={form_field(%{"status" => "published"}, :status)}
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        />
        """)

      assert html =~ ~s(selected)
    end
  end

  describe "checkbox/1" do
    test "renders checkbox with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.checkbox field={form_field(%{"published" => "true"}, :published)} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "checkbox"
    end

    test "renders label" do
      html =
        rendered_to_string(~H"""
        <Input.checkbox field={form_field(%{}, :published)} label="Published" />
        """)

      assert html =~ "Published"
    end
  end

  describe "toggle/1" do
    test "renders toggle with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.toggle field={form_field(%{"active" => "true"}, :active)} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "toggle"
    end

    test "renders label" do
      html =
        rendered_to_string(~H"""
        <Input.toggle field={form_field(%{}, :active)} label="Active" />
        """)

      assert html =~ "Active"
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: Failures for select, checkbox, toggle

- [ ] **Step 3: Implement select, checkbox, toggle in input.ex**

Append to `lib/phoenix_filament/components/input.ex` (before the closing `end`):

```elixir
  # --- select/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :options, :list, required: true
  attr :prompt, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def select(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <select
        id={@field.id}
        name={@field.name}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["select select-bordered w-full", @field.errors != [] && "select-error", @class]}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @field.value)}
      </select>
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- checkbox/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label cursor-pointer gap-2">
        <input type="hidden" name={@field.name} value="false" />
        <input
          type="checkbox"
          id={@field.id}
          name={@field.name}
          value="true"
          checked={Phoenix.HTML.Form.normalize_value("checkbox", @field.value)}
          class={["checkbox", @class]}
          {@rest}
        />
        <span :if={@label} class="label-text">{@label}</span>
      </label>
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- toggle/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def toggle(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label cursor-pointer gap-2">
        <input type="hidden" name={@field.name} value="false" />
        <input
          type="checkbox"
          id={@field.id}
          name={@field.name}
          value="true"
          checked={Phoenix.HTML.Form.normalize_value("checkbox", @field.value)}
          class={["toggle", @class]}
          {@rest}
        />
        <span :if={@label} class="label-text">{@label}</span>
      </label>
      <.field_errors field={@field} />
    </div>
    """
  end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/input.ex test/phoenix_filament/components/input_test.exs
git commit -m "feat(components): add select, checkbox, toggle inputs"
```

---

## Task 4: Input Components — date, datetime, hidden

**Files:**
- Modify: `lib/phoenix_filament/components/input.ex`
- Modify: `test/phoenix_filament/components/input_test.exs`

- [ ] **Step 1: Write failing tests for date, datetime, hidden**

Append to `test/phoenix_filament/components/input_test.exs`:

```elixir
  describe "date/1" do
    test "renders native date input with daisyUI classes" do
      html =
        rendered_to_string(~H"""
        <Input.date field={form_field(%{"published_at" => "2026-04-01"}, :published_at)} />
        """)

      assert html =~ ~s(type="date")
      assert html =~ "input input-bordered"
      assert html =~ ~s(value="2026-04-01")
    end

    test "renders with min and max" do
      html =
        rendered_to_string(~H"""
        <Input.date field={form_field(%{}, :published_at)} min="2026-01-01" max="2026-12-31" />
        """)

      assert html =~ ~s(min="2026-01-01")
      assert html =~ ~s(max="2026-12-31")
    end
  end

  describe "datetime/1" do
    test "renders native datetime-local input" do
      html =
        rendered_to_string(~H"""
        <Input.datetime field={form_field(%{"starts_at" => "2026-04-01T10:30"}, :starts_at)} />
        """)

      assert html =~ ~s(type="datetime-local")
      assert html =~ "input input-bordered"
    end
  end

  describe "hidden/1" do
    test "renders hidden input with no wrapper" do
      html =
        rendered_to_string(~H"""
        <Input.hidden field={form_field(%{"id" => "42"}, :id)} />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="42")
      refute html =~ "<label"
      refute html =~ "input-bordered"
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: Failures for date, datetime, hidden

- [ ] **Step 3: Implement date, datetime, hidden in input.ex**

Append to `lib/phoenix_filament/components/input.ex`:

```elixir
  # --- date/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :min, :string, default: nil
  attr :max, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def date(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="date"
        id={@field.id}
        name={@field.name}
        value={@field.value}
        min={@min}
        max={@max}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- datetime/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :min, :string, default: nil
  attr :max, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def datetime(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@field.id} class="label">
        <span>{@label}</span>
        <span :if={@required} class="text-error">*</span>
      </label>
      <input
        type="datetime-local"
        id={@field.id}
        name={@field.name}
        value={@field.value}
        min={@min}
        max={@max}
        disabled={@disabled}
        aria-describedby={@field.errors != [] && "#{@field.id}-error"}
        class={["input input-bordered w-full", @field.errors != [] && "input-error", @class]}
        {@rest}
      />
      <.field_errors field={@field} />
    </div>
    """
  end

  # --- hidden/1 ---

  attr :field, Phoenix.HTML.FormField, required: true
  attr :rest, :global

  def hidden(assigns) do
    ~H"""
    <input
      type="hidden"
      id={@field.id}
      name={@field.name}
      value={@field.value}
      {@rest}
    />
    """
  end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/input_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/input.ex test/phoenix_filament/components/input_test.exs
git commit -m "feat(components): add date, datetime, hidden inputs"
```

---

## Task 5: Button Component

**Files:**
- Create: `lib/phoenix_filament/components/button.ex`
- Create: `test/phoenix_filament/components/button_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/button_test.exs
defmodule PhoenixFilament.Components.ButtonTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.Button

  describe "button/1" do
    test "renders primary button by default" do
      html = rendered_to_string(~H"""
      <Button.button>Save</Button.button>
      """)

      assert html =~ "<button"
      assert html =~ "btn btn-primary"
      assert html =~ "Save"
    end

    test "renders danger variant" do
      html = rendered_to_string(~H"""
      <Button.button variant={:danger}>Delete</Button.button>
      """)

      assert html =~ "btn btn-error"
    end

    test "renders secondary variant" do
      html = rendered_to_string(~H"""
      <Button.button variant={:secondary}>Cancel</Button.button>
      """)

      assert html =~ "btn btn-secondary"
    end

    test "renders ghost variant" do
      html = rendered_to_string(~H"""
      <Button.button variant={:ghost}>Skip</Button.button>
      """)

      assert html =~ "btn btn-ghost"
    end

    test "renders size sm" do
      html = rendered_to_string(~H"""
      <Button.button size={:sm}>Small</Button.button>
      """)

      assert html =~ "btn-sm"
    end

    test "renders size lg" do
      html = rendered_to_string(~H"""
      <Button.button size={:lg}>Large</Button.button>
      """)

      assert html =~ "btn-lg"
    end

    test "renders loading state with spinner" do
      html = rendered_to_string(~H"""
      <Button.button loading>Saving...</Button.button>
      """)

      assert html =~ "loading"
      assert html =~ "disabled"
    end

    test "renders disabled state" do
      html = rendered_to_string(~H"""
      <Button.button disabled>Disabled</Button.button>
      """)

      assert html =~ "disabled"
    end

    test "defaults to type button" do
      html = rendered_to_string(~H"""
      <Button.button>Click</Button.button>
      """)

      assert html =~ ~s(type="button")
    end

    test "accepts type submit" do
      html = rendered_to_string(~H"""
      <Button.button type="submit">Submit</Button.button>
      """)

      assert html =~ ~s(type="submit")
    end

    test "merges custom class" do
      html = rendered_to_string(~H"""
      <Button.button class="w-full">Full Width</Button.button>
      """)

      assert html =~ "btn btn-primary"
      assert html =~ "w-full"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/button_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement button.ex**

```elixir
# lib/phoenix_filament/components/button.ex
defmodule PhoenixFilament.Components.Button do
  @moduledoc """
  Button component with variant, size, loading, and disabled support.
  Styled with daisyUI 5 semantic classes.
  """

  use Phoenix.Component

  @variant_classes %{
    primary: "btn-primary",
    secondary: "btn-secondary",
    danger: "btn-error",
    ghost: "btn-ghost"
  }

  @size_classes %{
    sm: "btn-sm",
    md: nil,
    lg: "btn-lg"
  }

  attr :variant, :atom, default: :primary, values: [:primary, :secondary, :danger, :ghost]
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :loading, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :type, :string, default: "button"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled || @loading}
      class={[
        "btn",
        Map.get(@variant_classes, @variant),
        Map.get(@size_classes, @size),
        @loading && "loading loading-spinner",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp variant_classes, do: @variant_classes
  defp size_classes, do: @size_classes
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/button_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/button.ex test/phoenix_filament/components/button_test.exs
git commit -m "feat(components): add button with variants, sizes, loading state"
```

---

## Task 6: Badge Component

**Files:**
- Create: `lib/phoenix_filament/components/badge.ex`
- Create: `test/phoenix_filament/components/badge_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/badge_test.exs
defmodule PhoenixFilament.Components.BadgeTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.Badge

  describe "badge/1" do
    test "renders neutral badge by default" do
      html = rendered_to_string(~H"""
      <Badge.badge>Status</Badge.badge>
      """)

      assert html =~ "badge"
      assert html =~ "Status"
    end

    test "renders success color" do
      html = rendered_to_string(~H"""
      <Badge.badge color={:success}>Active</Badge.badge>
      """)

      assert html =~ "badge-success"
    end

    test "renders warning color" do
      html = rendered_to_string(~H"""
      <Badge.badge color={:warning}>Pending</Badge.badge>
      """)

      assert html =~ "badge-warning"
    end

    test "renders error color" do
      html = rendered_to_string(~H"""
      <Badge.badge color={:error}>Failed</Badge.badge>
      """)

      assert html =~ "badge-error"
    end

    test "renders info color" do
      html = rendered_to_string(~H"""
      <Badge.badge color={:info}>Note</Badge.badge>
      """)

      assert html =~ "badge-info"
    end

    test "renders size sm" do
      html = rendered_to_string(~H"""
      <Badge.badge size={:sm}>Small</Badge.badge>
      """)

      assert html =~ "badge-sm"
    end

    test "merges custom class" do
      html = rendered_to_string(~H"""
      <Badge.badge class="gap-2">Custom</Badge.badge>
      """)

      assert html =~ "badge"
      assert html =~ "gap-2"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/badge_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement badge.ex**

```elixir
# lib/phoenix_filament/components/badge.ex
defmodule PhoenixFilament.Components.Badge do
  @moduledoc """
  Badge component with color variants. Styled with daisyUI 5.
  """

  use Phoenix.Component

  @color_classes %{
    neutral: nil,
    primary: "badge-primary",
    success: "badge-success",
    warning: "badge-warning",
    error: "badge-error",
    info: "badge-info"
  }

  @size_classes %{
    sm: "badge-sm",
    md: nil,
    lg: "badge-lg"
  }

  attr :color, :atom, default: :neutral, values: [:neutral, :primary, :success, :warning, :error, :info]
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["badge", Map.get(@color_classes, @color), Map.get(@size_classes, @size), @class]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp color_classes, do: @color_classes
  defp size_classes, do: @size_classes
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/badge_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/badge.ex test/phoenix_filament/components/badge_test.exs
git commit -m "feat(components): add badge with color variants"
```

---

## Task 7: Card Component

**Files:**
- Create: `lib/phoenix_filament/components/card.ex`
- Create: `test/phoenix_filament/components/card_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/card_test.exs
defmodule PhoenixFilament.Components.CardTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.Card

  describe "card/1" do
    test "renders card with inner content" do
      html = rendered_to_string(~H"""
      <Card.card>
        <p>Content here</p>
      </Card.card>
      """)

      assert html =~ "card"
      assert html =~ "bg-base-100"
      assert html =~ "Content here"
    end

    test "renders with title attr (simple mode)" do
      html = rendered_to_string(~H"""
      <Card.card title="Post Details">
        <p>Content</p>
      </Card.card>
      """)

      assert html =~ "card-title"
      assert html =~ "Post Details"
    end

    test "renders with header slot (complex mode)" do
      html = rendered_to_string(~H"""
      <Card.card>
        <:header>
          <h2>Custom Header</h2>
        </:header>
        <p>Content</p>
      </Card.card>
      """)

      assert html =~ "Custom Header"
    end

    test "renders with footer slot" do
      html = rendered_to_string(~H"""
      <Card.card title="Title">
        <p>Content</p>
        <:footer>
          <button>Save</button>
        </:footer>
      </Card.card>
      """)

      assert html =~ "Save"
    end

    test "merges custom class" do
      html = rendered_to_string(~H"""
      <Card.card class="compact">
        <p>Content</p>
      </Card.card>
      """)

      assert html =~ "card"
      assert html =~ "compact"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/card_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement card.ex**

```elixir
# lib/phoenix_filament/components/card.ex
defmodule PhoenixFilament.Components.Card do
  @moduledoc """
  Card component with hybrid slot strategy.

  Simple mode: pass `title` attr for a basic card.
  Complex mode: use `:header`, `:footer` named slots for rich layouts.
  """

  use Phoenix.Component

  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  slot :header
  slot :inner_block, required: true
  slot :footer

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-sm", @class]} {@rest}>
      <div class="card-body">
        <div :if={@header != []} class="card-header">
          {render_slot(@header)}
        </div>
        <h3 :if={@title && @header == []} class="card-title">{@title}</h3>
        {render_slot(@inner_block)}
        <div :if={@footer != []} class="card-actions justify-end mt-4">
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/card_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/card.ex test/phoenix_filament/components/card_test.exs
git commit -m "feat(components): add card with hybrid slots"
```

---

## Task 8: Modal Component

**Files:**
- Create: `lib/phoenix_filament/components/modal.ex`
- Create: `test/phoenix_filament/components/modal_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/modal_test.exs
defmodule PhoenixFilament.Components.ModalTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.Modal

  describe "modal/1" do
    test "renders modal when show is true" do
      html = rendered_to_string(~H"""
      <Modal.modal show id="test-modal">
        <p>Modal content</p>
      </Modal.modal>
      """)

      assert html =~ "modal"
      assert html =~ "modal-open"
      assert html =~ "Modal content"
    end

    test "does not render modal-open when show is false" do
      html = rendered_to_string(~H"""
      <Modal.modal show={false} id="hidden-modal">
        <p>Hidden</p>
      </Modal.modal>
      """)

      refute html =~ "modal-open"
    end

    test "renders header slot" do
      html = rendered_to_string(~H"""
      <Modal.modal show id="header-modal">
        <:header>Delete Post?</:header>
        <p>This cannot be undone.</p>
      </Modal.modal>
      """)

      assert html =~ "Delete Post?"
    end

    test "renders actions slot" do
      html = rendered_to_string(~H"""
      <Modal.modal show id="action-modal">
        <p>Confirm?</p>
        <:actions>
          <button>Yes</button>
        </:actions>
      </Modal.modal>
      """)

      assert html =~ "modal-action"
      assert html =~ "Yes"
    end

    test "renders backdrop for close" do
      html = rendered_to_string(~H"""
      <Modal.modal show id="backdrop-modal">
        <p>Content</p>
      </Modal.modal>
      """)

      assert html =~ "modal-backdrop"
    end

    test "merges custom class" do
      html = rendered_to_string(~H"""
      <Modal.modal show id="custom-modal" class="max-w-lg">
        <p>Content</p>
      </Modal.modal>
      """)

      assert html =~ "modal-box"
      assert html =~ "max-w-lg"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/modal_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement modal.ex**

```elixir
# lib/phoenix_filament/components/modal.ex
defmodule PhoenixFilament.Components.Modal do
  @moduledoc """
  Modal dialog component using daisyUI modal classes.

  Uses `show` boolean and `on_cancel` event for control.
  Designed to work with LiveView 1.1 portals when integrated
  into the Panel layout (Phase 6).
  """

  use Phoenix.Component

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  slot :header
  slot :inner_block, required: true
  slot :actions

  def modal(assigns) do
    ~H"""
    <div id={@id} class={["modal", @show && "modal-open"]} {@rest}>
      <div class={["modal-box", @class]}>
        <div :if={@header != []}>
          <h3 class="font-bold text-lg">
            {render_slot(@header)}
          </h3>
        </div>
        <div class="py-4">
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} class="modal-action">
          {render_slot(@actions)}
        </div>
      </div>
      <div class="modal-backdrop" phx-click={@on_cancel}>
        <button>close</button>
      </div>
    </div>
    """
  end
end
```

Note: This renders the modal using CSS classes. When integrated into the Panel layout (Phase 6), the modal will be wrapped with `<.portal>` for proper z-index/overflow handling. Phase 2 does not depend on portal — it delivers the component structure.

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/modal_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/modal.ex test/phoenix_filament/components/modal_test.exs
git commit -m "feat(components): add modal with show/on_cancel and slots"
```

---

## Task 9: Theme Helpers

**Files:**
- Create: `lib/phoenix_filament/components/theme.ex`
- Create: `test/phoenix_filament/components/theme_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/theme_test.exs
defmodule PhoenixFilament.Components.ThemeTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Components.Theme

  describe "css_vars/1" do
    test "converts keyword list to CSS variable string" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)", accent: "oklch(70% 0.2 150)")

      assert result =~ "--p: 55% 0.25 260"
      assert result =~ "--a: 70% 0.2 150"
    end

    test "returns empty string for empty list" do
      assert Theme.css_vars([]) == ""
    end

    test "handles single color" do
      result = Theme.css_vars(primary: "oklch(55% 0.25 260)")

      assert result =~ "--p:"
    end
  end

  describe "theme_attr/1" do
    test "returns theme name as string" do
      assert Theme.theme_attr(:dark) == "dark"
      assert Theme.theme_attr(:corporate) == "corporate"
      assert Theme.theme_attr(:cyberpunk) == "cyberpunk"
    end

    test "handles string input" do
      assert Theme.theme_attr("retro") == "retro"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/theme_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement theme.ex**

```elixir
# lib/phoenix_filament/components/theme.ex
defmodule PhoenixFilament.Components.Theme do
  @moduledoc """
  Theme utilities for daisyUI 5 CSS variable theming.

  Provides helpers to convert PhoenixFilament theme configuration
  into CSS variable strings and data-theme attributes.
  """

  use Phoenix.Component

  @color_var_map %{
    primary: "--p",
    secondary: "--s",
    accent: "--a",
    neutral: "--n",
    base_100: "--b1",
    base_200: "--b2",
    base_300: "--b3",
    info: "--in",
    success: "--su",
    warning: "--wa",
    error: "--er"
  }

  @doc """
  Converts a keyword list of color overrides to a CSS inline style string.

  Values should be oklch() strings. The function extracts the numeric values
  from the oklch() wrapper for use as daisyUI CSS variables.

  ## Examples

      iex> css_vars(primary: "oklch(55% 0.25 260)")
      "--p: 55% 0.25 260;"
  """
  @spec css_vars(keyword()) :: String.t()
  def css_vars([]), do: ""

  def css_vars(colors) when is_list(colors) do
    colors
    |> Enum.map(fn {name, value} ->
      var = Map.get(@color_var_map, name, "--#{name}")
      val = extract_oklch_values(value)
      "#{var}: #{val}"
    end)
    |> Enum.join("; ")
  end

  @doc """
  Returns the data-theme attribute value for a given theme name.
  """
  @spec theme_attr(atom() | String.t()) :: String.t()
  def theme_attr(theme) when is_atom(theme), do: Atom.to_string(theme)
  def theme_attr(theme) when is_binary(theme), do: theme

  # Extracts "55% 0.25 260" from "oklch(55% 0.25 260)"
  defp extract_oklch_values(value) do
    case Regex.run(~r/oklch\((.+)\)/, value) do
      [_, inner] -> inner
      _ -> value
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/theme_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/theme.ex test/phoenix_filament/components/theme_test.exs
git commit -m "feat(components): add theme helpers (css_vars, theme_attr)"
```

---

## Task 10: Field Renderer — Dispatch %Field{} to Components

**Files:**
- Create: `lib/phoenix_filament/components/field_renderer.ex`
- Create: `test/phoenix_filament/components/field_renderer_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/components/field_renderer_test.exs
defmodule PhoenixFilament.Components.FieldRendererTest do
  use PhoenixFilament.ComponentCase, async: true

  import Phoenix.Component, only: [to_form: 2]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias PhoenixFilament.Components.FieldRenderer
  alias PhoenixFilament.Field

  defp make_form(params \\ %{}) do
    to_form(params, as: "post")
  end

  describe "render_field/1" do
    test "dispatches text_input field" do
      field = Field.text_input(:title, required: true)
      form = make_form(%{"title" => "Hello"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="text")
      assert html =~ "Title"
      assert html =~ "Hello"
    end

    test "dispatches textarea field" do
      field = Field.textarea(:body, rows: 5)
      form = make_form(%{"body" => "Content"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ "<textarea"
      assert html =~ "Body"
    end

    test "dispatches number_input field" do
      field = Field.number_input(:views)
      form = make_form(%{"views" => "42"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="number")
    end

    test "dispatches select field" do
      field = Field.select(:status, options: [{"Draft", "draft"}, {"Published", "published"}])
      form = make_form(%{"status" => "draft"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ "<select"
      assert html =~ "Draft"
    end

    test "dispatches checkbox field" do
      field = Field.checkbox(:active)
      form = make_form(%{"active" => "true"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "checkbox"
    end

    test "dispatches toggle field" do
      field = Field.toggle(:published)
      form = make_form(%{"published" => "false"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "toggle"
    end

    test "dispatches date field" do
      field = Field.date(:published_at)
      form = make_form(%{"published_at" => "2026-04-01"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="date")
    end

    test "dispatches datetime field" do
      field = Field.datetime(:starts_at)
      form = make_form(%{"starts_at" => "2026-04-01T10:30"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="datetime-local")
    end

    test "dispatches hidden field" do
      field = Field.hidden(:id)
      form = make_form(%{"id" => "42"})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ ~s(type="hidden")
    end

    test "passes label from Field struct" do
      field = Field.text_input(:first_name)
      form = make_form(%{})

      html =
        rendered_to_string(~H"""
        <FieldRenderer.render_field pf_field={field} form={form} />
        """)

      assert html =~ "First name"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/components/field_renderer_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement field_renderer.ex**

```elixir
# lib/phoenix_filament/components/field_renderer.ex
defmodule PhoenixFilament.Components.FieldRenderer do
  @moduledoc """
  Dispatches `%PhoenixFilament.Field{}` structs to the appropriate
  input component. This bridges Phase 1 data structures to Phase 2 components.

  Used by Form Builder (Phase 3) to render form fields from DSL declarations.
  """

  use Phoenix.Component

  import PhoenixFilament.Components.Input

  attr :pf_field, PhoenixFilament.Field, required: true
  attr :form, :any, required: true

  def render_field(%{pf_field: %{type: type} = pf_field, form: form} = assigns) do
    field = form[pf_field.name]

    assigns =
      assigns
      |> assign(:field, field)
      |> assign(:label, pf_field.label)
      |> merge_opts(pf_field.opts)

    dispatch(type, assigns)
  end

  defp dispatch(:text_input, assigns), do: text_input(assigns)
  defp dispatch(:textarea, assigns), do: textarea(assigns)
  defp dispatch(:number_input, assigns), do: number_input(assigns)
  defp dispatch(:select, assigns), do: select(assigns)
  defp dispatch(:checkbox, assigns), do: checkbox(assigns)
  defp dispatch(:toggle, assigns), do: toggle(assigns)
  defp dispatch(:date, assigns), do: date(assigns)
  defp dispatch(:datetime, assigns), do: datetime(assigns)
  defp dispatch(:hidden, assigns), do: hidden(assigns)

  defp merge_opts(assigns, opts) do
    Enum.reduce(opts, assigns, fn {key, value}, acc ->
      assign(acc, key, value)
    end)
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/components/field_renderer_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/components/field_renderer.ex test/phoenix_filament/components/field_renderer_test.exs
git commit -m "feat(components): add field renderer dispatching Field structs to components"
```

---

## Task 11: Components Module — Bulk Import

**Files:**
- Create: `lib/phoenix_filament/components.ex`

- [ ] **Step 1: Create components.ex**

```elixir
# lib/phoenix_filament/components.ex
defmodule PhoenixFilament.Components do
  @moduledoc """
  Imports all PhoenixFilament UI components.

  ## Usage

      defmodule MyAppWeb.PostLive do
        use PhoenixFilament.Components

        # Now available: <.text_input>, <.button>, <.modal>, etc.
      end

  For selective import:

      import PhoenixFilament.Components.Input
      import PhoenixFilament.Components.Button
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixFilament.Components.Input
      import PhoenixFilament.Components.Button
      import PhoenixFilament.Components.Badge
      import PhoenixFilament.Components.Card
      import PhoenixFilament.Components.Modal
      import PhoenixFilament.Components.FieldRenderer, only: [render_field: 1]
    end
  end
end
```

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 3: Commit**

```bash
git add lib/phoenix_filament/components.ex
git commit -m "feat(components): add use PhoenixFilament.Components bulk import"
```

---

## Task 12: Full Test Suite + Final Verification

**Files:**
- All test and source files from previous tasks

- [ ] **Step 1: Run the complete test suite**

Run: `mix test --include cascade`
Expected: All tests pass (80+ from Phase 1, plus all new component tests)

- [ ] **Step 2: Run the code formatter**

Run: `mix format --check-formatted`
Expected: All files formatted

If not: `mix format` then re-check.

- [ ] **Step 3: Verify clean compilation with no warnings**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation, zero warnings

- [ ] **Step 4: Verify no hardcoded colors in components**

Run: `grep -r "bg-blue\|bg-red\|bg-green\|text-blue\|text-red\|text-green\|#[0-9a-fA-F]\{3,6\}" lib/phoenix_filament/components/`
Expected: No matches — all colors use daisyUI semantic classes

- [ ] **Step 5: Verify no Tailwind class interpolation**

Run: `grep -r "\"btn-\#{" lib/phoenix_filament/components/ && grep -r "\"badge-\#{" lib/phoenix_filament/components/ && grep -r "\"input-\#{" lib/phoenix_filament/components/`
Expected: No matches — all classes use list syntax, not string interpolation

- [ ] **Step 6: Commit any final adjustments**

```bash
git add -A
git commit -m "chore: final Phase 2 verification pass"
```

---

## Success Criteria Verification

After completing all tasks, verify each success criterion from the roadmap:

| # | Criterion | Verified By |
|---|-----------|-------------|
| 1 | Components work in plain LiveView without Panel | All tests use render_component without Panel — they render standalone |
| 2 | Default theme produces professional appearance | Components use daisyUI 5 semantic classes which provide professional styling |
| 3 | Dark mode via CSS variables, no JS round-trip | Components use daisyUI classes that auto-respond to `data-theme` |
| 4 | Override brand colors via CSS variables | `Theme.css_vars/1` generates inline CSS variable overrides |
| 5 | No Tailwind class interpolation | Task 12 Step 5 verifies no string interpolation anywhere |

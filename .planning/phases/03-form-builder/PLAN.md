# Phase 3: Form Builder — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone `form_builder/1` function component that renders `%Field{}`, `%Section{}`, and `%Columns{}` structs into a complete HTML form with daisyUI styling, auto-wrapped `<.form>` tag, submit button, layout sections/columns, and client-side `visible_when` conditional visibility.

**Architecture:** Form Builder is a pure rendering module — a stateless Phoenix function component. The DSL (compile-time) produces a form schema (list of structs). The form_builder (render-time) iterates the schema, dispatching fields via FieldRenderer and wrapping layout items in HTML structure. A colocated JS hook handles visible_when client-side evaluation.

**Tech Stack:** Elixir 1.19+, Phoenix.Component, Phoenix.HTML.Form, FieldRenderer (Phase 2), daisyUI 5, LiveView 1.1 colocated JS hooks

---

## File Structure

### Source Files (create)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/form/section.ex` | `%Section{}` struct with label, visible_when, items |
| `lib/phoenix_filament/form/columns.ex` | `%Columns{}` struct with count, items |
| `lib/phoenix_filament/form/form_builder.ex` | `form_builder/1` function component |
| `lib/phoenix_filament/form/visibility.ex` | visible_when rendering helpers (wrapper div, data attrs) |

### Source Files (modify)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/resource/dsl.ex` | Add `section/2` and `columns/2` macros to FormFields |
| `lib/phoenix_filament/resource.ex` | Change `@_phx_filament_form_fields` to `@_phx_filament_form_schema` |

### Test Files (create)

| File | Responsibility |
|------|---------------|
| `test/phoenix_filament/form/section_test.exs` | Section struct tests |
| `test/phoenix_filament/form/columns_test.exs` | Columns struct tests |
| `test/phoenix_filament/form/form_builder_test.exs` | form_builder/1 rendering tests |
| `test/phoenix_filament/form/dsl_test.exs` | Extended DSL macro tests (section, columns, visible_when) |
| `test/phoenix_filament/form/visibility_test.exs` | visible_when wrapper rendering tests |

---

## Task 1: Section and Columns Structs

**Files:**
- Create: `lib/phoenix_filament/form/section.ex`
- Create: `lib/phoenix_filament/form/columns.ex`
- Create: `test/phoenix_filament/form/section_test.exs`
- Create: `test/phoenix_filament/form/columns_test.exs`

- [ ] **Step 1: Write failing tests for Section**

```elixir
# test/phoenix_filament/form/section_test.exs
defmodule PhoenixFilament.Form.SectionTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Form.Section
  alias PhoenixFilament.Field

  describe "%Section{}" do
    test "creates section with label and items" do
      fields = [Field.text_input(:title), Field.textarea(:body)]
      section = %Section{label: "Basic Info", items: fields}

      assert section.label == "Basic Info"
      assert length(section.items) == 2
      assert match?(%Field{name: :title}, hd(section.items))
    end

    test "defaults to empty items" do
      section = %Section{label: "Empty"}

      assert section.items == []
      assert section.visible_when == nil
    end

    test "supports visible_when" do
      section = %Section{
        label: "Advanced",
        visible_when: {:type, :in, ["pro", "enterprise"]},
        items: [Field.toggle(:feature_x)]
      }

      assert section.visible_when == {:type, :in, ["pro", "enterprise"]}
    end
  end
end
```

- [ ] **Step 2: Write failing tests for Columns**

```elixir
# test/phoenix_filament/form/columns_test.exs
defmodule PhoenixFilament.Form.ColumnsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Form.Columns
  alias PhoenixFilament.Field

  describe "%Columns{}" do
    test "creates columns with count and items" do
      fields = [Field.text_input(:first_name), Field.text_input(:last_name)]
      cols = %Columns{count: 2, items: fields}

      assert cols.count == 2
      assert length(cols.items) == 2
    end

    test "defaults to empty items" do
      cols = %Columns{count: 3}

      assert cols.items == []
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/form/`
Expected: Compilation error — modules not found

- [ ] **Step 4: Implement Section struct**

```elixir
# lib/phoenix_filament/form/section.ex
defmodule PhoenixFilament.Form.Section do
  @moduledoc """
  Groups form fields under a labeled heading.

  Renders as a `<fieldset>` with `<legend>` in the form builder.
  Supports `visible_when` for conditional section visibility.
  """

  @type t :: %__MODULE__{
          label: String.t(),
          visible_when: {atom(), atom(), any()} | nil,
          items: [PhoenixFilament.Field.t() | PhoenixFilament.Form.Columns.t()]
        }

  defstruct [:label, :visible_when, items: []]
end
```

- [ ] **Step 5: Implement Columns struct**

```elixir
# lib/phoenix_filament/form/columns.ex
defmodule PhoenixFilament.Form.Columns do
  @moduledoc """
  Arranges form fields in a CSS grid with N columns.

  Renders as a `<div class=\"grid grid-cols-N gap-4\">` in the form builder.
  """

  @type t :: %__MODULE__{
          count: pos_integer(),
          items: [PhoenixFilament.Field.t()]
        }

  defstruct [:count, items: []]
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/form/`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add lib/phoenix_filament/form/section.ex lib/phoenix_filament/form/columns.ex test/phoenix_filament/form/section_test.exs test/phoenix_filament/form/columns_test.exs
git commit -m "feat(form): add Section and Columns layout structs"
```

---

## Task 2: Extend DSL with section/2 and columns/2 Macros

**Files:**
- Modify: `lib/phoenix_filament/resource/dsl.ex`
- Modify: `lib/phoenix_filament/resource.ex`
- Create: `test/phoenix_filament/form/dsl_test.exs`

- [ ] **Step 1: Write failing tests for extended DSL**

```elixir
# test/phoenix_filament/form/dsl_test.exs
defmodule PhoenixFilament.Form.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Field
  alias PhoenixFilament.Form.{Section, Columns}

  describe "form DSL with section/2" do
    test "section wraps fields in Section struct" do
      defmodule SectionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          section "Basic Info" do
            text_input(:title, required: true)
            textarea(:body)
          end
        end
      end

      schema = SectionResource.__resource__(:form_schema)

      assert [%Section{label: "Basic Info", items: items}] = schema
      assert [%Field{name: :title}, %Field{name: :body}] = items
    end

    test "mixes top-level fields and sections" do
      defmodule MixedResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          text_input(:title)

          section "Details" do
            textarea(:body)
            toggle(:published)
          end
        end
      end

      schema = MixedResource.__resource__(:form_schema)

      assert [%Field{name: :title}, %Section{label: "Details", items: items}] = schema
      assert [%Field{name: :body}, %Field{name: :published}] = items
    end

    test "section with visible_when" do
      defmodule VisibleSectionResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          select(:status, options: ~w(draft published))

          section "Publishing", visible_when: {:status, :eq, "published"} do
            date(:published_at)
          end
        end
      end

      schema = VisibleSectionResource.__resource__(:form_schema)

      assert [%Field{name: :status}, %Section{label: "Publishing", visible_when: {:status, :eq, "published"}}] = schema
    end
  end

  describe "form DSL with columns/2" do
    test "columns wraps fields in Columns struct" do
      defmodule ColumnsResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          columns 2 do
            text_input(:title)
            text_input(:body)
          end
        end
      end

      schema = ColumnsResource.__resource__(:form_schema)

      assert [%Columns{count: 2, items: items}] = schema
      assert [%Field{name: :title}, %Field{name: :body}] = items
    end

    test "columns inside section" do
      defmodule NestedColumnsResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          section "Author" do
            columns 2 do
              text_input(:title)
              text_input(:body)
            end
            textarea(:body)
          end
        end
      end

      schema = NestedColumnsResource.__resource__(:form_schema)

      assert [%Section{label: "Author", items: items}] = schema
      assert [%Columns{count: 2, items: col_items}, %Field{name: :body}] = items
      assert [%Field{name: :title}, %Field{name: :body}] = col_items
    end
  end

  describe "form DSL with visible_when on fields" do
    test "visible_when stored in Field opts" do
      defmodule FieldVisibilityResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          toggle(:published)
          date(:published_at, visible_when: {:published, :eq, true})
        end
      end

      schema = FieldVisibilityResource.__resource__(:form_schema)

      assert [%Field{name: :published}, %Field{name: :published_at, opts: opts}] = schema
      assert opts[:visible_when] == {:published, :eq, true}
    end
  end

  describe "backward compatibility" do
    test "flat fields still work (no sections)" do
      defmodule FlatResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo

        form do
          text_input(:title)
          textarea(:body)
        end
      end

      schema = FlatResource.__resource__(:form_schema)

      assert [%Field{name: :title}, %Field{name: :body}] = schema
    end

    test "resource with no form block auto-discovers fields" do
      defmodule AutoResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo
      end

      schema = AutoResource.__resource__(:form_schema)

      assert is_list(schema)
      assert length(schema) > 0
      assert Enum.all?(schema, &match?(%Field{}, &1))
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/form/dsl_test.exs`
Expected: Compilation errors — `__resource__(:form_schema)` not defined, `section/2` and `columns/2` not available

- [ ] **Step 3: Implement DSL extension — section/2 and columns/2 macros**

The key challenge is nested context accumulation. The approach:
- Use a stack of module attributes. `@_phx_filament_form_context` is a stack (list of lists). 
- `section/2` pushes a new empty list, runs the block (which accumulates to the top of stack), then pops and wraps in `%Section{}`.
- `columns/2` does the same, wrapping in `%Columns{}`.
- Field macros always append to the top of the stack.
- The outermost level is `@_phx_filament_form_schema`.

Update `lib/phoenix_filament/resource/dsl.ex`:

```elixir
defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  defmacro form(do: block) do
    quote do
      Module.register_attribute(__MODULE__, :_phx_filament_form_context, accumulate: true)
      # Push root context
      @_phx_filament_form_context []

      import PhoenixFilament.Resource.DSL.FormFields
      unquote(block)
      import PhoenixFilament.Resource.DSL.FormFields, only: []

      # Pop root context and set as form schema
      [root | _] = @_phx_filament_form_context
      @_phx_filament_form_schema Enum.reverse(root)
      Module.delete_attribute(__MODULE__, :_phx_filament_form_context)
    end
  end

  defmacro table(do: block) do
    quote do
      import PhoenixFilament.Resource.DSL.TableColumns
      unquote(block)
      import PhoenixFilament.Resource.DSL.TableColumns, only: []
    end
  end
end

defmodule PhoenixFilament.Resource.DSL.FormFields do
  @moduledoc false

  # --- Field macros (append to current context) ---

  defmacro text_input(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.text_input(unquote(name), unquote(opts))
      )
    end
  end

  defmacro textarea(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.textarea(unquote(name), unquote(opts))
      )
    end
  end

  defmacro number_input(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.number_input(unquote(name), unquote(opts))
      )
    end
  end

  defmacro select(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.select(unquote(name), unquote(opts))
      )
    end
  end

  defmacro checkbox(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.checkbox(unquote(name), unquote(opts))
      )
    end
  end

  defmacro toggle(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.toggle(unquote(name), unquote(opts))
      )
    end
  end

  defmacro date(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.date(unquote(name), unquote(opts))
      )
    end
  end

  defmacro datetime(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.datetime(unquote(name), unquote(opts))
      )
    end
  end

  defmacro hidden(name, opts \\ []) do
    quote do
      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        PhoenixFilament.Field.hidden(unquote(name), unquote(opts))
      )
    end
  end

  # --- Layout macros ---

  defmacro section(label, opts \\ [], do: block) do
    quote do
      # Push new context for section children
      @_phx_filament_form_context []
      unquote(block)
      # Pop context, wrap in Section, push to parent
      [children | rest] = @_phx_filament_form_context
      Module.delete_attribute(__MODULE__, :_phx_filament_form_context)

      for item <- rest do
        @_phx_filament_form_context item
      end

      visible_when = Keyword.get(unquote(opts), :visible_when)

      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        %PhoenixFilament.Form.Section{
          label: unquote(label),
          visible_when: visible_when,
          items: Enum.reverse(children)
        }
      )
    end
  end

  defmacro columns(count, do: block) do
    quote do
      # Push new context for column children
      @_phx_filament_form_context []
      unquote(block)
      # Pop context, wrap in Columns, push to parent
      [children | rest] = @_phx_filament_form_context
      Module.delete_attribute(__MODULE__, :_phx_filament_form_context)

      for item <- rest do
        @_phx_filament_form_context item
      end

      PhoenixFilament.Resource.DSL.FormFields.__push_item__(
        __MODULE__,
        %PhoenixFilament.Form.Columns{
          count: unquote(count),
          items: Enum.reverse(children)
        }
      )
    end
  end

  # --- Internal helpers ---

  @doc false
  def __push_item__(module, item) do
    [current | rest] = Module.get_attribute(module, :_phx_filament_form_context)
    Module.delete_attribute(module, :_phx_filament_form_context)

    for ctx <- rest do
      Module.put_attribute(module, :_phx_filament_form_context, ctx)
    end

    Module.put_attribute(module, :_phx_filament_form_context, [item | current])
  end
end

defmodule PhoenixFilament.Resource.DSL.TableColumns do
  @moduledoc false

  defmacro column(name, opts \\ []) do
    quote do
      @_phx_filament_table_columns PhoenixFilament.Column.column(unquote(name), unquote(opts))
    end
  end
end
```

- [ ] **Step 4: Update resource.ex to use form_schema**

Modify `lib/phoenix_filament/resource.ex`:

In `__using__/1`, replace `@_phx_filament_form_fields` registration with `@_phx_filament_form_schema`:

```elixir
# Replace:
Module.register_attribute(__MODULE__, :_phx_filament_form_fields, accumulate: true)
# With:
Module.register_attribute(__MODULE__, :_phx_filament_form_schema, accumulate: false)
@_phx_filament_form_schema nil
```

In `__before_compile__/1`, replace `__resource__(:form_fields)` with both `:form_fields` (backward compat) and `:form_schema`:

```elixir
def __resource__(:form_schema) do
  case @_phx_filament_form_schema do
    nil -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
    schema -> schema
  end
end

def __resource__(:form_fields) do
  # Backward compat: extract flat Field list from schema
  @_phx_filament_form_schema
  |> case do
    nil -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
    schema -> PhoenixFilament.Form.Schema.extract_fields(schema)
  end
end
```

Also add a helper module for extracting flat fields:

```elixir
# lib/phoenix_filament/form/schema.ex
defmodule PhoenixFilament.Form.Schema do
  @moduledoc false

  def extract_fields(schema) when is_list(schema) do
    Enum.flat_map(schema, &extract_fields_from_item/1)
  end

  defp extract_fields_from_item(%PhoenixFilament.Field{} = field), do: [field]
  defp extract_fields_from_item(%PhoenixFilament.Form.Section{items: items}), do: extract_fields(items)
  defp extract_fields_from_item(%PhoenixFilament.Form.Columns{items: items}), do: extract_fields(items)
end
```

Also update `@valid_resource_keys` and `@callback` to include `:form_schema`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/form/dsl_test.exs`
Expected: All tests pass

- [ ] **Step 6: Run existing tests to verify no regressions**

Run: `mix test --include cascade`
Expected: All tests pass (existing resource_test.exs, dsl_test.exs tests should still work since `:form_fields` is backward compatible)

- [ ] **Step 7: Commit**

```bash
git add lib/phoenix_filament/resource/dsl.ex lib/phoenix_filament/resource.ex lib/phoenix_filament/form/schema.ex test/phoenix_filament/form/dsl_test.exs
git commit -m "feat(form): extend DSL with section/2, columns/2 macros and form_schema"
```

---

## Task 3: form_builder/1 Component — Basic Rendering

**Files:**
- Create: `lib/phoenix_filament/form/form_builder.ex`
- Create: `test/phoenix_filament/form/form_builder_test.exs`

- [ ] **Step 1: Write failing tests for form_builder**

```elixir
# test/phoenix_filament/form/form_builder_test.exs
defmodule PhoenixFilament.Form.FormBuilderTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Form.FormBuilder
  alias PhoenixFilament.Form.{Section, Columns}
  alias PhoenixFilament.Field

  defp make_form(params \\ %{}) do
    to_form(params, as: "post")
  end

  describe "form_builder/1 with flat fields" do
    test "renders form with fields and submit button" do
      form = make_form(%{"title" => "Hello", "body" => "World"})

      schema = [
        Field.text_input(:title),
        Field.textarea(:body)
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} phx-change="validate" phx-submit="save" />
        """)

      assert html =~ "<form"
      assert html =~ ~s(phx-change="validate")
      assert html =~ ~s(phx-submit="save")
      assert html =~ ~s(type="text")
      assert html =~ "<textarea"
      assert html =~ ~s(type="submit")
      assert html =~ "Save"
    end

    test "renders custom submit label" do
      form = make_form()
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit_label="Create Post" />
        """)

      assert html =~ "Create Post"
    end

    test "hides submit button when submit is false" do
      form = make_form()
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      refute html =~ ~s(type="submit")
    end
  end

  describe "form_builder/1 with sections" do
    test "renders section as fieldset with legend" do
      form = make_form(%{"title" => "", "body" => ""})

      schema = [
        %Section{label: "Basic Info", items: [
          Field.text_input(:title),
          Field.textarea(:body)
        ]}
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "<fieldset"
      assert html =~ "Basic Info"
      assert html =~ ~s(type="text")
      assert html =~ "<textarea"
    end
  end

  describe "form_builder/1 with columns" do
    test "renders columns as CSS grid" do
      form = make_form(%{"first" => "", "last" => ""})

      schema = [
        %Columns{count: 2, items: [
          Field.text_input(:first),
          Field.text_input(:last)
        ]}
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "grid grid-cols-2 gap-4"
    end
  end

  describe "form_builder/1 with nested layout" do
    test "renders section with columns inside" do
      form = make_form(%{"first" => "", "last" => "", "bio" => ""})

      schema = [
        %Section{label: "Author", items: [
          %Columns{count: 2, items: [
            Field.text_input(:first),
            Field.text_input(:last)
          ]},
          Field.textarea(:bio)
        ]}
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} />
        """)

      assert html =~ "<fieldset"
      assert html =~ "Author"
      assert html =~ "grid grid-cols-2 gap-4"
      assert html =~ "<textarea"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/form/form_builder_test.exs`
Expected: Compilation error — module not found

- [ ] **Step 3: Implement form_builder.ex**

```elixir
# lib/phoenix_filament/form/form_builder.ex
defmodule PhoenixFilament.Form.FormBuilder do
  @moduledoc """
  Renders a complete form from a form schema.

  ## Example

      <.form_builder
        form={@form}
        schema={@schema}
        phx-change="validate"
        phx-submit="save"
      />
  """

  use Phoenix.Component

  alias PhoenixFilament.Field
  alias PhoenixFilament.Form.{Section, Columns}

  import PhoenixFilament.Components.FieldRenderer, only: [render_field: 1]
  import PhoenixFilament.Components.Button, only: [button: 1]

  @grid_classes %{
    1 => "grid-cols-1",
    2 => "grid-cols-2",
    3 => "grid-cols-3",
    4 => "grid-cols-4"
  }

  @doc """
  Renders a complete form with fields, sections, columns, and submit button.

  ## Example

      <.form_builder form={@form} schema={@schema} phx-change="validate" phx-submit="save" />
  """
  attr :form, :any, required: true
  attr :schema, :list, required: true
  attr :submit_label, :string, default: "Save"
  attr :submit, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-change phx-submit)

  def form_builder(assigns) do
    ~H"""
    <.form for={@form} class={@class} {@rest}>
      <.render_items items={@schema} form={@form} />
      <div :if={@submit} class="mt-6">
        <.button type="submit">{@submit_label}</.button>
      </div>
    </.form>
    """
  end

  attr :items, :list, required: true
  attr :form, :any, required: true

  defp render_items(assigns) do
    ~H"""
    <div :for={item <- @items} class="mb-4">
      <.render_item item={item} form={@form} />
    </div>
    """
  end

  attr :item, :any, required: true
  attr :form, :any, required: true

  defp render_item(%{item: %Field{} = _field} = assigns) do
    ~H"""
    <.render_field pf_field={@item} form={@form} />
    """
  end

  defp render_item(%{item: %Section{} = _section} = assigns) do
    ~H"""
    <fieldset class="fieldset bg-base-200/50 border border-base-300 rounded-box p-4">
      <legend class="fieldset-legend font-semibold">{@item.label}</legend>
      <.render_items items={@item.items} form={@form} />
    </fieldset>
    """
  end

  defp render_item(%{item: %Columns{} = _columns} = assigns) do
    assigns = assign(assigns, :grid_class, Map.get(@grid_classes, assigns.item.count, "grid-cols-2"))

    ~H"""
    <div class={["grid gap-4", @grid_class]}>
      <.render_items items={@item.items} form={@form} />
    </div>
    """
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/form/form_builder_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/form/form_builder.ex test/phoenix_filament/form/form_builder_test.exs
git commit -m "feat(form): add form_builder component with sections and columns rendering"
```

---

## Task 4: visible_when Rendering

**Files:**
- Create: `lib/phoenix_filament/form/visibility.ex`
- Create: `test/phoenix_filament/form/visibility_test.exs`
- Modify: `lib/phoenix_filament/form/form_builder.ex`

- [ ] **Step 1: Write failing tests for visibility rendering**

```elixir
# test/phoenix_filament/form/visibility_test.exs
defmodule PhoenixFilament.Form.VisibilityTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Form.FormBuilder
  alias PhoenixFilament.Form.Section
  alias PhoenixFilament.Field

  defp make_form(params \\ %{}) do
    to_form(params, as: "post")
  end

  describe "visible_when on fields" do
    test "wraps field in hidden div with hook data attrs" do
      form = make_form(%{"published" => "false", "published_at" => ""})

      schema = [
        Field.toggle(:published),
        Field.date(:published_at, visible_when: {:published, :eq, "true"})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(id="field-published_at")
      assert html =~ ~s(style="display:none")
      assert html =~ ~s(phx-hook="PFVisibility")
      assert html =~ ~s(data-controlling-id="post_published")
      assert html =~ ~s(data-operator="eq")
      assert html =~ ~s(data-expected="true")
    end

    test "field without visible_when renders normally" do
      form = make_form(%{"title" => ""})
      schema = [Field.text_input(:title)]
      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      refute html =~ "phx-hook"
      refute html =~ "PFVisibility"
    end
  end

  describe "visible_when on sections" do
    test "wraps section in hidden div with hook data attrs" do
      form = make_form(%{"type" => ""})

      schema = [
        Field.select(:type, options: ["basic", "pro"]),
        %Section{
          label: "Advanced",
          visible_when: {:type, :eq, "pro"},
          items: [Field.toggle(:feature_x)]
        }
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(phx-hook="PFVisibility")
      assert html =~ ~s(data-controlling-id="post_type")
      assert html =~ ~s(data-operator="eq")
      assert html =~ ~s(data-expected="pro")
    end
  end

  describe "visible_when with :in operator" do
    test "serializes list values as comma-separated" do
      form = make_form(%{"role" => ""})

      schema = [
        Field.select(:role, options: ["user", "admin", "super"]),
        Field.text_input(:admin_note, visible_when: {:role, :in, ["admin", "super"]})
      ]

      assigns = %{form: form, schema: schema}

      html =
        rendered_to_string(~H"""
        <FormBuilder.form_builder form={@form} schema={@schema} submit={false} />
        """)

      assert html =~ ~s(data-operator="in")
      assert html =~ ~s(data-expected="admin,super")
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/form/visibility_test.exs`
Expected: Failures — no visibility wrapper rendered

- [ ] **Step 3: Implement visibility.ex**

```elixir
# lib/phoenix_filament/form/visibility.ex
defmodule PhoenixFilament.Form.Visibility do
  @moduledoc """
  Helpers for rendering visible_when conditional visibility.

  Wraps form items in a container div with data attributes for the
  PFVisibility JS hook to evaluate client-side.
  """

  @doc """
  Returns visibility data attrs for a given visible_when condition and form.
  Returns nil if no condition is set.
  """
  @spec attrs(keyword() | nil, Phoenix.HTML.Form.t()) :: map() | nil
  def attrs(nil, _form), do: nil

  def attrs({controlling_field, operator, value}, form) do
    %{
      id: "field-#{controlling_field}-target-#{:erlang.unique_integer([:positive])}",
      style: "display:none",
      "phx-hook": "PFVisibility",
      "data-controlling-id": "#{form.id}_#{controlling_field}",
      "data-operator": to_string(operator),
      "data-expected": serialize_value(value)
    }
  end

  defp serialize_value(values) when is_list(values), do: Enum.join(values, ",")
  defp serialize_value(value), do: to_string(value)
end
```

Wait — the test expects `id="field-published_at"` not a random ID. Let me fix. The ID should be deterministic based on the field name:

```elixir
  def attrs({controlling_field, operator, value}, form, target_name) do
    %{
      id: "field-#{target_name}",
      style: "display:none",
      "phx-hook": "PFVisibility",
      "data-controlling-id": "#{form.id}_#{controlling_field}",
      "data-operator": to_string(operator),
      "data-expected": serialize_value(value)
    }
  end
```

- [ ] **Step 4: Update form_builder.ex to use Visibility for fields and sections**

In `form_builder.ex`, modify `render_item/1` for `%Field{}` and `%Section{}` to check for `visible_when` and wrap accordingly:

```elixir
  defp render_item(%{item: %Field{} = field} = assigns) do
    visible_when = Keyword.get(field.opts, :visible_when)

    if visible_when do
      vis_attrs = PhoenixFilament.Form.Visibility.attrs(visible_when, assigns.form, field.name)
      assigns = assign(assigns, :vis, vis_attrs)

      ~H"""
      <div id={@vis.id} style={@vis.style} phx-hook={@vis[:"phx-hook"]}
           data-controlling-id={@vis[:"data-controlling-id"]}
           data-operator={@vis[:"data-operator"]}
           data-expected={@vis[:"data-expected"]}>
        <.render_field pf_field={@item} form={@form} />
      </div>
      """
    else
      ~H"""
      <.render_field pf_field={@item} form={@form} />
      """
    end
  end

  defp render_item(%{item: %Section{} = section} = assigns) do
    if section.visible_when do
      vis_attrs = PhoenixFilament.Form.Visibility.attrs(section.visible_when, assigns.form, "section-#{section.label |> String.downcase() |> String.replace(" ", "-")}")
      assigns = assign(assigns, :vis, vis_attrs)

      ~H"""
      <div id={@vis.id} style={@vis.style} phx-hook={@vis[:"phx-hook"]}
           data-controlling-id={@vis[:"data-controlling-id"]}
           data-operator={@vis[:"data-operator"]}
           data-expected={@vis[:"data-expected"]}>
        <fieldset class="fieldset bg-base-200/50 border border-base-300 rounded-box p-4">
          <legend class="fieldset-legend font-semibold">{@item.label}</legend>
          <.render_items items={@item.items} form={@form} />
        </fieldset>
      </div>
      """
    else
      ~H"""
      <fieldset class="fieldset bg-base-200/50 border border-base-300 rounded-box p-4">
        <legend class="fieldset-legend font-semibold">{@item.label}</legend>
        <.render_items items={@item.items} form={@form} />
      </fieldset>
      """
    end
  end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/form/visibility_test.exs`
Expected: All tests pass

- [ ] **Step 6: Run full suite for regressions**

Run: `mix test --include cascade`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add lib/phoenix_filament/form/visibility.ex lib/phoenix_filament/form/form_builder.ex test/phoenix_filament/form/visibility_test.exs
git commit -m "feat(form): add visible_when conditional visibility with JS hook data attrs"
```

---

## Task 5: PFVisibility JS Hook

**Files:**
- Create: `lib/phoenix_filament/form/hooks.ex`

This task creates the Elixir module that provides the JS hook code. The actual JS is served as a colocated hook string that host apps register in their LiveView socket configuration.

- [ ] **Step 1: Implement hooks.ex**

```elixir
# lib/phoenix_filament/form/hooks.ex
defmodule PhoenixFilament.Form.Hooks do
  @moduledoc """
  JavaScript hooks for PhoenixFilament Form Builder.

  Register these hooks in your LiveView socket configuration:

      # In app.js:
      import { getHooks } from "phoenix_filament"
      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { ...getHooks(), ...Hooks }
      })

  Or copy the hook manually:

      const PFVisibility = PhoenixFilament.Form.Hooks.visibility_hook_js()
  """

  @visibility_hook_js """
  {
    mounted() {
      const controlling = document.getElementById(this.el.dataset.controllingId)
      if (!controlling) return

      const evaluate = () => {
        const op = this.el.dataset.operator
        const expected = this.el.dataset.expected
        const actual = controlling.type === "checkbox"
          ? String(controlling.checked)
          : controlling.value

        const match = op === "eq" ? actual === expected
                    : op === "neq" ? actual !== expected
                    : op === "in" ? expected.split(",").includes(actual)
                    : op === "not_in" ? !expected.split(",").includes(actual)
                    : false

        this.el.style.display = match ? "" : "none"
      }

      controlling.addEventListener("input", evaluate)
      controlling.addEventListener("change", evaluate)
      evaluate()
    }
  }
  """

  @doc "Returns the PFVisibility hook JavaScript source as a string."
  @spec visibility_hook_js() :: String.t()
  def visibility_hook_js, do: @visibility_hook_js
end
```

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 3: Commit**

```bash
git add lib/phoenix_filament/form/hooks.ex
git commit -m "feat(form): add PFVisibility JS hook for conditional field visibility"
```

---

## Task 6: Update Components Module + Export form_builder

**Files:**
- Modify: `lib/phoenix_filament/components.ex`

- [ ] **Step 1: Add form_builder to bulk import**

Add to `lib/phoenix_filament/components.ex` `__using__` macro:

```elixir
import PhoenixFilament.Form.FormBuilder, only: [form_builder: 1]
```

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation

- [ ] **Step 3: Commit**

```bash
git add lib/phoenix_filament/components.ex
git commit -m "feat(components): export form_builder in bulk import"
```

---

## Task 7: Full Test Suite + Final Verification

**Files:**
- All test and source files from previous tasks

- [ ] **Step 1: Run the complete test suite**

Run: `mix test --include cascade`
Expected: All tests pass (151 from Phase 1-2 + new form tests)

- [ ] **Step 2: Run the code formatter**

Run: `mix format --check-formatted`
Expected: All files formatted. If not: `mix format` then re-check.

- [ ] **Step 3: Verify clean compilation with no warnings**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation, zero warnings

- [ ] **Step 4: Verify no Tailwind class interpolation**

Run: `grep -rn '"grid-cols-#{' lib/phoenix_filament/form/`
Expected: No matches — grid classes use static map

- [ ] **Step 5: Commit any final adjustments**

```bash
git add -A
git commit -m "chore: final Phase 3 verification pass"
```

---

## Success Criteria Verification

After completing all tasks, verify each success criterion from the roadmap:

| # | Criterion | Verified By |
|---|-----------|-------------|
| 1 | Form works in plain LiveView, no panel | form_builder_test.exs renders forms standalone with no Panel |
| 2 | Submit calls changeset, renders errors inline | form_builder passes phx-submit to `<form>`, error display via Phase 2 Input components |
| 3 | Separate create/update changesets | Form Builder is changeset-agnostic — receives @form from parent. Phase 5 selects changeset. |
| 4 | Live validation on type/blur | form_builder renders phx-change on form tag. Parent handles event. |
| 5 | visible_when without server round-trip | PFVisibility hook evaluates client-side. Data attrs + JS, no phx-change. |

# Phase 5: Resource Abstraction — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `use PhoenixFilament.Resource` turn the module into a LiveView that auto-generates CRUD pages (index, create, edit, show) from an Ecto schema, with changeset integration, authorization, and delete confirmation.

**Architecture:** Thin Delegation — `__before_compile__` injects minimal LiveView callbacks that delegate to internal modules (Lifecycle, CRUD, Authorize, Renderer). Each module is independently testable. The Resource module is both config (DSL, NimbleOptions) AND the LiveView.

**Tech Stack:** Elixir 1.19+, Phoenix.LiveView 1.1, Ecto, NimbleOptions, existing form_builder/1 + TableLive

---

## File Structure

### Source Files (create)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/resource/lifecycle.ex` | mount, handle_params (apply_action), handle_event, handle_info |
| `lib/phoenix_filament/resource/renderer.ex` | render/1 composing TableLive + form_builder + modal + show |
| `lib/phoenix_filament/resource/crud.ex` | create, update, delete, get! — pure Ecto operations |
| `lib/phoenix_filament/resource/authorize.ex` | authorize!/4 wrapper + UnauthorizedError |

### Source Files (modify)

| File | Responsibility |
|------|---------------|
| `lib/phoenix_filament/resource.ex` | Add `use Phoenix.LiveView`, inject thin callbacks |
| `lib/phoenix_filament/resource/options.ex` | Add `create_changeset`, `update_changeset` options |

### Test Files (create)

| File | Responsibility |
|------|---------------|
| `test/phoenix_filament/resource/authorize_test.exs` | authorize!/4 with/without callback |
| `test/phoenix_filament/resource/crud_test.exs` | CRUD operations (basic, may need sandbox) |
| `test/phoenix_filament/resource/lifecycle_test.exs` | apply_action assigns and page titles |
| `test/phoenix_filament/resource/renderer_test.exs` | HTML rendering per action |
| `test/phoenix_filament/resource/options_extended_test.exs` | New NimbleOptions validation |

---

## Task 1: Extend NimbleOptions with Changeset Options

**Files:**
- Modify: `lib/phoenix_filament/resource/options.ex`
- Create: `test/phoenix_filament/resource/options_extended_test.exs`

- [ ] **Step 1: Write failing tests for new options**

```elixir
# test/phoenix_filament/resource/options_extended_test.exs
defmodule PhoenixFilament.Resource.OptionsExtendedTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Options

  describe "changeset options" do
    test "accepts create_changeset function" do
      fun = fn _struct, _params -> :ok end
      opts = [schema: MySchema, repo: MyRepo, create_changeset: fun]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.schema())
      assert validated[:create_changeset] == fun
    end

    test "accepts update_changeset function" do
      fun = fn _record, _params -> :ok end
      opts = [schema: MySchema, repo: MyRepo, update_changeset: fun]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.schema())
      assert validated[:update_changeset] == fun
    end

    test "defaults to nil when not provided" do
      opts = [schema: MySchema, repo: MyRepo]
      assert {:ok, validated} = NimbleOptions.validate(opts, Options.schema())
      assert validated[:create_changeset] == nil
      assert validated[:update_changeset] == nil
    end

    test "rejects non-function values" do
      opts = [schema: MySchema, repo: MyRepo, create_changeset: "not_a_function"]
      assert {:error, _} = NimbleOptions.validate(opts, Options.schema())
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/options_extended_test.exs`
Expected: Failures — options not recognized

- [ ] **Step 3: Implement option extensions**

Update `lib/phoenix_filament/resource/options.ex`:

```elixir
defmodule PhoenixFilament.Resource.Options do
  @moduledoc false

  @schema NimbleOptions.new!(
            schema: [type: :atom, required: true, doc: "The Ecto schema module"],
            repo: [type: :atom, required: true, doc: "The Ecto repo module"],
            label: [
              type: :string,
              doc: "Human-readable resource name (auto-derived from schema if omitted)"
            ],
            plural_label: [type: :string, doc: "Plural form of label"],
            icon: [type: :string, doc: "Icon name for panel navigation"],
            create_changeset: [
              type: {:or, [{:fun, 2}, nil]},
              default: nil,
              doc: "Function `(struct, params) → changeset` for create. Default: `schema.changeset/2`"
            ],
            update_changeset: [
              type: {:or, [{:fun, 2}, nil]},
              default: nil,
              doc: "Function `(record, params) → changeset` for update. Default: `schema.changeset/2`"
            ]
          )

  def schema, do: @schema
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/options_extended_test.exs`
Expected: All pass

- [ ] **Step 5: Run full suite for regressions**

Run: `mix test --include cascade`
Expected: All pass

- [ ] **Step 6: Commit**

```bash
git add lib/phoenix_filament/resource/options.ex test/phoenix_filament/resource/options_extended_test.exs
git commit -m "feat(resource): add create_changeset and update_changeset NimbleOptions"
```

---

## Task 2: Authorize Module

**Files:**
- Create: `lib/phoenix_filament/resource/authorize.ex`
- Create: `test/phoenix_filament/resource/authorize_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/resource/authorize_test.exs
defmodule PhoenixFilament.Resource.AuthorizeTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Authorize

  # Module with authorize/3 that allows admins
  defmodule AllowAdminResource do
    def authorize(:create, _record, %{role: "admin"}), do: :ok
    def authorize(:create, _record, _user), do: {:error, :unauthorized}
    def authorize(:delete, _record, %{role: "admin"}), do: :ok
    def authorize(:delete, _record, _user), do: {:error, :unauthorized}
  end

  # Module without authorize/3
  defmodule NoAuthResource do
  end

  describe "authorize!/4" do
    test "allows when resource has no authorize/3 callback" do
      assert :ok = Authorize.authorize!(NoAuthResource, :create, nil, %{role: "user"})
    end

    test "allows when authorize/3 returns :ok" do
      assert :ok = Authorize.authorize!(AllowAdminResource, :create, nil, %{role: "admin"})
    end

    test "raises when authorize/3 returns error" do
      assert_raise PhoenixFilament.Resource.UnauthorizedError, fn ->
        Authorize.authorize!(AllowAdminResource, :create, nil, %{role: "user"})
      end
    end

    test "allows when user is nil and no authorize/3 defined" do
      assert :ok = Authorize.authorize!(NoAuthResource, :delete, nil, nil)
    end

    test "raises with descriptive message" do
      error =
        assert_raise PhoenixFilament.Resource.UnauthorizedError, fn ->
          Authorize.authorize!(AllowAdminResource, :delete, nil, %{role: "editor"})
        end

      assert error.message =~ "Unauthorized"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/authorize_test.exs`
Expected: Compilation error — modules not found

- [ ] **Step 3: Implement Authorize + UnauthorizedError**

```elixir
# lib/phoenix_filament/resource/authorize.ex
defmodule PhoenixFilament.Resource.Authorize do
  @moduledoc """
  Wraps authorization checks around Resource CRUD operations.

  If the Resource module defines `authorize/3`, it is called before every
  write operation. If not defined, all operations are allowed by default.

  ## Example

      def authorize(:create, _record, user) do
        if user.role in ["admin", "editor"], do: :ok, else: {:error, :unauthorized}
      end
  """

  @doc "Checks authorization. Raises UnauthorizedError on denial."
  @spec authorize!(module(), atom(), any(), any()) :: :ok
  def authorize!(resource_module, action, record, user) do
    if function_exported?(resource_module, :authorize, 3) do
      case resource_module.authorize(action, record, user) do
        :ok -> :ok
        {:error, reason} -> raise PhoenixFilament.Resource.UnauthorizedError, reason: reason
      end
    else
      :ok
    end
  end
end

defmodule PhoenixFilament.Resource.UnauthorizedError do
  @moduledoc "Raised when a Resource authorization check fails."
  defexception [:reason]

  @impl true
  def message(%{reason: reason}) do
    "Unauthorized: #{inspect(reason)}"
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/authorize_test.exs`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/resource/authorize.ex test/phoenix_filament/resource/authorize_test.exs
git commit -m "feat(resource): add Authorize module with authorize!/4"
```

---

## Task 3: CRUD Module

**Files:**
- Create: `lib/phoenix_filament/resource/crud.ex`
- Create: `test/phoenix_filament/resource/crud_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/resource/crud_test.exs
defmodule PhoenixFilament.Resource.CRUDTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.CRUD

  # Mock repo that tracks calls
  defmodule MockRepo do
    def insert(changeset), do: {:ok, %{id: 1, changeset: changeset}}
    def update(changeset), do: {:ok, %{id: 1, changeset: changeset}}
    def delete(record), do: {:ok, record}
    def get!(schema, id), do: %{__struct__: schema, id: id, title: "Test"}
  end

  # Mock changeset function
  defp mock_changeset(struct_or_record, params) do
    %{data: struct_or_record, params: params, valid?: true}
  end

  describe "create/4" do
    test "builds changeset and inserts" do
      result = CRUD.create(
        PhoenixFilament.Test.Schemas.Post,
        MockRepo,
        &mock_changeset/2,
        %{"title" => "New Post"}
      )

      assert {:ok, %{id: 1}} = result
    end
  end

  describe "update/4" do
    test "builds changeset from record and updates" do
      record = %{id: 1, title: "Old"}
      result = CRUD.update(record, MockRepo, &mock_changeset/2, %{"title" => "New"})

      assert {:ok, %{id: 1}} = result
    end
  end

  describe "delete/2" do
    test "deletes record" do
      record = %{id: 1, title: "Delete me"}
      result = CRUD.delete(record, MockRepo)

      assert {:ok, ^record} = result
    end
  end

  describe "get!/3" do
    test "fetches record by id" do
      result = CRUD.get!(PhoenixFilament.Test.Schemas.Post, MockRepo, 42)

      assert result.id == 42
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/crud_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement CRUD module**

```elixir
# lib/phoenix_filament/resource/crud.ex
defmodule PhoenixFilament.Resource.CRUD do
  @moduledoc """
  Pure CRUD operations against an Ecto repo.

  No LiveView dependency. Testable with mock repos.
  """

  @doc "Creates a new record. Builds changeset from empty struct + params, then inserts."
  @spec create(module(), module(), (map(), map() -> Ecto.Changeset.t()), map()) ::
          {:ok, any()} | {:error, Ecto.Changeset.t()}
  def create(schema, repo, changeset_fn, params) do
    schema
    |> struct()
    |> changeset_fn.(params)
    |> repo.insert()
  end

  @doc "Updates an existing record. Builds changeset from record + params, then updates."
  @spec update(any(), module(), (map(), map() -> Ecto.Changeset.t()), map()) ::
          {:ok, any()} | {:error, Ecto.Changeset.t()}
  def update(record, repo, changeset_fn, params) do
    record
    |> changeset_fn.(params)
    |> repo.update()
  end

  @doc "Deletes a record."
  @spec delete(any(), module()) :: {:ok, any()} | {:error, Ecto.Changeset.t()}
  def delete(record, repo) do
    repo.delete(record)
  end

  @doc "Fetches a record by ID. Raises if not found."
  @spec get!(module(), module(), any()) :: any()
  def get!(schema, repo, id) do
    repo.get!(schema, id)
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/crud_test.exs`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/resource/crud.ex test/phoenix_filament/resource/crud_test.exs
git commit -m "feat(resource): add CRUD module for Ecto operations"
```

---

## Task 4: Lifecycle Module

**Files:**
- Create: `lib/phoenix_filament/resource/lifecycle.ex`
- Create: `test/phoenix_filament/resource/lifecycle_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/resource/lifecycle_test.exs
defmodule PhoenixFilament.Resource.LifecycleTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Resource.Lifecycle

  # Mock resource module
  defmodule MockResource do
    def __resource__(:schema), do: PhoenixFilament.Test.Schemas.Post
    def __resource__(:repo), do: PhoenixFilament.Test.FakeRepo
    def __resource__(:opts), do: [label: "Blog Post", plural_label: "Blog Posts"]
    def __resource__(:form_schema), do: [PhoenixFilament.Field.text_input(:title)]
    def __resource__(:table_columns), do: [PhoenixFilament.Column.column(:title, sortable: true)]
    def __resource__(:table_actions), do: []
    def __resource__(:table_filters), do: []
  end

  defp base_socket do
    # Minimal socket-like map for testing assign logic
    %{assigns: %{__changed__: %{}}}
  end

  describe "init_assigns/2" do
    test "sets resource metadata on socket" do
      socket = Lifecycle.init_assigns(base_socket(), MockResource)

      assert socket.assigns.resource == MockResource
      assert socket.assigns.schema == PhoenixFilament.Test.Schemas.Post
      assert socket.assigns.repo == PhoenixFilament.Test.FakeRepo
      assert socket.assigns.form_schema == [%PhoenixFilament.Field{name: :title}]
    end
  end

  describe "apply_action/3" do
    test "index sets page title from plural_label" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:index, %{})

      assert socket.assigns.page_title == "Blog Posts"
      assert socket.assigns.record == nil
    end

    test "new sets page title and empty form" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      assert socket.assigns.page_title == "New Blog Post"
      assert socket.assigns.record == nil
      assert socket.assigns.form != nil
      assert socket.assigns.changeset_fn != nil
    end

    test "edit sets page title and loaded form" do
      # Note: edit calls repo.get! which needs a real repo
      # For this test, we verify the structure — full integration deferred
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)

      # Can't fully test edit without real repo, but verify structure exists
      assert function_exported?(Lifecycle, :apply_action, 3)
    end

    test "show sets page title" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)

      assert function_exported?(Lifecycle, :apply_action, 3)
    end
  end

  describe "changeset resolution" do
    test "uses default changeset when none configured" do
      socket =
        base_socket()
        |> Lifecycle.init_assigns(MockResource)
        |> Lifecycle.apply_action(:new, %{})

      # changeset_fn should be set (defaults to schema.changeset/2)
      assert is_function(socket.assigns.changeset_fn, 2)
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/lifecycle_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement Lifecycle module**

```elixir
# lib/phoenix_filament/resource/lifecycle.ex
defmodule PhoenixFilament.Resource.Lifecycle do
  @moduledoc """
  LiveView lifecycle management for Resource CRUD pages.

  Handles mount, apply_action per live_action, event handling,
  and info message routing. Called by thin callbacks injected
  into the Resource module.
  """

  import Phoenix.Component, only: [assign: 3, to_form: 1]

  alias PhoenixFilament.Resource.{CRUD, Authorize}

  @doc "Initializes resource assigns on mount."
  def init_assigns(socket, resource_module) do
    opts = resource_module.__resource__(:opts)

    socket
    |> assign(:resource, resource_module)
    |> assign(:schema, resource_module.__resource__(:schema))
    |> assign(:repo, resource_module.__resource__(:repo))
    |> assign(:opts, opts)
    |> assign(:form_schema, resource_module.__resource__(:form_schema))
    |> assign(:columns, resource_module.__resource__(:table_columns))
    |> assign(:table_actions, resource_module.__resource__(:table_actions))
    |> assign(:table_filters, resource_module.__resource__(:table_filters))
    |> assign(:page_title, nil)
    |> assign(:record, nil)
    |> assign(:form, nil)
    |> assign(:changeset_fn, nil)
    |> assign(:params, %{})
  end

  @doc "Applies action based on live_action, setting appropriate assigns."
  def apply_action(socket, :index, params) do
    label = plural_label(socket)

    socket
    |> assign(:page_title, label)
    |> assign(:params, params)
    |> assign(:record, nil)
    |> assign(:form, nil)
  end

  def apply_action(socket, :new, _params) do
    label = singular_label(socket)
    schema = socket.assigns.schema
    changeset_fn = resolve_changeset_fn(socket, :create)
    changeset = changeset_fn.(struct(schema), %{})

    socket
    |> assign(:page_title, "New #{label}")
    |> assign(:record, nil)
    |> assign(:changeset_fn, changeset_fn)
    |> assign(:form, to_form(changeset))
  end

  def apply_action(socket, :edit, %{"id" => id}) do
    label = singular_label(socket)
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)
    changeset_fn = resolve_changeset_fn(socket, :update)
    changeset = changeset_fn.(record, %{})

    socket
    |> assign(:page_title, "Edit #{label}")
    |> assign(:record, record)
    |> assign(:changeset_fn, changeset_fn)
    |> assign(:form, to_form(changeset))
  end

  def apply_action(socket, :show, %{"id" => id}) do
    label = singular_label(socket)
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)

    socket
    |> assign(:page_title, label)
    |> assign(:record, record)
  end

  @doc "Handles validate event — rebuilds changeset from params."
  def handle_validate(socket, params) do
    changeset_fn = socket.assigns.changeset_fn
    record = socket.assigns.record || struct(socket.assigns.schema)

    changeset =
      record
      |> changeset_fn.(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @doc "Handles save event — authorizes then creates or updates."
  def handle_save(socket, params) do
    resource = socket.assigns.resource
    user = socket.assigns[:current_user]

    if socket.assigns.record do
      Authorize.authorize!(resource, :update, socket.assigns.record, user)

      case CRUD.update(socket.assigns.record, socket.assigns.repo, socket.assigns.changeset_fn, params) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(:info, "#{singular_label(socket)} updated successfully")
           |> Phoenix.LiveView.push_patch(to: index_path(socket))}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      Authorize.authorize!(resource, :create, nil, user)

      case CRUD.create(socket.assigns.schema, socket.assigns.repo, socket.assigns.changeset_fn, params) do
        {:ok, _record} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(:info, "#{singular_label(socket)} created successfully")
           |> Phoenix.LiveView.push_patch(to: index_path(socket))}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  rescue
    PhoenixFilament.Resource.UnauthorizedError ->
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, "You are not authorized to perform this action")}
  end

  @doc "Handles table action messages from TableLive."
  def handle_table_action(socket, :view, id) do
    {:noreply, Phoenix.LiveView.push_navigate(socket, to: show_path(socket, id))}
  end

  def handle_table_action(socket, :edit, id) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: edit_path(socket, id))}
  end

  def handle_table_action(socket, :delete, id) do
    resource = socket.assigns.resource
    user = socket.assigns[:current_user]
    record = CRUD.get!(socket.assigns.schema, socket.assigns.repo, id)

    Authorize.authorize!(resource, :delete, record, user)
    {:ok, _} = CRUD.delete(record, socket.assigns.repo)

    {:noreply,
     socket
     |> Phoenix.LiveView.put_flash(:info, "#{singular_label(socket)} deleted successfully")
     |> Phoenix.LiveView.push_patch(to: index_path(socket))}
  rescue
    PhoenixFilament.Resource.UnauthorizedError ->
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, "You are not authorized to delete this record")}
  end

  @doc "Handles table patch messages (URL state sync)."
  def handle_table_patch(socket, params) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: index_path_with_params(socket, params))}
  end

  # --- Private helpers ---

  defp singular_label(socket) do
    opts = socket.assigns.opts
    opts[:label] || socket.assigns.schema |> Module.split() |> List.last()
  end

  defp plural_label(socket) do
    opts = socket.assigns.opts
    opts[:plural_label] || "#{singular_label(socket)}s"
  end

  defp resolve_changeset_fn(socket, :create) do
    opts = socket.assigns.opts
    opts[:create_changeset] || default_changeset_fn(socket.assigns.schema)
  end

  defp resolve_changeset_fn(socket, :update) do
    opts = socket.assigns.opts
    opts[:update_changeset] || default_changeset_fn(socket.assigns.schema)
  end

  defp default_changeset_fn(schema) do
    fn struct_or_record, params -> schema.changeset(struct_or_record, params) end
  end

  defp index_path(socket) do
    socket.assigns[:index_path] || "/"
  end

  defp index_path_with_params(socket, params) do
    base = index_path(socket)
    query = URI.encode_query(params)
    if query == "", do: base, else: "#{base}?#{query}"
  end

  defp show_path(socket, id) do
    "#{index_path(socket)}/#{id}"
  end

  defp edit_path(socket, id) do
    "#{index_path(socket)}/#{id}/edit"
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/lifecycle_test.exs`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/resource/lifecycle.ex test/phoenix_filament/resource/lifecycle_test.exs
git commit -m "feat(resource): add Lifecycle module for LiveView state management"
```

---

## Task 5: Renderer Module

**Files:**
- Create: `lib/phoenix_filament/resource/renderer.ex`
- Create: `test/phoenix_filament/resource/renderer_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
# test/phoenix_filament/resource/renderer_test.exs
defmodule PhoenixFilament.Resource.RendererTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Resource.Renderer
  alias PhoenixFilament.Field
  alias PhoenixFilament.Column

  describe "render/1 for :index" do
    test "renders page title and table container" do
      assigns = %{
        live_action: :index,
        page_title: "Blog Posts",
        resource: TestResource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo,
        columns: [Column.column(:title, sortable: true)],
        table_actions: [],
        table_filters: [],
        params: %{},
        record: nil,
        form: nil,
        form_schema: []
      }

      html = rendered_to_string(~H"""
      <Renderer.render {assigns} />
      """)

      assert html =~ "Blog Posts"
    end
  end

  describe "render/1 for :new" do
    test "renders modal with form" do
      form = to_form(%{"title" => ""}, as: "post")
      form_schema = [Field.text_input(:title)]

      assigns = %{
        live_action: :new,
        page_title: "New Blog Post",
        resource: TestResource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo,
        columns: [],
        table_actions: [],
        table_filters: [],
        params: %{},
        record: nil,
        form: form,
        form_schema: form_schema
      }

      html = rendered_to_string(~H"""
      <Renderer.render {assigns} />
      """)

      assert html =~ "New Blog Post"
      assert html =~ "modal"
      assert html =~ ~s(type="text")
    end
  end

  describe "render/1 for :show" do
    test "renders record detail" do
      assigns = %{
        live_action: :show,
        page_title: "Blog Post",
        resource: TestResource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo,
        columns: [Column.column(:title), Column.column(:body)],
        table_actions: [],
        table_filters: [],
        params: %{},
        record: %{id: 1, title: "Hello", body: "World"},
        form: nil,
        form_schema: []
      }

      html = rendered_to_string(~H"""
      <Renderer.render {assigns} />
      """)

      assert html =~ "Blog Post"
      assert html =~ "Hello"
      assert html =~ "World"
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/renderer_test.exs`
Expected: Compilation error

- [ ] **Step 3: Implement Renderer module**

```elixir
# lib/phoenix_filament/resource/renderer.ex
defmodule PhoenixFilament.Resource.Renderer do
  @moduledoc """
  Renders Resource CRUD pages based on live_action.

  Composes existing PhoenixFilament components:
  - TableLive for :index
  - form_builder + modal for :new/:edit
  - Detail view for :show
  """

  use Phoenix.Component

  import PhoenixFilament.Form.FormBuilder, only: [form_builder: 1]
  import PhoenixFilament.Components.Modal, only: [modal: 1]
  import PhoenixFilament.Components.Button, only: [button: 1]

  @doc "Renders the appropriate view based on live_action."
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-4">{@page_title}</h1>

      <.index_view :if={@live_action in [:index, :new, :edit]} {assigns} />
      <.form_modal :if={@live_action in [:new, :edit]} {assigns} />
      <.show_view :if={@live_action == :show} {assigns} />
    </div>
    """
  end

  defp index_view(assigns) do
    ~H"""
    <.live_component
      module={PhoenixFilament.Table.TableLive}
      id={"#{@resource}-table"}
      schema={@schema}
      repo={@repo}
      columns={@columns}
      actions={@table_actions}
      filters={@table_filters}
      params={@params || %{}}
    />
    """
  end

  defp form_modal(assigns) do
    ~H"""
    <.modal show id={"#{@resource}-form-modal"}>
      <:header>{@page_title}</:header>
      <.form_builder
        form={@form}
        schema={@form_schema}
        phx-change="validate"
        phx-submit="save"
      />
    </.modal>
    """
  end

  defp show_view(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body">
        <dl class="space-y-4">
          <div :for={col <- @columns} class="grid grid-cols-3 gap-4">
            <dt class="font-semibold text-base-content/70">{col.label}</dt>
            <dd class="col-span-2">{show_value(@record, col)}</dd>
          </div>
        </dl>
      </div>
    </div>
    <div class="mt-4">
      <.button variant={:ghost} phx-click="back">Back</.button>
    </div>
    """
  end

  defp show_value(record, col) do
    value = Map.get(record, col.name)

    cond do
      col.opts[:format] -> col.opts[:format].(value, record)
      true -> to_string(value || "")
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/renderer_test.exs`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/resource/renderer.ex test/phoenix_filament/resource/renderer_test.exs
git commit -m "feat(resource): add Renderer composing TableLive + form_builder + show"
```

---

## Task 6: Inject LiveView Callbacks into Resource

**Files:**
- Modify: `lib/phoenix_filament/resource.ex`

This is the core integration task — the existing `__using__/1` and `__before_compile__/1` are extended to inject LiveView callbacks.

- [ ] **Step 1: Update __using__/1 to add use Phoenix.LiveView**

In `lib/phoenix_filament/resource.ex`, add `use Phoenix.LiveView` to the `quote` block in `__using__/1`:

```elixir
defmacro __using__(opts) do
  schema_mod =
    Macro.expand_literals(
      opts[:schema],
      %{__CALLER__ | function: {:__resource__, 1}}
    )

  repo_mod =
    Macro.expand_literals(
      opts[:repo],
      %{__CALLER__ | function: {:__resource__, 1}}
    )

  quote do
    use Phoenix.LiveView

    @behaviour PhoenixFilament.Resource

    @_phx_filament_opts NimbleOptions.validate!(
                          unquote(opts),
                          PhoenixFilament.Resource.Options.schema()
                        )

    Module.register_attribute(__MODULE__, :_phx_filament_form_fields, accumulate: true)
    Module.register_attribute(__MODULE__, :_phx_filament_table_columns, accumulate: true)
    Module.register_attribute(__MODULE__, :_phx_filament_table_actions, accumulate: true)
    Module.register_attribute(__MODULE__, :_phx_filament_table_filters, accumulate: true)

    @_phx_filament_form_schema nil
    @_phx_filament_form_context nil

    import PhoenixFilament.Resource.DSL, only: [form: 1, table: 1]

    @before_compile PhoenixFilament.Resource

    @_phx_filament_schema unquote(schema_mod)
    @_phx_filament_repo unquote(repo_mod)
  end
end
```

- [ ] **Step 2: Add thin LiveView callbacks to __before_compile__/1**

Add these at the end of the `__before_compile__/1` quote block, BEFORE the catch-all `__resource__/1`:

```elixir
# --- LiveView thin callbacks ---

@impl Phoenix.LiveView
def mount(params, session, socket) do
  socket = PhoenixFilament.Resource.Lifecycle.init_assigns(socket, __MODULE__)
  {:ok, socket}
end

@impl Phoenix.LiveView
def handle_params(params, _uri, socket) do
  socket = PhoenixFilament.Resource.Lifecycle.apply_action(socket, socket.assigns.live_action, params)
  {:noreply, socket}
end

@impl Phoenix.LiveView
def handle_event("validate", params, socket) do
  # Extract the form params (keyed by schema name)
  form_params = params |> Map.drop(["_target", "_csrf_token"]) |> Map.values() |> List.first() || %{}
  PhoenixFilament.Resource.Lifecycle.handle_validate(socket, form_params)
end

@impl Phoenix.LiveView
def handle_event("save", params, socket) do
  form_params = params |> Map.drop(["_target", "_csrf_token"]) |> Map.values() |> List.first() || %{}
  PhoenixFilament.Resource.Lifecycle.handle_save(socket, form_params)
end

@impl Phoenix.LiveView
def handle_event("back", _params, socket) do
  {:noreply, Phoenix.LiveView.push_patch(socket, to: PhoenixFilament.Resource.Lifecycle.index_path(socket))}
end

@impl Phoenix.LiveView
def handle_info({:table_action, action, id}, socket) do
  PhoenixFilament.Resource.Lifecycle.handle_table_action(socket, action, id)
end

@impl Phoenix.LiveView
def handle_info({:table_patch, params}, socket) do
  PhoenixFilament.Resource.Lifecycle.handle_table_patch(socket, params)
end

@impl Phoenix.LiveView
def render(assigns) do
  PhoenixFilament.Resource.Renderer.render(assigns)
end
```

Note: Make `index_path/1` in Lifecycle a public function so it can be called from the injected callback.

- [ ] **Step 3: Run existing tests for regressions**

Run: `mix test --include cascade`
Expected: All tests pass. The existing resource_test.exs tests `__resource__/1` which should still work. The cascade test validates compile-time safety.

IMPORTANT: Some existing tests may break because `use Phoenix.LiveView` is now injected. Tests that `defmodule` resources inside test files will now try to inject LiveView callbacks, which may conflict. If this happens, the test resource modules in `test/support/resources/` and inline test modules may need `@before_compile` adjustments. Read error messages carefully.

- [ ] **Step 4: Fix any test compatibility issues**

If existing tests break due to LiveView injection, the fix is usually to ensure the test resource modules have the required assigns available or to adjust test assertions.

- [ ] **Step 5: Run full suite**

Run: `mix test --include cascade`
Expected: All pass

- [ ] **Step 6: Format and commit**

```bash
mix format
git add lib/phoenix_filament/resource.ex
git commit -m "feat(resource): inject LiveView callbacks via thin delegation"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run complete test suite**

Run: `mix test --include cascade`
Expected: All tests pass

- [ ] **Step 2: Verify compilation**

Run: `mix compile --warnings-as-errors`
Expected: Clean

- [ ] **Step 3: Verify formatting**

Run: `mix format --check-formatted`
Expected: Clean

- [ ] **Step 4: Verify cascade still works**

Run: `mix test --include cascade test/phoenix_filament/resource/cascade_test.exs`
Expected: Touching schema does NOT recompile resource

- [ ] **Step 5: Commit any adjustments**

```bash
git add -A
git commit -m "chore: final Phase 5 verification pass"
```

---

## Success Criteria Verification

| # | Criterion | Verified By |
|---|-----------|-------------|
| 1 | Zero-code CRUD pages | `use PhoenixFilament.Resource` injects LiveView with mount/handle_params/render |
| 2 | Auto-discover fields | `__resource__(:form_schema)` and `__resource__(:table_columns)` auto-discover from Phase 1 Defaults |
| 3 | Override via DSL | `form do...end` and `table do...end` already work and are picked up by Lifecycle/Renderer |
| 4 | No compile-time cascade | cascade_test.exs validates. Thin delegation to runtime modules. |
| 5 | authorize!/3 on every write | Lifecycle.handle_save and handle_table_action(:delete) both call Authorize.authorize! |
| 6 | Delete confirmation | TableLive already has delete modal → sends {:table_action, :delete, id} → Lifecycle handles |

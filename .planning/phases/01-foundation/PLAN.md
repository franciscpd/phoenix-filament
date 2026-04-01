# Phase 1: Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the PhoenixFilament Hex package with Ecto introspection, runtime DSL infrastructure (module attribute accumulation producing plain structs), and compile-time safety via `Macro.expand_literals/2`.

**Architecture:** Monolito Foundation — flat-by-domain namespace under `lib/phoenix_filament/`. Six source modules (`field.ex`, `column.ex`, `schema.ex`, `resource.ex`, `resource/dsl.ex`, `resource/defaults.ex`) plus test support schemas. Macros accumulate DATA (structs) not CODE. Thin delegation pattern: `__before_compile__` only defines `__resource__/1` accessor functions.

**Tech Stack:** Elixir 1.19+, Ecto ~> 3.11 (introspection only), NimbleOptions ~> 1.0, Phoenix.Naming (for label humanization)

---

## File Structure

### Source Files (create all)

| File | Responsibility |
|------|---------------|
| `mix.exs` | Hex package config, deps, project metadata |
| `.formatter.exs` | Code formatter config |
| `lib/phoenix_filament.ex` | Application module (minimal supervision tree) |
| `lib/phoenix_filament/field.ex` | `%Field{}` struct + constructor functions |
| `lib/phoenix_filament/column.ex` | `%Column{}` struct + constructor functions |
| `lib/phoenix_filament/schema.ex` | Ecto introspection API |
| `lib/phoenix_filament/resource.ex` | `__using__` macro + `__before_compile__` |
| `lib/phoenix_filament/resource/dsl.ex` | `form/1` and `table/1` block macros + field/column accumulator macros |
| `lib/phoenix_filament/resource/defaults.ex` | Auto-discovery: schema → default fields/columns |

### Test Files (create all)

| File | Responsibility |
|------|---------------|
| `test/test_helper.exs` | ExUnit config |
| `test/support/schemas/post.ex` | Simple schema (string, text, boolean, integer, belongs_to) |
| `test/support/schemas/user.ex` | Schema with has_many + sensitive fields |
| `test/support/schemas/comment.ex` | Schema with multiple belongs_to |
| `test/support/schemas/profile.ex` | Schema with embeds_one + virtual fields |
| `test/phoenix_filament/field_test.exs` | Field struct constructors and behavior |
| `test/phoenix_filament/column_test.exs` | Column struct constructors and behavior |
| `test/phoenix_filament/schema_test.exs` | Ecto introspection functions |
| `test/phoenix_filament/resource_test.exs` | Resource macro, NimbleOptions, DSL blocks |
| `test/phoenix_filament/resource/defaults_test.exs` | Auto-discovery from schemas |
| `test/phoenix_filament/resource/cascade_test.exs` | Compile-time independence validation |

---

## Task 1: Mix Project Scaffold

**Files:**
- Create: `mix.exs`
- Create: `.formatter.exs`
- Create: `lib/phoenix_filament.ex`
- Create: `test/test_helper.exs`

- [ ] **Step 1: Create `mix.exs`**

```elixir
defmodule PhoenixFilament.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/franciscpd/phoenix-filament"

  def project do
    [
      app: :phoenix_filament,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "PhoenixFilament",
      source_url: @source_url,
      description: "Rapid application development framework for Phoenix — declarative admin panels from Ecto schemas",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.11"},
      {:nimble_options, "~> 1.0"},
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:phoenix_html, "~> 4.1", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
```

- [ ] **Step 2: Create `.formatter.exs`**

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

- [ ] **Step 3: Create `lib/phoenix_filament.ex`**

```elixir
defmodule PhoenixFilament do
  @moduledoc """
  Rapid application development framework for Phoenix.

  PhoenixFilament provides declarative DSL-based builders for forms, tables,
  and CRUD resources — all powered by LiveView and styled with Tailwind CSS.
  """
end
```

- [ ] **Step 4: Create `test/test_helper.exs`**

```elixir
ExUnit.start()
```

- [ ] **Step 5: Install dependencies and verify compilation**

Run: `mix deps.get && mix compile`
Expected: Clean compilation with no warnings

- [ ] **Step 6: Run empty test suite**

Run: `mix test`
Expected: `0 tests, 0 failures`

- [ ] **Step 7: Commit**

```bash
git add mix.exs mix.lock .formatter.exs lib/phoenix_filament.ex test/test_helper.exs
git commit -m "chore: scaffold hex package with deps"
```

---

## Task 2: Test Support Schemas

**Files:**
- Create: `test/support/schemas/post.ex`
- Create: `test/support/schemas/user.ex`
- Create: `test/support/schemas/comment.ex`
- Create: `test/support/schemas/profile.ex`

These are Ecto schemas compiled only in test env (via `elixirc_paths`). They exist purely to test introspection — no database, no migrations, no repo.

- [ ] **Step 1: Create `test/support/schemas/post.ex`**

```elixir
defmodule PhoenixFilament.Test.Schemas.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body, :string
    field :views, :integer
    field :published, :boolean, default: false
    field :published_at, :naive_datetime

    belongs_to :author, PhoenixFilament.Test.Schemas.User

    timestamps()
  end
end
```

- [ ] **Step 2: Create `test/support/schemas/user.ex`**

```elixir
defmodule PhoenixFilament.Test.Schemas.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string
    field :confirmation_token, :string
    field :role, :string, default: "user"

    has_many :posts, PhoenixFilament.Test.Schemas.Post, foreign_key: :author_id
    has_many :comments, PhoenixFilament.Test.Schemas.Comment

    timestamps()
  end
end
```

- [ ] **Step 3: Create `test/support/schemas/comment.ex`**

```elixir
defmodule PhoenixFilament.Test.Schemas.Comment do
  use Ecto.Schema

  schema "comments" do
    field :body, :string

    belongs_to :post, PhoenixFilament.Test.Schemas.Post
    belongs_to :user, PhoenixFilament.Test.Schemas.User

    timestamps()
  end
end
```

- [ ] **Step 4: Create `test/support/schemas/profile.ex`**

```elixir
defmodule PhoenixFilament.Test.Schemas.Address do
  use Ecto.Schema

  embedded_schema do
    field :street, :string
    field :city, :string
    field :zip, :string
  end
end

defmodule PhoenixFilament.Test.Schemas.Profile do
  use Ecto.Schema

  schema "profiles" do
    field :bio, :string
    field :display_name, :string, virtual: true
    field :age, :integer, virtual: true

    embeds_one :address, PhoenixFilament.Test.Schemas.Address

    belongs_to :user, PhoenixFilament.Test.Schemas.User

    timestamps()
  end
end
```

- [ ] **Step 5: Verify schemas compile**

Run: `mix compile`
Expected: Clean compilation, no warnings

- [ ] **Step 6: Commit**

```bash
git add test/support/schemas/
git commit -m "test: add ecto schemas for introspection testing"
```

---

## Task 3: `%PhoenixFilament.Field{}` Struct

**Files:**
- Create: `test/phoenix_filament/field_test.exs`
- Create: `lib/phoenix_filament/field.ex`

- [ ] **Step 1: Write failing tests**

```elixir
defmodule PhoenixFilament.FieldTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Field

  describe "new/3" do
    test "creates a field struct with name, type, and default label" do
      field = Field.new(:title, :text_input, [])

      assert %Field{} = field
      assert field.name == :title
      assert field.type == :text_input
      assert field.label == "Title"
      assert field.opts == []
    end

    test "auto-humanizes multi-word atom names" do
      field = Field.new(:published_at, :datetime, [])

      assert field.label == "Published at"
    end

    test "custom label overrides auto-humanized label" do
      field = Field.new(:title, :text_input, label: "Post Title")

      assert field.label == "Post Title"
    end

    test "preserves opts in the struct" do
      opts = [required: true, placeholder: "Enter title", max_length: 255]
      field = Field.new(:title, :text_input, opts)

      assert field.opts == opts
    end
  end

  describe "constructor functions" do
    test "text_input/2 creates a :text_input field" do
      field = Field.text_input(:name, required: true)

      assert field.type == :text_input
      assert field.name == :name
      assert field.opts == [required: true]
    end

    test "textarea/2 creates a :textarea field" do
      field = Field.textarea(:body, rows: 5)

      assert field.type == :textarea
      assert field.opts == [rows: 5]
    end

    test "number_input/2 creates a :number_input field" do
      field = Field.number_input(:age, min: 0, max: 150)

      assert field.type == :number_input
    end

    test "select/2 creates a :select field" do
      field = Field.select(:role, options: ~w(admin user))

      assert field.type == :select
      assert field.opts == [options: ~w(admin user)]
    end

    test "checkbox/2 creates a :checkbox field" do
      field = Field.checkbox(:agree)

      assert field.type == :checkbox
    end

    test "toggle/2 creates a :toggle field" do
      field = Field.toggle(:published)

      assert field.type == :toggle
    end

    test "date/2 creates a :date field" do
      field = Field.date(:birthday)

      assert field.type == :date
    end

    test "datetime/2 creates a :datetime field" do
      field = Field.datetime(:published_at)

      assert field.type == :datetime
    end

    test "hidden/2 creates a :hidden field" do
      field = Field.hidden(:secret_id)

      assert field.type == :hidden
    end

    test "constructors with no opts default to empty list" do
      field = Field.text_input(:name)

      assert field.opts == []
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/field_test.exs`
Expected: FAIL — `PhoenixFilament.Field` module not found

- [ ] **Step 3: Implement `lib/phoenix_filament/field.ex`**

```elixir
defmodule PhoenixFilament.Field do
  @moduledoc """
  A plain data struct representing a form field declaration.

  Each field has a name (matching an Ecto schema field), a type
  that determines which input component renders it, an auto-humanized
  label, and a keyword list of type-specific options.

  ## Supported Field Types

    * `:text_input` — single-line text input
    * `:textarea` — multi-line text input (opts: `rows`)
    * `:number_input` — numeric input (opts: `min`, `max`, `step`)
    * `:select` — dropdown select (opts: `options`)
    * `:checkbox` — boolean checkbox
    * `:toggle` — boolean toggle switch
    * `:date` — date picker
    * `:datetime` — datetime picker
    * `:hidden` — hidden field

  ## Common Options

    * `required: true` — UI hint only (shows asterisk). Real validation is in Ecto changeset.
    * `label: "Custom"` — overrides auto-humanized label
    * `placeholder: "..."` — placeholder text
  """

  @type field_type ::
          :text_input
          | :textarea
          | :number_input
          | :select
          | :checkbox
          | :toggle
          | :date
          | :datetime
          | :hidden

  @type t :: %__MODULE__{
          name: atom(),
          type: field_type(),
          label: String.t() | nil,
          opts: keyword()
        }

  defstruct [:name, :type, :label, opts: []]

  @doc "Creates a new Field struct. Label is auto-humanized from `name` unless provided in `opts`."
  @spec new(atom(), field_type(), keyword()) :: t()
  def new(name, type, opts) do
    {label, opts} = Keyword.pop(opts, :label)
    label = label || humanize(name)
    %__MODULE__{name: name, type: type, label: label, opts: opts}
  end

  @doc "Creates a `:text_input` field."
  @spec text_input(atom(), keyword()) :: t()
  def text_input(name, opts \\ []), do: new(name, :text_input, opts)

  @doc "Creates a `:textarea` field."
  @spec textarea(atom(), keyword()) :: t()
  def textarea(name, opts \\ []), do: new(name, :textarea, opts)

  @doc "Creates a `:number_input` field."
  @spec number_input(atom(), keyword()) :: t()
  def number_input(name, opts \\ []), do: new(name, :number_input, opts)

  @doc "Creates a `:select` field."
  @spec select(atom(), keyword()) :: t()
  def select(name, opts \\ []), do: new(name, :select, opts)

  @doc "Creates a `:checkbox` field."
  @spec checkbox(atom(), keyword()) :: t()
  def checkbox(name, opts \\ []), do: new(name, :checkbox, opts)

  @doc "Creates a `:toggle` field."
  @spec toggle(atom(), keyword()) :: t()
  def toggle(name, opts \\ []), do: new(name, :toggle, opts)

  @doc "Creates a `:date` field."
  @spec date(atom(), keyword()) :: t()
  def date(name, opts \\ []), do: new(name, :date, opts)

  @doc "Creates a `:datetime` field."
  @spec datetime(atom(), keyword()) :: t()
  def datetime(name, opts \\ []), do: new(name, :datetime, opts)

  @doc "Creates a `:hidden` field."
  @spec hidden(atom(), keyword()) :: t()
  def hidden(name, opts \\ []), do: new(name, :hidden, opts)

  defp humanize(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/field_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/field.ex test/phoenix_filament/field_test.exs
git commit -m "feat: add Field struct with constructor functions"
```

---

## Task 4: `%PhoenixFilament.Column{}` Struct

**Files:**
- Create: `test/phoenix_filament/column_test.exs`
- Create: `lib/phoenix_filament/column.ex`

- [ ] **Step 1: Write failing tests**

```elixir
defmodule PhoenixFilament.ColumnTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Column

  describe "column/2" do
    test "creates a column struct with name and auto-humanized label" do
      col = Column.column(:title, [])

      assert %Column{} = col
      assert col.name == :title
      assert col.label == "Title"
      assert col.opts == []
    end

    test "auto-humanizes multi-word atom names" do
      col = Column.column(:published_at, [])

      assert col.label == "Published at"
    end

    test "custom label overrides auto-humanized label" do
      col = Column.column(:title, label: "Post Title")

      assert col.label == "Post Title"
    end

    test "preserves opts" do
      opts = [sortable: true, searchable: true, badge: true]
      col = Column.column(:status, opts)

      assert col.opts == opts
    end

    test "default opts is empty list" do
      col = Column.column(:title)

      assert col.opts == []
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/column_test.exs`
Expected: FAIL — `PhoenixFilament.Column` module not found

- [ ] **Step 3: Implement `lib/phoenix_filament/column.ex`**

```elixir
defmodule PhoenixFilament.Column do
  @moduledoc """
  A plain data struct representing a table column declaration.

  Each column has a name (matching an Ecto schema field), an auto-humanized
  label, and a keyword list of options controlling display and behavior.

  ## Supported Options

    * `sortable: true` — enable column header sorting
    * `searchable: true` — include in global text search
    * `format: fn value, row -> ... end` — custom cell formatting
    * `badge: true` — render cell value as a badge component
    * `visible: false` — hide column by default
    * `preload: :association_name` — preload association for this column
  """

  @type t :: %__MODULE__{
          name: atom(),
          label: String.t() | nil,
          opts: keyword()
        }

  defstruct [:name, :label, opts: []]

  @doc "Creates a new Column struct. Label is auto-humanized from `name` unless provided in `opts`."
  @spec column(atom(), keyword()) :: t()
  def column(name, opts \\ []) do
    {label, opts} = Keyword.pop(opts, :label)
    label = label || humanize(name)
    %__MODULE__{name: name, label: label, opts: opts}
  end

  defp humanize(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/column_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/column.ex test/phoenix_filament/column_test.exs
git commit -m "feat: add Column struct with constructor function"
```

---

## Task 5: `PhoenixFilament.Schema` — Ecto Introspection

**Files:**
- Create: `test/phoenix_filament/schema_test.exs`
- Create: `lib/phoenix_filament/schema.ex`

- [ ] **Step 1: Write failing tests**

```elixir
defmodule PhoenixFilament.SchemaTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Schema
  alias PhoenixFilament.Test.Schemas.{Post, User, Comment, Profile}

  describe "fields/1" do
    test "returns all non-virtual fields with types" do
      fields = Schema.fields(Post)

      assert is_list(fields)
      title_field = Enum.find(fields, &(&1.name == :title))
      assert title_field.type == :string

      views_field = Enum.find(fields, &(&1.name == :views))
      assert views_field.type == :integer

      published_field = Enum.find(fields, &(&1.name == :published))
      assert published_field.type == :boolean
    end

    test "includes foreign key fields" do
      fields = Schema.fields(Post)
      author_id = Enum.find(fields, &(&1.name == :author_id))

      assert author_id != nil
      assert author_id.type == :id
    end

    test "includes id and timestamps" do
      fields = Schema.fields(Post)
      names = Enum.map(fields, & &1.name)

      assert :id in names
      assert :inserted_at in names
      assert :updated_at in names
    end
  end

  describe "associations/1" do
    test "returns belongs_to associations" do
      assocs = Schema.associations(Post)
      author = Enum.find(assocs, &(&1.name == :author))

      assert author != nil
      assert author.type == :belongs_to
      assert author.related == User
    end

    test "returns has_many associations" do
      assocs = Schema.associations(User)
      posts = Enum.find(assocs, &(&1.name == :posts))

      assert posts != nil
      assert posts.type == :has_many
      assert posts.related == Post
    end

    test "returns multiple associations" do
      assocs = Schema.associations(Comment)

      assert length(assocs) == 2
      names = Enum.map(assocs, & &1.name)
      assert :post in names
      assert :user in names
    end
  end

  describe "embeds/1" do
    test "returns embeds_one" do
      embeds = Schema.embeds(Profile)
      address = Enum.find(embeds, &(&1.name == :address))

      assert address != nil
      assert address.cardinality == :one
      assert address.related == PhoenixFilament.Test.Schemas.Address
    end

    test "returns empty list for schemas without embeds" do
      assert Schema.embeds(Post) == []
    end
  end

  describe "virtual_fields/1" do
    test "returns virtual fields with types" do
      virtuals = Schema.virtual_fields(Profile)
      names = Enum.map(virtuals, & &1.name)

      assert :display_name in names
      assert :age in names
    end

    test "returns empty list for schemas without virtual fields" do
      assert Schema.virtual_fields(Post) == []
    end
  end

  describe "visible_fields/1" do
    test "excludes id" do
      fields = Schema.visible_fields(Post)
      names = Enum.map(fields, & &1.name)

      refute :id in names
    end

    test "excludes timestamps" do
      fields = Schema.visible_fields(Post)
      names = Enum.map(fields, & &1.name)

      refute :inserted_at in names
      refute :updated_at in names
    end

    test "excludes fields ending in _hash" do
      fields = Schema.visible_fields(User)
      names = Enum.map(fields, & &1.name)

      refute :password_hash in names
    end

    test "excludes fields ending in _token" do
      fields = Schema.visible_fields(User)
      names = Enum.map(fields, & &1.name)

      refute :confirmation_token in names
    end

    test "excludes foreign key fields" do
      fields = Schema.visible_fields(Post)
      names = Enum.map(fields, & &1.name)

      refute :author_id in names
    end

    test "keeps regular business fields" do
      fields = Schema.visible_fields(Post)
      names = Enum.map(fields, & &1.name)

      assert :title in names
      assert :body in names
      assert :views in names
      assert :published in names
      assert :published_at in names
    end
  end

  describe "type_to_field_type/1" do
    test "maps string to text_input" do
      assert Schema.type_to_field_type(:string) == :text_input
    end

    test "maps integer to number_input" do
      assert Schema.type_to_field_type(:integer) == :number_input
    end

    test "maps float to number_input" do
      assert Schema.type_to_field_type(:float) == :number_input
    end

    test "maps boolean to toggle" do
      assert Schema.type_to_field_type(:boolean) == :toggle
    end

    test "maps date to date" do
      assert Schema.type_to_field_type(:date) == :date
    end

    test "maps naive_datetime to datetime" do
      assert Schema.type_to_field_type(:naive_datetime) == :datetime
    end

    test "maps utc_datetime to datetime" do
      assert Schema.type_to_field_type(:utc_datetime) == :datetime
    end

    test "maps unknown types to text_input as fallback" do
      assert Schema.type_to_field_type(:binary) == :text_input
      assert Schema.type_to_field_type(:map) == :text_input
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/schema_test.exs`
Expected: FAIL — `PhoenixFilament.Schema` module not found

- [ ] **Step 3: Implement `lib/phoenix_filament/schema.ex`**

```elixir
defmodule PhoenixFilament.Schema do
  @moduledoc """
  Introspects Ecto schemas at runtime to extract field metadata,
  associations, embeds, and virtual fields.

  All functions use `__schema__/1` at runtime — no compile-time
  dependency is created on the schema module.
  """

  @excluded_fields [:id, :inserted_at, :updated_at]
  @excluded_suffixes ["_hash", "_digest", "_token"]

  @doc "Returns all non-virtual fields with their Ecto types."
  @spec fields(module()) :: [%{name: atom(), type: atom()}]
  def fields(schema) do
    ensure_schema!(schema)

    schema.__schema__(:fields)
    |> Enum.map(fn name ->
      %{name: name, type: schema.__schema__(:type, name)}
    end)
  end

  @doc "Returns all associations (belongs_to, has_many, has_one) with related module."
  @spec associations(module()) :: [%{name: atom(), type: atom(), related: module()}]
  def associations(schema) do
    ensure_schema!(schema)

    schema.__schema__(:associations)
    |> Enum.map(fn name ->
      assoc = schema.__schema__(:association, name)
      %{name: name, type: assoc.relationship, related: assoc.queryable}
    end)
  end

  @doc "Returns all embeds (embeds_one, embeds_many) with cardinality and related module."
  @spec embeds(module()) :: [%{name: atom(), cardinality: :one | :many, related: module()}]
  def embeds(schema) do
    ensure_schema!(schema)

    schema.__schema__(:embeds)
    |> Enum.map(fn name ->
      embed = schema.__schema__(:embed, name)
      %{name: name, cardinality: embed.cardinality, related: embed.related}
    end)
  end

  @doc "Returns all virtual fields with their types."
  @spec virtual_fields(module()) :: [%{name: atom(), type: atom()}]
  def virtual_fields(schema) do
    ensure_schema!(schema)

    schema.__schema__(:virtual_fields)
    |> Enum.map(fn name ->
      %{name: name, type: schema.__schema__(:virtual_type, name)}
    end)
  end

  @doc """
  Returns visible fields for auto-discovery.

  Excludes: `id`, timestamps (`inserted_at`, `updated_at`), foreign keys
  (ending in `_id`), and sensitive fields (ending in `_hash`, `_digest`, `_token`).
  """
  @spec visible_fields(module()) :: [%{name: atom(), type: atom()}]
  def visible_fields(schema) do
    fields(schema)
    |> Enum.reject(fn %{name: name} -> excluded_field?(name) end)
  end

  @doc "Maps an Ecto type to a default form field type."
  @spec type_to_field_type(atom()) :: PhoenixFilament.Field.field_type()
  def type_to_field_type(:string), do: :text_input
  def type_to_field_type(:integer), do: :number_input
  def type_to_field_type(:float), do: :number_input
  def type_to_field_type(:decimal), do: :number_input
  def type_to_field_type(:boolean), do: :toggle
  def type_to_field_type(:date), do: :date
  def type_to_field_type(:time), do: :text_input
  def type_to_field_type(:naive_datetime), do: :datetime
  def type_to_field_type(:naive_datetime_usec), do: :datetime
  def type_to_field_type(:utc_datetime), do: :datetime
  def type_to_field_type(:utc_datetime_usec), do: :datetime
  def type_to_field_type(_), do: :text_input

  defp excluded_field?(name) do
    name_str = Atom.to_string(name)

    name in @excluded_fields or
      String.ends_with?(name_str, "_id") or
      Enum.any?(@excluded_suffixes, &String.ends_with?(name_str, &1))
  end

  defp ensure_schema!(schema) do
    Code.ensure_loaded!(schema)

    unless function_exported?(schema, :__schema__, 1) do
      raise ArgumentError,
            "#{inspect(schema)} is not an Ecto schema. " <>
              "Expected a module that uses Ecto.Schema."
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/schema_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/schema.ex test/phoenix_filament/schema_test.exs
git commit -m "feat: add Ecto schema introspection API"
```

---

## Task 6: `PhoenixFilament.Resource` — `__using__` Macro + NimbleOptions

**Files:**
- Create: `lib/phoenix_filament/resource.ex`
- Create: `test/phoenix_filament/resource_test.exs`

This task implements only the `__using__` macro with NimbleOptions validation and `__before_compile__` with `__resource__/1`. DSL blocks are wired in Task 7.

- [ ] **Step 1: Write failing tests**

```elixir
defmodule PhoenixFilament.ResourceTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Test.Schemas.Post

  describe "__using__ macro with NimbleOptions" do
    test "valid options compile without errors" do
      defmodule ValidResource do
        use PhoenixFilament.Resource,
          schema: PhoenixFilament.Test.Schemas.Post,
          repo: PhoenixFilament.Test.FakeRepo
      end

      assert ValidResource.__resource__(:schema) == Post
    end

    test "missing :schema raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/required :schema option/, fn ->
        defmodule BadResource1 do
          use PhoenixFilament.Resource, repo: SomeRepo
        end
      end
    end

    test "missing :repo raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/required :repo option/, fn ->
        defmodule BadResource2 do
          use PhoenixFilament.Resource, schema: SomeSchema
        end
      end
    end

    test "unknown option raises NimbleOptions error" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options/, fn ->
        defmodule BadResource3 do
          use PhoenixFilament.Resource,
            schema: SomeSchema,
            repo: SomeRepo,
            bogus: true
        end
      end
    end
  end

  describe "__resource__/1 accessors" do
    defmodule TestResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo,
        label: "Blog Post",
        icon: "document"
    end

    test "returns schema module" do
      assert TestResource.__resource__(:schema) == Post
    end

    test "returns repo module" do
      assert TestResource.__resource__(:repo) == PhoenixFilament.Test.FakeRepo
    end

    test "returns validated options" do
      opts = TestResource.__resource__(:opts)

      assert opts[:label] == "Blog Post"
      assert opts[:icon] == "document"
    end

    test "returns form_fields (auto-discovered since no form block)" do
      fields = TestResource.__resource__(:form_fields)

      assert is_list(fields)
      assert length(fields) > 0
      assert Enum.all?(fields, &match?(%PhoenixFilament.Field{}, &1))
    end

    test "returns table_columns (auto-discovered since no table block)" do
      columns = TestResource.__resource__(:table_columns)

      assert is_list(columns)
      assert length(columns) > 0
      assert Enum.all?(columns, &match?(%PhoenixFilament.Column{}, &1))
    end
  end
end
```

- [ ] **Step 2: Create `test/support/fake_repo.ex` (stub module)**

```elixir
defmodule PhoenixFilament.Test.FakeRepo do
  @moduledoc false
  # Stub module — just needs to exist for NimbleOptions :atom validation.
  # No actual repo behavior needed in Phase 1.
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource_test.exs`
Expected: FAIL — `PhoenixFilament.Resource` module not found

- [ ] **Step 4: Create `lib/phoenix_filament/resource/options.ex`** (needed by Resource macro)

```elixir
defmodule PhoenixFilament.Resource.Options do
  @moduledoc false

  @schema NimbleOptions.new!([
    schema: [type: :atom, required: true, doc: "The Ecto schema module"],
    repo: [type: :atom, required: true, doc: "The Ecto repo module"],
    label: [type: :string, doc: "Human-readable resource name (auto-derived from schema if omitted)"],
    plural_label: [type: :string, doc: "Plural form of label"],
    icon: [type: :string, doc: "Icon name for panel navigation"]
  ])

  def schema, do: @schema
end
```

- [ ] **Step 5: Implement `lib/phoenix_filament/resource.ex`**

```elixir
defmodule PhoenixFilament.Resource do
  @moduledoc """
  Declares an admin resource backed by an Ecto schema.

  ## Usage

      defmodule MyApp.Admin.PostResource do
        use PhoenixFilament.Resource,
          schema: MyApp.Blog.Post,
          repo: MyApp.Repo
      end

  ## Options

  #{NimbleOptions.docs(PhoenixFilament.Resource.Options.schema())}
  """

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
      @_phx_filament_opts NimbleOptions.validate!(
                            unquote(opts),
                            PhoenixFilament.Resource.Options.schema()
                          )

      Module.register_attribute(__MODULE__, :_phx_filament_form_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :_phx_filament_table_columns, accumulate: true)

      import PhoenixFilament.Resource.DSL, only: [form: 1, table: 1]

      @before_compile PhoenixFilament.Resource

      @_phx_filament_schema unquote(schema_mod)
      @_phx_filament_repo unquote(repo_mod)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __resource__(:schema), do: @_phx_filament_schema
      def __resource__(:repo), do: @_phx_filament_repo
      def __resource__(:opts), do: @_phx_filament_opts

      def __resource__(:form_fields) do
        case @_phx_filament_form_fields |> Enum.reverse() do
          [] -> PhoenixFilament.Resource.Defaults.form_fields(@_phx_filament_schema)
          fields -> fields
        end
      end

      def __resource__(:table_columns) do
        case @_phx_filament_table_columns |> Enum.reverse() do
          [] -> PhoenixFilament.Resource.Defaults.table_columns(@_phx_filament_schema)
          columns -> columns
        end
      end
    end
  end
end
```

- [ ] **Step 6: Create stub `lib/phoenix_filament/resource/dsl.ex`** (full implementation in Task 7)

```elixir
defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  defmacro form(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro table(do: block) do
    quote do
      unquote(block)
    end
  end
end
```

- [ ] **Step 7: Create stub `lib/phoenix_filament/resource/defaults.ex`** (full implementation in Task 8)

```elixir
defmodule PhoenixFilament.Resource.Defaults do
  @moduledoc false

  def form_fields(schema) do
    Code.ensure_loaded!(schema)

    PhoenixFilament.Schema.visible_fields(schema)
    |> Enum.map(fn %{name: name, type: ecto_type} ->
      field_type = PhoenixFilament.Schema.type_to_field_type(ecto_type)
      PhoenixFilament.Field.new(name, field_type, [])
    end)
  end

  def table_columns(schema) do
    Code.ensure_loaded!(schema)

    PhoenixFilament.Schema.visible_fields(schema)
    |> Enum.map(fn %{name: name} ->
      PhoenixFilament.Column.column(name, sortable: true)
    end)
  end
end
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource_test.exs`
Expected: All tests pass

- [ ] **Step 9: Commit**

```bash
git add lib/phoenix_filament/resource.ex lib/phoenix_filament/resource/options.ex lib/phoenix_filament/resource/dsl.ex lib/phoenix_filament/resource/defaults.ex test/phoenix_filament/resource_test.exs test/support/fake_repo.ex
git commit -m "feat: add Resource macro with NimbleOptions and auto-discovery"
```

---

## Task 7: `PhoenixFilament.Resource.DSL` — Form/Table Block Macros

**Files:**
- Modify: `lib/phoenix_filament/resource/dsl.ex`
- Create: `test/phoenix_filament/resource/dsl_test.exs`

- [ ] **Step 1: Write failing tests**

```elixir
defmodule PhoenixFilament.Resource.DSLTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.{Field, Column}

  describe "form block accumulation" do
    defmodule FormResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input :title, required: true, placeholder: "Enter title"
        textarea :body, rows: 5
        toggle :published
        select :status, options: ~w(draft published archived)
      end
    end

    test "accumulates fields in declaration order" do
      fields = FormResource.__resource__(:form_fields)

      assert length(fields) == 4
      assert [%Field{name: :title}, %Field{name: :body}, %Field{name: :published}, %Field{name: :status}] = fields
    end

    test "fields have correct types" do
      fields = FormResource.__resource__(:form_fields)

      assert Enum.at(fields, 0).type == :text_input
      assert Enum.at(fields, 1).type == :textarea
      assert Enum.at(fields, 2).type == :toggle
      assert Enum.at(fields, 3).type == :select
    end

    test "fields preserve opts" do
      fields = FormResource.__resource__(:form_fields)

      title = Enum.at(fields, 0)
      assert title.opts[:required] == true
      assert title.opts[:placeholder] == "Enter title"

      body = Enum.at(fields, 1)
      assert body.opts[:rows] == 5
    end

    test "fields have auto-humanized labels" do
      fields = FormResource.__resource__(:form_fields)

      assert Enum.at(fields, 0).label == "Title"
      assert Enum.at(fields, 2).label == "Published"
    end
  end

  describe "table block accumulation" do
    defmodule TableResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      table do
        column :title, sortable: true
        column :published, badge: true
        column :inserted_at, label: "Created"
      end
    end

    test "accumulates columns in declaration order" do
      columns = TableResource.__resource__(:table_columns)

      assert length(columns) == 3
      assert [%Column{name: :title}, %Column{name: :published}, %Column{name: :inserted_at}] = columns
    end

    test "columns preserve opts" do
      columns = TableResource.__resource__(:table_columns)

      assert Enum.at(columns, 0).opts[:sortable] == true
      assert Enum.at(columns, 1).opts[:badge] == true
    end

    test "columns support custom labels" do
      columns = TableResource.__resource__(:table_columns)

      assert Enum.at(columns, 2).label == "Created"
    end
  end

  describe "mixed form and table blocks" do
    defmodule MixedResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input :title
        textarea :body
      end

      table do
        column :title, sortable: true
      end
    end

    test "form block fields are independent from table columns" do
      fields = MixedResource.__resource__(:form_fields)
      columns = MixedResource.__resource__(:table_columns)

      assert length(fields) == 2
      assert length(columns) == 1
    end
  end

  describe "partial override" do
    defmodule FormOnlyResource do
      use PhoenixFilament.Resource,
        schema: PhoenixFilament.Test.Schemas.Post,
        repo: PhoenixFilament.Test.FakeRepo

      form do
        text_input :title
      end

      # No table block — should auto-discover
    end

    test "custom form with auto-discovered table" do
      fields = FormOnlyResource.__resource__(:form_fields)
      columns = FormOnlyResource.__resource__(:table_columns)

      # Custom form: only 1 field
      assert length(fields) == 1
      assert hd(fields).name == :title

      # Auto-discovered table: multiple columns from schema
      assert length(columns) > 1
      assert Enum.all?(columns, &match?(%Column{}, &1))
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mix test test/phoenix_filament/resource/dsl_test.exs`
Expected: FAIL — field macros like `text_input` not available inside `form do...end`

- [ ] **Step 3: Implement full `lib/phoenix_filament/resource/dsl.ex`**

```elixir
defmodule PhoenixFilament.Resource.DSL do
  @moduledoc false

  @doc false
  defmacro form(do: block) do
    quote do
      import PhoenixFilament.Resource.DSL.FormFields
      unquote(block)
      import PhoenixFilament.Resource.DSL.FormFields, only: []
    end
  end

  @doc false
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

  defmacro text_input(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.text_input(unquote(name), unquote(opts))
    end
  end

  defmacro textarea(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.textarea(unquote(name), unquote(opts))
    end
  end

  defmacro number_input(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.number_input(unquote(name), unquote(opts))
    end
  end

  defmacro select(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.select(unquote(name), unquote(opts))
    end
  end

  defmacro checkbox(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.checkbox(unquote(name), unquote(opts))
    end
  end

  defmacro toggle(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.toggle(unquote(name), unquote(opts))
    end
  end

  defmacro date(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.date(unquote(name), unquote(opts))
    end
  end

  defmacro datetime(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.datetime(unquote(name), unquote(opts))
    end
  end

  defmacro hidden(name, opts \\ []) do
    quote do
      @_phx_filament_form_fields PhoenixFilament.Field.hidden(unquote(name), unquote(opts))
    end
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

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test test/phoenix_filament/resource/dsl_test.exs`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/phoenix_filament/resource/dsl.ex test/phoenix_filament/resource/dsl_test.exs
git commit -m "feat: add DSL block macros for form and table field accumulation"
```

---

## Task 8: `PhoenixFilament.Resource.Defaults` — Auto-Discovery Tests

**Files:**
- Create: `test/phoenix_filament/resource/defaults_test.exs`
- Verify: `lib/phoenix_filament/resource/defaults.ex` (already implemented in Task 6)

- [ ] **Step 1: Write tests for auto-discovery**

```elixir
defmodule PhoenixFilament.Resource.DefaultsTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.{Field, Column}
  alias PhoenixFilament.Resource.Defaults
  alias PhoenixFilament.Test.Schemas.{Post, User}

  describe "form_fields/1" do
    test "generates fields from schema visible fields" do
      fields = Defaults.form_fields(Post)

      assert is_list(fields)
      assert length(fields) > 0
      assert Enum.all?(fields, &match?(%Field{}, &1))
    end

    test "maps string fields to text_input" do
      fields = Defaults.form_fields(Post)
      title = Enum.find(fields, &(&1.name == :title))

      assert title.type == :text_input
    end

    test "maps boolean fields to toggle" do
      fields = Defaults.form_fields(Post)
      published = Enum.find(fields, &(&1.name == :published))

      assert published.type == :toggle
    end

    test "maps integer fields to number_input" do
      fields = Defaults.form_fields(Post)
      views = Enum.find(fields, &(&1.name == :views))

      assert views.type == :number_input
    end

    test "maps naive_datetime to datetime" do
      fields = Defaults.form_fields(Post)
      pub_at = Enum.find(fields, &(&1.name == :published_at))

      assert pub_at.type == :datetime
    end

    test "excludes sensitive fields from User schema" do
      fields = Defaults.form_fields(User)
      names = Enum.map(fields, & &1.name)

      refute :password_hash in names
      refute :confirmation_token in names
    end

    test "auto-humanizes labels" do
      fields = Defaults.form_fields(Post)
      pub_at = Enum.find(fields, &(&1.name == :published_at))

      assert pub_at.label == "Published at"
    end
  end

  describe "table_columns/1" do
    test "generates columns from schema visible fields" do
      columns = Defaults.table_columns(Post)

      assert is_list(columns)
      assert length(columns) > 0
      assert Enum.all?(columns, &match?(%Column{}, &1))
    end

    test "all columns are sortable by default" do
      columns = Defaults.table_columns(Post)

      assert Enum.all?(columns, fn col -> col.opts[:sortable] == true end)
    end

    test "excludes sensitive fields from User schema" do
      columns = Defaults.table_columns(User)
      names = Enum.map(columns, & &1.name)

      refute :password_hash in names
      refute :confirmation_token in names
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they pass** (implementation already exists from Task 6)

Run: `mix test test/phoenix_filament/resource/defaults_test.exs`
Expected: All tests pass (Defaults was already implemented as a non-stub in Task 6)

- [ ] **Step 3: Commit**

```bash
git add test/phoenix_filament/resource/defaults_test.exs
git commit -m "test: add auto-discovery defaults tests"
```

---

## Task 9: Compile-Time Cascade Validation

**Files:**
- Create: `test/phoenix_filament/resource/cascade_test.exs`

This test validates the critical success criterion: touching an Ecto schema does NOT recompile the resource module.

- [ ] **Step 1: Write the cascade test**

```elixir
defmodule PhoenixFilament.Resource.CascadeTest do
  use ExUnit.Case

  @moduletag :cascade

  @tag timeout: 60_000
  test "touching schema file does not recompile resource module" do
    # This test validates success criterion #3:
    # "use PhoenixFilament.Resource injects the DSL macro blocks without causing
    #  compile-time cascades when the referenced schema changes"

    project_root = File.cwd!()
    schema_path = Path.join(project_root, "test/support/schemas/post.ex")
    resource_path = Path.join(project_root, "test/support/resources/cascade_resource.ex")

    # Ensure the resource module exists
    assert File.exists?(resource_path),
           "Missing test/support/resources/cascade_resource.ex — create it first"

    # Step 1: Full compile to establish baseline
    {_, 0} = System.cmd("mix", ["compile", "--force"], cd: project_root, stderr_to_stdout: true)

    # Step 2: Touch the schema file (simulate a change)
    File.touch!(schema_path)

    # Step 3: Recompile and capture output
    {output, 0} = System.cmd("mix", ["compile"], cd: project_root, stderr_to_stdout: true)

    # Step 4: Assert the resource module was NOT recompiled
    # mix compile lists recompiled modules in its output
    refute output =~ "PhoenixFilament.Test.Resources.CascadeResource",
           """
           Compile-time cascade detected!

           Touching #{schema_path} caused CascadeResource to recompile.
           This means Macro.expand_literals/2 is not properly preventing
           compile-time dependencies.

           mix compile output:
           #{output}
           """
  end
end
```

- [ ] **Step 2: Create the cascade test resource**

Create `test/support/resources/cascade_resource.ex`:

```elixir
defmodule PhoenixFilament.Test.Resources.CascadeResource do
  use PhoenixFilament.Resource,
    schema: PhoenixFilament.Test.Schemas.Post,
    repo: PhoenixFilament.Test.FakeRepo

  form do
    text_input :title, required: true
    textarea :body
    toggle :published
  end

  table do
    column :title, sortable: true
    column :published, badge: true
  end
end
```

- [ ] **Step 3: Run the cascade test**

Run: `mix test test/phoenix_filament/resource/cascade_test.exs --include cascade`
Expected: PASS — CascadeResource does NOT appear in recompile output

If this test FAILS, it means `Macro.expand_literals/2` is not correctly preventing the compile-time dependency. Debug by running `mix xref trace test/support/resources/cascade_resource.ex` to see which dependencies are compile-time vs runtime.

- [ ] **Step 4: Commit**

```bash
git add test/phoenix_filament/resource/cascade_test.exs test/support/resources/cascade_resource.ex
git commit -m "test: add compile-time cascade prevention validation"
```

---

## Task 10: Full Integration Test + Final Verification

**Files:**
- Verify all existing tests pass together
- Run formatter

- [ ] **Step 1: Run the complete test suite**

Run: `mix test`
Expected: All tests pass

- [ ] **Step 2: Run the cascade test explicitly**

Run: `mix test --include cascade`
Expected: All tests pass including cascade test

- [ ] **Step 3: Run the code formatter**

Run: `mix format --check-formatted`
Expected: All files formatted. If not, run `mix format` and commit the changes.

- [ ] **Step 4: Verify clean compilation with no warnings**

Run: `mix compile --warnings-as-errors`
Expected: Clean compilation, zero warnings

- [ ] **Step 5: Verify the zero-config resource works in IEx**

Run: `iex -S mix`

```elixir
# Verify struct introspection
alias PhoenixFilament.Test.Resources.CascadeResource
CascadeResource.__resource__(:schema)
# => PhoenixFilament.Test.Schemas.Post

CascadeResource.__resource__(:form_fields)
# => [%PhoenixFilament.Field{name: :title, ...}, ...]

CascadeResource.__resource__(:table_columns)
# => [%PhoenixFilament.Column{name: :title, ...}, ...]

# Verify Field struct is inspectable
%PhoenixFilament.Field{}
# => %PhoenixFilament.Field{name: nil, type: nil, label: nil, opts: []}
```

- [ ] **Step 6: Commit any final adjustments**

```bash
git add -A
git commit -m "chore: final Phase 1 verification pass"
```

---

## Success Criteria Verification

After completing all tasks, verify each success criterion from the roadmap:

| # | Criterion | Verified By |
|---|-----------|-------------|
| 1 | Package compiles as dependency in blank `mix phx.new` app with no warnings | Task 10 Step 4: `mix compile --warnings-as-errors` |
| 2 | `PhoenixFilament.Schema.fields/1` returns typed field metadata at runtime | Task 5: schema_test.exs `fields/1` tests |
| 3 | `use PhoenixFilament.Resource` doesn't cause compile cascades on schema change | Task 9: cascade_test.exs |
| 4 | Field and column definitions are plain structs inspectable in IEx | Task 10 Step 5: IEx verification |

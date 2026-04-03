# Resource Customization

A PhoenixFilament Resource is a module that declares how an Ecto schema is exposed in the
admin panel — its form fields, table columns, filters, actions, and authorization rules.

## Declaring a Resource

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo
end
```

## `use PhoenixFilament.Resource` Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `schema:` | module | yes | The Ecto schema module |
| `repo:` | module | yes | The Ecto repo module |
| `label:` | string | no | Singular display name (auto-derived from schema name) |
| `plural_label:` | string | no | Plural display name (auto-derived) |
| `icon:` | string | no | Heroicon name for panel navigation |
| `create_changeset:` | `{Module, :function}` | no | Changeset for create. Default: `{schema, :changeset}` |
| `update_changeset:` | `{Module, :function}` | no | Changeset for update. Default: `{schema, :changeset}` |

### Custom changesets

When your schema has separate create and update changesets:

```elixir
defmodule MyAppWeb.Admin.UserResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Accounts.User,
    repo: MyApp.Repo,
    label: "User",
    create_changeset: {MyApp.Accounts.User, :registration_changeset},
    update_changeset: {MyApp.Accounts.User, :profile_changeset}
end
```

Both options take a `{Module, :function_name}` tuple. The function is called as:

- Create: `Module.function_name(%User{}, params)`
- Update: `Module.function_name(existing_user, params)`

## Form DSL

Add a `form do...end` block inside your resource module to customize the create/edit form.
If no `form` block is present, PhoenixFilament auto-generates fields from the schema.

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  form do
    text_input :title
    textarea :body
    toggle :published
    date :published_at
  end
end
```

### Field types

#### `text_input`

Single-line text field. Use for short strings.

```elixir
text_input :title
text_input :title, label: "Post Title", placeholder: "Enter a title"
```

#### `textarea`

Multi-line text field. Use for long text content.

```elixir
textarea :body
textarea :body, label: "Content"
```

#### `number_input`

Numeric input. Suitable for integer and float fields.

```elixir
number_input :price
number_input :views, label: "View Count"
```

#### `select`

Drop-down menu. Requires an `options:` list.

```elixir
select :status, options: ["draft", "published", "archived"]

# With labels:
select :status, options: [{"Draft", "draft"}, {"Published", "published"}]

# With label override:
select :category_id, label: "Category", options: [{"Tech", 1}, {"Business", 2}]
```

#### `checkbox`

Standard HTML checkbox. Suitable for boolean fields.

```elixir
checkbox :featured
checkbox :accept_terms, label: "Accept Terms of Service"
```

#### `toggle`

Toggle switch for boolean fields. Renders as a daisyUI toggle.

```elixir
toggle :published
toggle :email_notifications, label: "Email Notifications"
```

#### `date`

Date picker input. Works with Ecto `:date` and `:naive_datetime` fields.

```elixir
date :published_at
date :expires_on, label: "Expiration Date"
```

#### `datetime`

Date and time picker. Works with Ecto `:naive_datetime` and `:utc_datetime` fields.

```elixir
datetime :published_at
datetime :scheduled_for, label: "Scheduled For"
```

#### `hidden`

Hidden input. Useful for sending values without showing them to the user.

```elixir
hidden :author_id
hidden :tenant_id
```

### Form layout: sections

`section` groups related fields under a labeled heading:

```elixir
form do
  section "Basic Information" do
    text_input :title
    text_input :slug
  end

  section "Content" do
    textarea :body
    textarea :excerpt
  end

  section "Publishing" do
    toggle :published
    select :status, options: ["draft", "review", "published"]
    date :published_at
  end
end
```

Sections can be nested inside `columns`:

```elixir
form do
  columns 2 do
    section "Left Column" do
      text_input :first_name
      text_input :last_name
    end

    section "Right Column" do
      text_input :email
      text_input :phone
    end
  end
end
```

### Form layout: columns

`columns` renders its children in a CSS grid with the specified number of columns:

```elixir
form do
  columns 2 do
    text_input :first_name
    text_input :last_name
  end

  columns 3 do
    text_input :city
    text_input :state
    text_input :zip_code
  end
end
```

Fields within `columns` are evenly distributed across the grid.

### Conditional visibility: `visible_when`

Show or hide a field (or an entire section) based on another field's current value:

```elixir
form do
  toggle :published

  # Only visible when :published is true
  date :published_at, visible_when: [field: :published, eq: true]
end
```

`visible_when` options:

| Key | Description |
|-----|-------------|
| `field:` | The field name to watch |
| `eq:` | The value that must be present to show this field |

This works on individual fields:

```elixir
select :discount_type, options: ["none", "percent", "fixed"]
number_input :discount_amount, visible_when: [field: :discount_type, eq: "percent"]
number_input :discount_fixed,  visible_when: [field: :discount_type, eq: "fixed"]
```

And on entire sections:

```elixir
form do
  toggle :is_scheduled

  section "Schedule Options", visible_when: [field: :is_scheduled, eq: true] do
    datetime :scheduled_for
    select :timezone, options: ["UTC", "America/New_York", "Europe/Berlin"]
  end
end
```

## Table DSL

Add a `table do...end` block to customize the index listing. If omitted, PhoenixFilament
auto-generates columns from the schema.

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  table do
    column :title
    column :published
    column :inserted_at, label: "Created"

    actions do
      action :view,   label: "View",   icon: "hero-eye"
      action :edit,   label: "Edit",   icon: "hero-pencil"
      action :delete, label: "Delete", icon: "hero-trash", confirm: "Delete this post?"
    end

    filters do
      boolean_filter :published
      select_filter  :status, options: [{"Draft", "draft"}, {"Published", "published"}]
    end
  end
end
```

### Columns

```elixir
column :field_name                          # auto-derives label from field name
column :field_name, label: "Custom Label"  # explicit column heading
```

Column order follows declaration order.

### Actions

The `actions do...end` block defines per-row action buttons.

Built-in action types handled automatically:

| Type | Behavior |
|------|----------|
| `:view` | Navigates to the show page |
| `:edit` | Navigates to the edit page |
| `:delete` | Deletes the record (with optional confirmation) |

All action types accept:

| Option | Description |
|--------|-------------|
| `label:` | Button text |
| `icon:` | Heroicon name |
| `confirm:` | Confirmation dialog message before executing the action |

#### Custom actions

Actions with types other than `:view`, `:edit`, `:delete` dispatch
`{:table_action, action_type, record_id}` to your resource's `handle_info/2`.
Override it to handle custom actions:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  table do
    column :title
    column :status

    actions do
      action :edit
      action :delete, confirm: "Delete this post?"
      action :publish, label: "Publish", icon: "hero-check", confirm: "Publish this post?"
    end
  end

  @impl true
  def handle_info({:table_action, :publish, id}, socket) do
    post = MyApp.Repo.get!(MyApp.Blog.Post, id)
    {:ok, _} = MyApp.Blog.publish_post(post)
    {:noreply, Phoenix.LiveView.put_flash(socket, :info, "Post published")}
  end

  def handle_info(msg, socket), do: super(msg, socket)
end
```

### Filters

The `filters do...end` block renders a filter toolbar above the table.

#### `boolean_filter`

A toggle filter for boolean fields:

```elixir
filters do
  boolean_filter :published
  boolean_filter :featured, label: "Featured Only"
end
```

#### `select_filter`

A dropdown filter for fields with a known set of values:

```elixir
filters do
  select_filter :status, options: [
    {"Draft", "draft"},
    {"Published", "published"},
    {"Archived", "archived"}
  ]

  select_filter :category_id, label: "Category", options: [
    {"Technology", 1},
    {"Business", 2},
    {"Design", 3}
  ]
end
```

#### `date_filter`

A date range filter:

```elixir
filters do
  date_filter :inserted_at, label: "Created After"
  date_filter :published_at, label: "Published After"
end
```

### Search

Full-text search is always enabled. The search box filters records by matching
across all `:string` fields in the schema using `ILIKE` queries.

To disable search on a per-resource basis, this is not yet configurable — search
is always active when the schema has string fields.

### Pagination and sorting

Pagination and column sorting are enabled automatically:

- Clicking a column header toggles ascending/descending sort
- Pagination controls appear below the table
- Default page size is 20 records

## Authorization

Define an `authorize/3` function on your resource to gate CRUD operations:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  # Admins can do everything
  def authorize(_action, _record, %{role: "admin"}), do: :ok

  # Editors can create and edit but not delete
  def authorize(:delete, _record, %{role: "editor"}), do: {:error, :forbidden}
  def authorize(_action, _record, %{role: "editor"}), do: :ok

  # Viewers can only view
  def authorize(:index, _record, %{role: "viewer"}), do: :ok
  def authorize(:show, _record, %{role: "viewer"}), do: :ok
  def authorize(_action, _record, %{role: "viewer"}), do: {:error, :forbidden}

  # Default deny
  def authorize(_action, _record, _user), do: {:error, :unauthorized}
end
```

`authorize/3` signature:

```elixir
@spec authorize(action, record, user) :: :ok | {:error, reason}
  when action: :index | :create | :edit | :delete | :show,
       record: struct() | nil,
       user: any()
```

- `action` — the operation being attempted
- `record` — the Ecto struct being acted on (nil for `:create` and `:index`)
- `user` — the value of `socket.assigns.current_user`

Returning `{:error, reason}` raises `PhoenixFilament.Resource.UnauthorizedError`.

If `authorize/3` is not defined on the resource, all operations are allowed.

## Overriding LiveView Callbacks

`use PhoenixFilament.Resource` injects default implementations of all LiveView callbacks.
You can override any of them:

```elixir
defmodule MyAppWeb.Admin.PostResource do
  use PhoenixFilament.Resource,
    schema: MyApp.Blog.Post,
    repo: MyApp.Repo

  # Override mount to add custom assigns
  @impl true
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)
    {:ok, assign(socket, :categories, MyApp.Blog.list_categories())}
  end
end
```

All callbacks are `defoverridable` — call `super` to execute the default behavior before
your customization.

Available overridable callbacks:

- `mount/3`
- `handle_params/3`
- `handle_event/3`
- `handle_info/2`
- `render/1`

## Inspecting Resource Metadata

Each resource exposes its configuration via `__resource__/1`:

```elixir
MyAppWeb.Admin.PostResource.__resource__(:schema)         # => MyApp.Blog.Post
MyAppWeb.Admin.PostResource.__resource__(:repo)           # => MyApp.Repo
MyAppWeb.Admin.PostResource.__resource__(:opts)           # => keyword list
MyAppWeb.Admin.PostResource.__resource__(:form_fields)    # => [%PhoenixFilament.Field{}, ...]
MyAppWeb.Admin.PostResource.__resource__(:table_columns)  # => [%PhoenixFilament.Column{}, ...]
MyAppWeb.Admin.PostResource.__resource__(:table_actions)  # => [%PhoenixFilament.Table.Action{}, ...]
MyAppWeb.Admin.PostResource.__resource__(:table_filters)  # => [%PhoenixFilament.Table.Filter{}, ...]
```

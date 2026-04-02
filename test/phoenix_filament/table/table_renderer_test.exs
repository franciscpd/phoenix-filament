defmodule PhoenixFilament.Table.TableRendererTest do
  use PhoenixFilament.ComponentCase, async: true

  alias PhoenixFilament.Table.TableRenderer
  alias PhoenixFilament.Table.{Action, Filter}
  alias PhoenixFilament.Column

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp col(name, opts \\ []), do: Column.column(name, opts)

  defp row(fields \\ []) do
    Enum.into([id: 1, title: "Hello", status: "active", published: true] ++ fields, %{})
    |> Map.new(fn {k, v} -> {k, v} end)
  end

  # ---------------------------------------------------------------------------
  # search_bar/1
  # ---------------------------------------------------------------------------

  describe "search_bar/1" do
    test "renders input with phx-change and debounce" do
      assigns = %{search: "", target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.search_bar search={@search} target={@target} />
        """)

      assert html =~ "<input"
      assert html =~ ~s(phx-change="search")
      assert html =~ "debounce"
    end

    test "reflects current search value" do
      assigns = %{search: "hello world", target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.search_bar search={@search} target={@target} />
        """)

      assert html =~ "hello world"
    end

    test "includes phx-target when target is set" do
      assigns = %{search: "", target: "#my-component"}

      html =
        rendered_to_string(~H"""
        <TableRenderer.search_bar search={@search} target={@target} />
        """)

      assert html =~ ~s(phx-target="#my-component")
    end
  end

  # ---------------------------------------------------------------------------
  # filter_bar/1
  # ---------------------------------------------------------------------------

  describe "filter_bar/1" do
    test "renders select filter with options" do
      filters = [
        %Filter{type: :select, field: :status, label: "Status", options: ["active", "inactive"]}
      ]

      assigns = %{filters: filters, filter_values: %{}, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.filter_bar filters={@filters} filter_values={@filter_values} target={@target} />
        """)

      assert html =~ "<select"
      assert html =~ "active"
      assert html =~ "inactive"
    end

    test "renders boolean filter as checkbox" do
      filters = [%Filter{type: :boolean, field: :published, label: "Published"}]

      assigns = %{filters: filters, filter_values: %{}, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.filter_bar filters={@filters} filter_values={@filter_values} target={@target} />
        """)

      assert html =~ ~s(type="checkbox")
    end

    test "renders date_range filter with two date inputs" do
      filters = [%Filter{type: :date_range, field: :inserted_at, label: "Created"}]

      assigns = %{filters: filters, filter_values: %{}, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.filter_bar filters={@filters} filter_values={@filter_values} target={@target} />
        """)

      assert html =~ ~s(type="date")
    end

    test "renders nothing when filters list is empty" do
      assigns = %{filters: [], filter_values: %{}, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.filter_bar filters={@filters} filter_values={@filter_values} target={@target} />
        """)

      # Should still render container but no filter controls
      refute html =~ "<select"
      refute html =~ ~s(type="checkbox")
    end
  end

  # ---------------------------------------------------------------------------
  # table_header/1
  # ---------------------------------------------------------------------------

  describe "table_header/1" do
    test "renders a thead with column labels" do
      columns = [col(:title), col(:status)]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :asc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      assert html =~ "<thead"
      assert html =~ "Title"
      assert html =~ "Status"
    end

    test "sortable column has phx-click=sort" do
      columns = [col(:title, sortable: true)]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :asc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      assert html =~ ~s(phx-click="sort")
      assert html =~ ~s(phx-value-column="title")
    end

    test "non-sortable column has no phx-click" do
      columns = [col(:status)]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :asc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      refute html =~ ~s(phx-click="sort")
    end

    test "active sort column shows asc indicator" do
      columns = [col(:title, sortable: true)]
      assigns = %{columns: columns, sort_by: :title, sort_dir: :asc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      assert html =~ "▲"
    end

    test "active sort column shows desc indicator" do
      columns = [col(:title, sortable: true)]
      assigns = %{columns: columns, sort_by: :title, sort_dir: :desc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      assert html =~ "▼"
    end

    test "adds Actions column header when actions present" do
      columns = [col(:title)]
      actions = [%Action{type: :edit, label: "Edit"}]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :asc, actions: actions, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      assert html =~ "Actions"
    end

    test "no Actions column when actions empty" do
      columns = [col(:title)]
      assigns = %{columns: columns, sort_by: :id, sort_dir: :asc, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_header
          columns={@columns}
          sort_by={@sort_by}
          sort_dir={@sort_dir}
          actions={@actions}
          target={@target}
        />
        """)

      refute html =~ "Actions"
    end
  end

  # ---------------------------------------------------------------------------
  # table_row/1
  # ---------------------------------------------------------------------------

  describe "table_row/1" do
    test "renders a tr with column values" do
      columns = [col(:title), col(:status)]
      r = row()
      assigns = %{row: r, columns: columns, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ "<tr"
      assert html =~ "Hello"
      assert html =~ "active"
    end

    test "renders badge when column has badge: true" do
      columns = [col(:status, badge: true)]
      r = row()
      assigns = %{row: r, columns: columns, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ ~s(class="badge badge-sm")
      assert html =~ "active"
    end

    test "uses format callback when provided" do
      columns = [col(:title, format: fn _v, _row -> "FORMATTED" end)]
      r = row()
      assigns = %{row: r, columns: columns, actions: [], target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ "FORMATTED"
    end

    test "renders edit action button" do
      columns = [col(:title)]
      actions = [%Action{type: :edit, label: "Edit"}]
      r = row()
      assigns = %{row: r, columns: columns, actions: actions, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ ~s(phx-click="row_action")
      assert html =~ ~s(phx-value-action="edit")
      assert html =~ "btn-ghost"
      assert html =~ "Edit"
    end

    test "renders delete action with danger variant" do
      columns = [col(:title)]
      actions = [%Action{type: :delete, label: "Delete"}]
      r = row()
      assigns = %{row: r, columns: columns, actions: actions, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ "btn-error"
      assert html =~ ~s(phx-value-action="delete")
    end

    test "action button sends row id" do
      columns = [col(:title)]
      actions = [%Action{type: :edit, label: "Edit"}]
      r = row(id: 42)
      assigns = %{row: r, columns: columns, actions: actions, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.table_row row={@row} columns={@columns} actions={@actions} target={@target} />
        """)

      assert html =~ ~s(phx-value-id="42")
    end
  end

  # ---------------------------------------------------------------------------
  # pagination/1
  # ---------------------------------------------------------------------------

  describe "pagination/1" do
    test "shows page info text" do
      assigns = %{page: 1, per_page: 25, total: 100, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      # Should contain "Showing X-Y of Z"
      assert html =~ "Showing"
      assert html =~ "100"
    end

    test "shows correct range for first page" do
      assigns = %{page: 1, per_page: 10, total: 50, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      assert html =~ "1"
      assert html =~ "10"
      assert html =~ "50"
    end

    test "shows correct range for second page" do
      assigns = %{page: 2, per_page: 10, total: 50, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      assert html =~ "11"
      assert html =~ "20"
    end

    test "renders per-page selector" do
      assigns = %{page: 1, per_page: 25, total: 100, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      assert html =~ "<select"
    end

    test "renders previous and next buttons" do
      assigns = %{page: 2, per_page: 10, total: 50, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      assert html =~ "Previous"
      assert html =~ "Next"
    end

    test "previous button disabled on first page" do
      assigns = %{page: 1, per_page: 10, total: 50, target: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.pagination page={@page} per_page={@per_page} total={@total} target={@target} />
        """)

      assert html =~ "disabled"
    end
  end

  # ---------------------------------------------------------------------------
  # empty_state/1
  # ---------------------------------------------------------------------------

  describe "empty_state/1" do
    test "renders message" do
      assigns = %{message: "No records found", action: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.empty_state message={@message} action={@action} />
        """)

      assert html =~ "No records found"
    end

    test "renders CTA button when action map is provided" do
      assigns = %{message: "No records found", action: %{label: "Create Record", event: "new"}}

      html =
        rendered_to_string(~H"""
        <TableRenderer.empty_state message={@message} action={@action} />
        """)

      assert html =~ "Create Record"
      assert html =~ ~s(phx-click="new")
    end

    test "no button when action is nil" do
      assigns = %{message: "Nothing here", action: nil}

      html =
        rendered_to_string(~H"""
        <TableRenderer.empty_state message={@message} action={@action} />
        """)

      refute html =~ "<button"
    end
  end
end

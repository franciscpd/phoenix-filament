defmodule PhoenixFilament.SchemaTest do
  use ExUnit.Case, async: true

  alias PhoenixFilament.Schema
  alias PhoenixFilament.Test.Schemas.{Post, User, Comment, Profile, Tag}

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

    test "returns many_to_many associations" do
      assocs = Schema.associations(Tag)
      posts = Enum.find(assocs, &(&1.name == :posts))

      assert posts != nil
      assert posts.type == :many_to_many
      assert posts.related == Post
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

  describe "ensure_schema! error messages" do
    test "raises helpful message for non-schema module" do
      assert_raise ArgumentError, ~r/is not an Ecto schema.*use Ecto.Schema/, fn ->
        Schema.fields(Enum)
      end
    end

    test "raises helpful message for nonexistent module" do
      assert_raise ArgumentError, ~r/could not be loaded.*Verify the module exists/, fn ->
        Schema.fields(Does.Not.Exist)
      end
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

defmodule PhoenixFilament.Test.Schemas.Tag do
  use Ecto.Schema

  schema "tags" do
    field(:name, :string)

    many_to_many(:posts, PhoenixFilament.Test.Schemas.Post, join_through: "posts_tags")

    timestamps()
  end
end

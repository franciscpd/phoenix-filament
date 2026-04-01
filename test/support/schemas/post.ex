defmodule PhoenixFilament.Test.Schemas.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:views, :integer)
    field(:published, :boolean, default: false)
    field(:published_at, :naive_datetime)

    belongs_to(:author, PhoenixFilament.Test.Schemas.User)

    timestamps()
  end
end

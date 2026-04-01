defmodule PhoenixFilament.Test.Schemas.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:body, :string)

    belongs_to(:post, PhoenixFilament.Test.Schemas.Post)
    belongs_to(:user, PhoenixFilament.Test.Schemas.User)

    timestamps()
  end
end

defmodule PhoenixFilament.Test.Schemas.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:confirmation_token, :string)
    field(:role, :string, default: "user")

    has_many(:posts, PhoenixFilament.Test.Schemas.Post, foreign_key: :author_id)
    has_many(:comments, PhoenixFilament.Test.Schemas.Comment)

    timestamps()
  end
end

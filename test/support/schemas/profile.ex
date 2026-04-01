defmodule PhoenixFilament.Test.Schemas.Address do
  use Ecto.Schema

  embedded_schema do
    field(:street, :string)
    field(:city, :string)
    field(:zip, :string)
  end
end

defmodule PhoenixFilament.Test.Schemas.Profile do
  use Ecto.Schema

  schema "profiles" do
    field(:bio, :string)
    field(:display_name, :string, virtual: true)
    field(:age, :integer, virtual: true)

    embeds_one(:address, PhoenixFilament.Test.Schemas.Address)

    belongs_to(:user, PhoenixFilament.Test.Schemas.User)

    timestamps()
  end
end

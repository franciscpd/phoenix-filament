defmodule PhoenixFilament.Test.Resources.TestPostResource do
  use PhoenixFilament.Resource,
    schema: PhoenixFilament.Test.Schemas.Post,
    repo: PhoenixFilament.Test.FakeRepo,
    label: "Post",
    plural_label: "Posts",
    icon: "hero-document-text"
end

defmodule PhoenixFilament.Test.Resources.CascadeResource do
  use PhoenixFilament.Resource,
    schema: PhoenixFilament.Test.Schemas.Post,
    repo: PhoenixFilament.Test.FakeRepo

  form do
    text_input(:title, required: true)
    textarea(:body)
    toggle(:published)
  end

  table do
    column(:title, sortable: true)
    column(:published, badge: true)
  end
end

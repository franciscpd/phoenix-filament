defmodule Mix.Tasks.PhxFilament.Gen.Resource do
  @moduledoc """
  Generates a PhoenixFilament resource for an Ecto schema.

  ## Usage

      mix phx_filament.gen.resource MyApp.Blog.Post
      mix phx_filament.gen.resource MyApp.Blog.Post --repo MyApp.Repo.ReadOnly

  ## What it does

  1. Creates a Resource module at `lib/{app_web}/admin/{name}_resource.ex`
  2. Prints instructions for registering the resource in your Panel module

  ## Options

  - `--repo` / `-r` — Ecto Repo module to use. Defaults to `{AppName}.Repo`.
  """

  if Code.ensure_loaded?(Igniter) do
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_filament,
        example: "mix phx_filament.gen.resource MyApp.Blog.Post",
        positional: [:schema],
        schema: [repo: :string],
        aliases: [r: :repo]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      schema_string = igniter.args.positional.schema
      schema_module = Module.concat([schema_string])
      schema_name = schema_module |> Module.split() |> List.last()

      app_name = Igniter.Project.Application.app_name(igniter)
      app_name_camel = app_name |> to_string() |> Macro.camelize()
      web_module = Module.concat([app_name_camel <> "Web"])
      panel_module = Module.concat([web_module, "Admin"])
      resource_module = Module.concat([panel_module, "#{schema_name}Resource"])

      repo =
        case igniter.args.options[:repo] do
          nil -> Module.concat([app_name_camel, "Repo"])
          repo_string -> Module.concat([repo_string])
        end

      igniter
      |> create_resource_module(resource_module, schema_module, repo)
      |> print_registration_instructions(panel_module, resource_module)
    end

    defp create_resource_module(igniter, resource_module, schema_module, repo) do
      path = Igniter.Project.Module.proper_location(igniter, resource_module)

      template_path = Application.app_dir(:phoenix_filament, "priv/templates/resource.ex.eex")

      contents =
        if File.exists?(template_path) do
          EEx.eval_file(template_path,
            assigns: %{
              resource_module: inspect(resource_module),
              schema: inspect(schema_module),
              repo: inspect(repo)
            }
          )
        else
          """
          defmodule #{inspect(resource_module)} do
            use PhoenixFilament.Resource,
              schema: #{inspect(schema_module)},
              repo: #{inspect(repo)}
          end
          """
        end

      Igniter.create_new_file(igniter, path, contents)
    end

    defp print_registration_instructions(igniter, panel_module, resource_module) do
      Igniter.add_notice(igniter, """

      Resource created! Add it to your panel module (#{inspect(panel_module)}):

          resources do
            resource #{inspect(resource_module)},
              icon: "hero-document-text"
          end
      """)
    end
  else
    use Mix.Task

    @shortdoc "Generates a PhoenixFilament resource (requires Igniter)"

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      PhoenixFilament resource generator requires Igniter.

      Add {:igniter, "~> 0.7"} to your deps in mix.exs and run:

          mix deps.get
          mix phx_filament.gen.resource MyApp.Blog.Post
      """)
    end
  end
end

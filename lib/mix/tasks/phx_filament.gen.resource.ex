defmodule Mix.Tasks.PhxFilament.Gen.Resource do
  @moduledoc """
  Generates a PhoenixFilament resource for an Ecto schema.

  ## Usage

      mix phx_filament.gen.resource MyApp.Blog.Post
      mix phx_filament.gen.resource MyApp.Blog.Post --repo MyApp.Repo.ReadOnly

  ## What it does

  1. Creates a Resource module at `lib/{app_web}/admin/{name}_resource.ex`
  2. Attempts to register the resource in your Panel module automatically
  3. Falls back to printing instructions if the Panel module cannot be found or patched

  ## Options

  - `--repo` / `-r` — Ecto Repo module to use. Auto-detected from `use Ecto.Repo` modules,
    defaults to `{AppName}.Repo` if none found.
  """

  if Code.ensure_loaded?(Igniter) do
    use Igniter.Mix.Task

    @shortdoc "Generates a PhoenixFilament resource"

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

      {igniter, repo} =
        case igniter.args.options[:repo] do
          nil -> detect_repo(igniter, app_name_camel)
          repo_string -> {igniter, Module.concat([repo_string])}
        end

      igniter
      |> create_resource_module(resource_module, schema_module, repo)
      |> register_resource_in_panel(panel_module, resource_module)
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

      Igniter.create_new_file(igniter, path, contents, on_exists: :skip)
    end

    defp register_resource_in_panel(igniter, panel_module, resource_module) do
      resource_entry = "resource #{inspect(resource_module)}, icon: \"hero-document-text\""

      case Igniter.Project.Module.find_and_update_module(igniter, panel_module, fn zipper ->
             # Try to find an existing resources do...end block
             case find_resources_block(zipper) do
               {:ok, resources_zipper} ->
                 # Check if already registered
                 content = zipper_to_string(resources_zipper)

                 if String.contains?(content, inspect(resource_module)) do
                   {:ok, zipper}
                 else
                   {:ok, Igniter.Code.Common.add_code(resources_zipper, resource_entry)}
                 end

               :error ->
                 # No resources block — add one to the module body
                 case Igniter.Code.Common.move_to_do_block(zipper) do
                   {:ok, do_zipper} ->
                     resources_block = """
                     resources do
                       #{resource_entry}
                     end
                     """

                     {:ok, Igniter.Code.Common.add_code(do_zipper, resources_block)}

                   :error ->
                     {:warning, registration_manual_notice(panel_module, resource_module)}
                 end
             end
           end) do
        {:ok, igniter} ->
          igniter

        {:error, igniter} ->
          Igniter.add_notice(igniter, registration_manual_notice(panel_module, resource_module))
      end
    end

    defp find_resources_block(zipper) do
      Igniter.Code.Common.move_to(zipper, fn z ->
        case z.node do
          {:resources, _, [[do: _]]} -> true
          {:resources, _, [_block]} -> true
          _ -> false
        end
      end)
      |> case do
        {:ok, resources_zipper} ->
          Igniter.Code.Common.move_to_do_block(resources_zipper)

        :error ->
          :error
      end
    end

    defp zipper_to_string(%Sourceror.Zipper{node: node}) do
      node |> Macro.to_string()
    rescue
      _ -> ""
    end

    defp registration_manual_notice(panel_module, resource_module) do
      """
      Resource created! Add it to your panel module (#{inspect(panel_module)}):

          resources do
            resource #{inspect(resource_module)},
              icon: "hero-document-text"
          end
      """
    end

    defp detect_repo(igniter, app_name_camel) do
      default_repo = Module.concat([app_name_camel, "Repo"])

      {igniter, matching} =
        Igniter.Project.Module.find_all_matching_modules(igniter, fn _mod, zipper ->
          Igniter.Code.Module.move_to_use(zipper, Ecto.Repo) != :error
        end)

      case matching do
        [single_repo] -> {igniter, single_repo}
        _ -> {igniter, default_repo}
      end
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

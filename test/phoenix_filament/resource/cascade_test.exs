defmodule PhoenixFilament.Resource.CascadeTest do
  use ExUnit.Case

  @moduletag :cascade

  @tag timeout: 60_000
  test "touching schema file does not recompile resource module" do
    project_root = File.cwd!()
    schema_path = Path.join(project_root, "test/support/schemas/post.ex")
    resource_path = Path.join(project_root, "test/support/resources/cascade_resource.ex")

    assert File.exists?(resource_path),
           "Missing test/support/resources/cascade_resource.ex"

    # Step 1: Full compile to establish baseline
    {_, 0} = System.cmd("mix", ["compile", "--force"], cd: project_root, stderr_to_stdout: true)

    # Step 2: Touch the schema file (simulate a change)
    File.touch!(schema_path)

    # Step 3: Recompile and capture output
    {output, 0} = System.cmd("mix", ["compile"], cd: project_root, stderr_to_stdout: true)

    # Step 4: Assert the resource module was NOT recompiled
    refute output =~ "cascade_resource",
           """
           Compile-time cascade detected!

           Touching #{schema_path} caused CascadeResource to recompile.
           This means Macro.expand_literals/2 is not properly preventing
           compile-time dependencies.

           mix compile output:
           #{output}
           """
  end
end

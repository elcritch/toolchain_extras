defmodule NervesExtras.Toolchain do
  use Nerves.Package.Platform

  alias Nerves.Artifact
  import Mix.Nerves.Utils

  @doc """
  The bootstrap callback is the called during the final setup of a Nerves "build" environment.
  This platform package looks for the `:toolchain_extras` key in the nerves package configuration.

  An example from the `:toolchain_extras_pru_cgt` extras toolchain mix.exs `nerves_package` function:

  ```elixir
    toolchain_extras: [
      env_var: "PRU_CGT",
      build_path_link: "ti-cgt-pru",
      build_script: "build.sh",
      clean_files: ["ti-cgt-pru"],
      archive_script: "scripts/archive.sh"
    ]
  ```

  TODO: Fill out documentation for configuration options.

  """
  @callback bootstrap(Nerves.Package.t()) :: :ok | {:error, error :: term}
  def bootstrap(%{config: config} = pkg) do
    IO.puts("EXTRAS:BOOTSRAPPING: PKG: #{inspect(pkg)}")

    if Keyword.has_key?(config[:toolchain_extras], :boostrap_override) do
      boot_func = config[:toolchain_extras][:boostrap_override]
      boot_func.(pkg)
    else
      default_bootstrap(pkg)
    end
  end

  defp default_bootstrap(pkg) do
    artifact_path =
      Artifact.base_dir()
      |> Path.join(Artifact.name(pkg))

    env_var = pkg.config[:toolchain_extras][:env_var]

    IO.puts("EXTRAS:BOOTSRAPPING: PUT_ENV: ENVVAR: #{inspect(env_var)}")
    IO.puts("EXTRAS:BOOTSRAPPING:          PATH: #{inspect(artifact_path)}")

    System.put_env(env_var, artifact_path)
    :ok
  end

  @doc """
  Return the location in the build path to where the global artifact is linked
  """
  @callback build_path_link(package :: Nerves.Package.t()) :: build_path_link :: String.t()
  def build_path_link(pkg) do
    IO.puts("EXTRAS:BUILD_PATH_LINK: PKG: #{inspect(pkg)}")

    path_link = pkg.config[:build_path_link] || ""
    build_path = Artifact.build_path(pkg) || ""

    path = Path.join(build_path, path_link)
    IO.inspect(path, label: :extras_build_path_link)
  end

  def build(pkg, toolchain, opts) do
    build_path = Artifact.build_path(pkg)
    File.rm_rf!(build_path)
    File.mkdir_p!(build_path)

    build_path
    |> Path.join("scripts")
    |> Path.join("build.sh")

    IO.puts("EXTRAS:BUILD: TOOLCHAIN: #{inspect(toolchain)} opts: #{opts}")
    IO.puts("EXTRAS:BUILD: PWD: #{inspect System.cwd}")
    IO.puts("EXTRAS:BUILD: PKG: #{inspect(Artifact.name(pkg))}")
    IO.puts("EXTRAS:BUILD: BUILD_PATH: #{build_path}")

    case shell(script, [defconfig, build_path]) do
      {_, 0} -> 
        x_tools = Path.join(build_path, "x-tools")
        tuple = 
          x_tools
          |> File.ls!
          |> List.first
        toolchain_path = Path.join(x_tools, tuple)
        {:ok, toolchain_path}
      {error, _} -> {:error, error}
    end
  end

  @doc """
  Create an archive of the artifact
  """
  def archive(pkg, toolchain, opts) do
    build_path = Artifact.build_path(pkg)

    script =
      pkg
      |> Map.get(:path)
      |> Path.join("scripts")
      |> Path.join("archive.sh")

    IO.puts("EXTRAS:ARCHIVE: TOOLCHAIN: #{inspect(toolchain)} opts: #{opts}")

    tar_path = Path.join([build_path, Artifact.download_name(pkg) <> Artifact.ext(pkg)])

    case shell(script, [build_path, tar_path]) do
      {_, 0} -> {:ok, tar_path}
      {error, _} -> {:error, error}
    end
  end

  @doc """
  Clean up all the build files
  """
  def clean(pkg) do
    pkg
    |> Artifact.dir()
    |> File.rm_rf()
  end
end

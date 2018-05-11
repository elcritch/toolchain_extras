defmodule NervesExtras.Toolchain do
  use Nerves.Package.Platform

  alias Nerves.Artifact
  import Mix.Nerves.Utils

  @doc """
  Called as the last step of bootstrapping the Nerves env.
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

  defp default_bootstrap(%{path: path} = pkg) do
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

  def build(pkg, _toolchain, _opts) do
    build_path = Artifact.build_path(pkg)
    File.rm_rf!(build_path)
    File.mkdir_p!(build_path)

    build_path
    |> Path.join("file")
    |> File.touch()

    IO.puts("EXTRAS_BUILD: PKG: #{inspect(Artifact.name(pkg))} BUILD_PATH: #{build_path}")
    {:ok, build_path}
  end

  @doc """
  Create an archive of the artifact
  """
  def archive(pkg, _toolchain, _opts) do
    build_path = Artifact.build_path(pkg)

    script =
      pkg
      |> Map.get(:path)
      |> Path.join("scripts")
      |> Path.join("archive.sh")

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
    dmg = Artifact.name(pkg) <> ".dmg"
    File.rm(dmg)

    pkg
    |> Artifact.dir()
    |> File.rm_rf()
  end

  defp defconfig(pkg) do
    pkg.config
    |> Keyword.get(:platform_config)
    |> Keyword.get(:defconfig)
    |> Path.expand()
  end
end

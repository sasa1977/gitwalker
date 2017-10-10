defmodule Gitwalker.TestGitHelper do
  def init() do
    File.mkdir_p!(repos_folder())

    File.ls!(repos_folder())
    |> Enum.map(&repo_path/1)
    |> Enum.filter(&File.dir?/1)
    |> Enum.each(&remove_repo/1)

    :ok
  end

  def create_repo() do
    repo = repo_path(rand_file_name())

    File.mkdir_p!(repo)
    git!(repo, ["init"])

    repo
  end

  def remove_repo(repo), do:
    File.rm_rf!(repo)

  def add_commit!(repo) do
    file_name = Path.join(repo, rand_file_name())
    File.write!(file_name, :crypto.strong_rand_bytes(10))
    git!(repo, ["stage", file_name])
    git!(repo, ["commit", ~s/-m "added #{file_name}/, "--no-gpg-sign"])
    git!(repo, ["rev-parse", "HEAD"])
  end

  defp repo_path(path), do:
    repos_folder()
    |> Path.join(path)
    |> Path.expand()

  defp repos_folder(), do:
    Path.join(System.tmp_dir!(), "gitwalker_test")

  defp rand_file_name(), do:
    Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)

  defp git!(repo, args) do
    {output, 0} = System.cmd("git", args, cd: repo, stderr_to_stdout: true)
    String.replace(output, ~r/\n$/, "")
  end
end

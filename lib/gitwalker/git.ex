defmodule Gitwalker.Git do
  def repo?(repo_folder) do
    case System.cmd("git", ["rev-parse", "HEAD"], cd: repo_folder, stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  def log(repo_folder, opts \\ []), do:
    repo_folder
    |> git!(["log", Keyword.get(opts, :branch, "master"), "--pretty=oneline"])
    |> String.split("\n")
    |> Stream.map(&String.split(&1, " ", parts: 2))
    |> Enum.map(fn [sha, comment] -> %{sha: sha, comment: comment} end)
    |> Enum.to_list()

  def current_head(repo_folder), do:
    git!(repo_folder, ["rev-parse", "HEAD"])

  def checkout(repo_folder, sha) do
    git!(repo_folder, ["checkout", sha])
    :ok
  end

  def reset_hard(repo_folder, sha) do
    git!(repo_folder, ["reset", sha, "--hard"])
    :ok
  end

  def changes(repo_folder, reference_sha, current_sha), do:
    git!(repo_folder, ["diff", "--name-status", reference_sha, current_sha])

  def current_commit_changes(repo_folder), do:
    git!(repo_folder, ["show", ~s(--pretty=), "--name-status", "HEAD"])

  defp git!(repo_folder, args) do
    {output, 0} = System.cmd("git", args, cd: repo_folder, stderr_to_stdout: true)

    output
    |> String.replace(~r/\n$/, "")
  end
end

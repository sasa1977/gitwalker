defmodule Gitwalker do
  alias Gitwalker.Git

  def new(folder) do
    if Git.repo?(folder) do
      {:ok,
        %{
          folder: folder,
          commits: Git.log(folder),
          current_sha: Git.current_head(folder)
        }
      }
    else
      {:error, :not_a_repo}
    end
  end

  def prev(gitwalker, count), do:
    checkout_after(gitwalker, gitwalker.current_sha, gitwalker.commits, count)

  def next(gitwalker, count), do:
    checkout_after(gitwalker, gitwalker.current_sha, Enum.reverse(gitwalker.commits), count)

  def last(gitwalker), do:
    checkout(gitwalker, hd(gitwalker.commits).sha)

  def first(gitwalker), do:
    checkout(gitwalker, List.last(gitwalker.commits).sha)

  defp checkout_after(gitwalker, sha, commits, count) do
    commits
    |> Enum.drop_while(&(&1.sha != sha))
    |> Enum.drop(count)
    |> case do
        [desired | _] ->
          {:ok, checkout(gitwalker, desired.sha)}
        _ ->
          {:error, :no_more_commits}
      end
  end

  defp checkout(gitwalker, sha) do
    Git.reset_hard(gitwalker.folder, gitwalker.current_sha)
    Git.checkout(gitwalker.folder, sha)
    %{gitwalker | current_sha: sha}
  end
end

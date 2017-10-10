defmodule Mix.Tasks.Gitwalker do
  @shortdoc "Task for walking the history of a git repo"

  @moduledoc """
  This task can be used to walk the history of a git repo.

  ## Usage

  Change to the folder of a repo where you want to walk through the commit history, and make sure that the master branch
  is checked out (gitwalker currently only works with master). Then you can use the following commands:

    - `mix gitwalker` - prints the current commit and a few surrounding commits
    - `mix gitwalker first` - checks out the first commit
    - `mix gitwalker last` - checks out the most recent commit
    - `mix gitwalker next` - moves to the next commit
    - `mix gitwalker prev` - moves to the previous commit
  """
  use Mix.Task

  def run(args) do
    unless :os.find_executable('git'), do:
      Mix.raise("`git` executable is not in path.")

    {command, args} = parse_args(args)
    handle_command(command, args)
  end

  defp parse_args([]), do: {"status", []}
  defp parse_args([command | args]), do: {command, args}

  defp handle_command("status", []), do: list()
  defp handle_command("first", []), do: first()
  defp handle_command("last", []), do: last()
  defp handle_command("p", args), do: handle_command("prev", args)
  defp handle_command("prev", []), do: handle_command("prev", ["1"])
  defp handle_command("prev", [count]), do: prev(String.to_integer(count))
  defp handle_command("n", [args]), do: handle_command("next", [args])
  defp handle_command("next", []), do: handle_command("next", ["1"])
  defp handle_command("next", [count]), do: next(String.to_integer(count))
  defp handle_command(_other, _), do:
    Mix.raise("Invalid arguments, run `mix help gitwalker` for instructions.")


  defp list() do
    with {:ok, gitwalker} <- Gitwalker.new(File.cwd!()) do
      print(gitwalker)
      IO.puts Gitwalker.Git.current_commit_changes(gitwalker.folder)
      IO.puts ""
    else
      error -> print_error(error)
    end
  end

  defp first() do
    with {:ok, gitwalker} <- Gitwalker.new(File.cwd!()) do
      gitwalker
      |> Gitwalker.first()
      |> print()

      IO.puts Gitwalker.Git.current_commit_changes(gitwalker.folder)
      IO.puts ""
    end
  end

  defp last() do
    with {:ok, gitwalker} <- Gitwalker.new(File.cwd!()), do:
      gitwalker
      |> Gitwalker.last()
      |> print()
  end

  defp prev(count) do
    with {:ok, gitwalker} <- Gitwalker.new(File.cwd!()),
          {:ok, gitwalker} <- Gitwalker.prev(gitwalker, count)
    do
      print(gitwalker)
    else
      error -> print_error(error)
    end
  end

  defp next(count) do
    with {:ok, current_gitwalker} <- Gitwalker.new(File.cwd!()),
          {:ok, new_gitwalker} <- Gitwalker.next(current_gitwalker, count)
    do
      print(new_gitwalker)
      IO.puts Gitwalker.Git.changes(
        current_gitwalker.folder,
        current_gitwalker.current_sha,
        new_gitwalker.current_sha
      )
      IO.puts ""
    else
      error -> print_error(error)
    end
  end


  defp print(gitwalker) do
    previous =
      gitwalker.commits
      |> Stream.drop_while(&(&1.sha != gitwalker.current_sha))
      |> Enum.take(4)

    future =
      gitwalker.commits
      |> Enum.reverse()
      |> Stream.drop_while(&(&1.sha != gitwalker.current_sha))
      |> Stream.drop(1)
      |> Stream.take(3)
      |> Enum.reverse()

    IO.write [IO.ANSI.home, IO.ANSI.clear]

    (future ++ previous)
    |> Stream.map(&Map.put(&1, :current?, &1.sha == gitwalker.current_sha))
    |> Enum.each(&print_commit/1)

    IO.puts ""
  end

  defp print_commit(commit), do:
    print_row(
      [
        {current_indicator(commit), 3},
        {commit.sha, 5},
        {commit.comment, 80}
      ],
      emphasize?: commit.current?
    )

  defp current_indicator(%{current?: true}), do: "-->"
  defp current_indicator(%{current?: false}), do: ""

  defp print_row(column_defs, row_opts) do
    IO.puts([
      (if row_opts[:emphasize?], do: [IO.ANSI.bright(), IO.ANSI.green()], else: []),
      (
        column_defs
        |> Enum.map(fn({col, length}) -> fixsized_string(col, length) end)
        |> Enum.intersperse(space(3))
      ),
      IO.ANSI.reset()
    ])
  end

  defp space(length), do:
    fixsized_string(" ", length)

  defp fixsized_string(string, length), do:
    string
    |> String.pad_trailing(length)
    |> String.split_at(length)
    |> elem(0)

  defp print_error(error), do:
    Mix.raise("\n#{error_message(error)}\n")

  defp error_message({:error, :not_a_repo}), do: "Not a git repository!"
  defp error_message({:error, :no_more_commits}), do: "No such commit!"
end

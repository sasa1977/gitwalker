defmodule GitwalkerTest do
  use Gitwalker.GitTestCase
  alias Gitwalker.TestGitHelper

  test "not a git repo" do
    path =
      Path.join(
        System.tmp_dir!(),
        Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
      )
    File.mkdir_p!(path)
    try do
      assert Gitwalker.new(path) == {:error, :not_a_repo}
    after
      File.rm_rf!(path)
    end
  end

  describe "proper repo with commits" do
    setup context do
      {:ok, shas: Enum.map(1..5, fn _ -> TestGitHelper.add_commit!(context.repo) end)}
    end

    test "initial state", context do
      gw = gitwalker!(context.repo)

      assert context.shas ==
        gw.commits
        |> Enum.map(&(&1.sha))
        |> Enum.reverse()
    end

    test "moving to the first commit", context do
      gw =
        context.repo
        |> gitwalker!()
        |> Gitwalker.first()

      assert gw.current_sha == hd(context.shas)
    end

    test "moving to the last commit", context do
      gw =
        context.repo
        |> gitwalker!()
        |> Gitwalker.first()
        |> Gitwalker.last()

      assert gw.current_sha == List.last(context.shas)
    end

    test "moving one commit forwards", context do
      {:ok, gw} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.first()
        |> Gitwalker.next(1)

      assert gw.current_sha == context.shas |> Enum.drop(1) |> hd()
    end

    test "moving two commits forwards", context do
      {:ok, gw} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.first()
        |> Gitwalker.next(2)

      assert gw.current_sha == context.shas |> Enum.drop(2) |> hd()
    end

    test "moving one commit backwards", context do
      {:ok, gw} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.prev(1)

      assert gw.current_sha == context.shas |> Enum.reverse() |> Enum.drop(1) |> hd()
    end

    test "moving two commits backwards", context do
      {:ok, gw} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.prev(2)

      assert gw.current_sha == context.shas |> Enum.reverse() |> Enum.drop(2) |> hd()
    end

    test "moving beyond the last commit", context, do:
      assert {:error, :no_more_commits} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.next(1)

    test "moving beyond the first commit", context, do:
      assert {:error, :no_more_commits} =
        context.repo
        |> gitwalker!()
        |> Gitwalker.first()
        |> Gitwalker.prev(1)

    test "discarding local changes", context do
      file =
        Path.join(
          context.repo,
          File.ls!(context.repo) |> Enum.filter(&(not File.dir?(&1))) |> hd
        )

      original_contents = File.read!(file)

      File.write!(file, "some changes")

      context.repo
      |> gitwalker!()
      |> Gitwalker.first()
      |> Gitwalker.last()

      assert File.read!(file) == original_contents
    end
  end

  defp gitwalker!(repo) do
    {:ok, gw} = Gitwalker.new(repo)
    gw
  end
end

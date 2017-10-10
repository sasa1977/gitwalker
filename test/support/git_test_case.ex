defmodule Gitwalker.GitTestCase do
  use ExUnit.CaseTemplate
  alias Gitwalker.TestGitHelper

  setup do
    repo = TestGitHelper.create_repo()
    on_exit(fn -> TestGitHelper.remove_repo(repo) end)
    {:ok, repo: repo}
  end
end

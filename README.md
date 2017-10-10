# Gitwalker

Gitwalker is a simple mix task which can be used to walk through the history of a git repo.

## Prerequisites

- Elixir 1.5 or higher, available in system path
- git available in system path


## Installing

To install the mix task run the following command:

```
mix archive.install https://github.com/sasa1977/gitwalker/raw/master/archives/gitwalker-0.1.ez
```

To uninstall the task you can run:

```
mix archive.uninstall gitwalker-0.1
```

## Usage

Change to the folder of the repo where you want to walk through the commit history, and make sure that the master branch is checked out (gitwalker currently only works with the master branch). Then you can use the following commands:

- `mix gitwalker` - prints the current commit and a few surrounding commits
- `mix gitwalker first` - checks out the first commit
- `mix gitwalker last` - checks out the most recent commit
- `mix gitwalker next` - checks out the next commit
- `mix gitwalker prev` - checks out the previous commit

## Warnings and disclaimers

- I used the tool at my workshop, and it worked for me on my machine :-) I make no other guarantees. Use with caution, perhaps by trying it out on a temporary copy of your repo.
- Gitwalker commands revert any local changes (by using `git reset --hard current_sha`). Don't use gitwalker if you have some pending changes.
- Gitwalker commands check out a commit without creating a branch (by doing `git checkout sha`). Once you're done walking around the history, you'll need to manually checkout the master branch and resume your work.
- Not tested on Windows. It should work, but I didn't try it out. If you have problems open up an issue, or, even better, make a PR :-)

## License

[MIT](./LICENSE)

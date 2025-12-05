# workj
Git worktrees in Zellij.

## Intro

A simplified way of using [Git worktrees](https://git-scm.com/docs/git-worktree) with [Zellij](https://zellij.dev).

## Usage

The usage is very simple. First go to `/configs/layout.kdl` and make sure that the configuration there makes sense for your purposes. It's customisable, so change according to [Zellij layouts](https://zellij.dev/documentation/creating-a-layout.html).

After that, it's as easy as:

```sh
workj <command> <branch_name>
```

Available commands: add, remove.

Example: create a new [Git worktree](https://git-scm.com/docs/git-worktree) on a branch named `potato`:

```sh
workj add potato
```

This will create a new worktree at `$PROJECT_ROOT_LEVEL/../${PROJECT_NAME}__worktrees/potato` and open a new Zellij tab at that directory with panes based on the `layout.kdl` file.

To remove it:

```sh
workj remove potato
```

## Development

Build it:

```sh
zig build
```

Run it:

```
./zig-out/bin/workj <commmand> <branch_name>
```

### TODOs

- [ ] Convert shell to zig
- [ ] Add tests
- [ ] Validate the outputs to stdout/stderr

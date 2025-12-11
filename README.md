# workj
Git worktrees in Zellij.

## Intro

A simplified way of using [Git worktrees](https://git-scm.com/docs/git-worktree) with [Zellij](https://zellij.dev).

## Configuration

Before using it, check if the default configs (`/configs/*`) make sense for you. If they don't, you can create a `~/.workj/config.cfg` file. The valid keys are displayed in `/configs/workj_config.cfg`.

- `main_branch` is the start point for the new branch (if it doesn't exist);
- `layout` is the path to the [Zellij layout](https://zellij.dev/documentation/creating-a-layout.html) you want to use when starting a new `workj add <branch>` command.

>[!NOTE]
>If the config file doesn't exist at `~/.workj/config.cfg`, the default values (the ones inside `/configs/*`) will be used.

## Usage

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

- [x] Convert shell to zig
- [ ] Add tests
- [ ] Validate the outputs to stdout/stderr
- [x] Add a workj config file
- [ ] Validate allocator to use

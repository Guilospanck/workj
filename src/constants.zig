pub const USAGE: []const u8 =
    \\                                    __                
    \\                                   |  \               
    \\  __   __   __   ______    ______  | $$   __       __ 
    \\ |  \ |  \ |  \ /      \  /      \ | $$  /  \     |  \
    \\ | $$ | $$ | $$|  $$$$$$\|  $$$$$$\| $$_/  $$      \$$
    \\ | $$ | $$ | $$| $$  | $$| $$   \$$| $$   $$      |  \
    \\ | $$_/ $$_/ $$| $$__/ $$| $$      | $$$$$$\      | $$
    \\  \$$   $$   $$ \$$    $$| $$      | $$  \$$\     | $$
    \\   \$$$$$\$$$$   \$$$$$$  \$$       \$$   \$$__   | $$
    \\                                            |  \__/ $$
    \\                                             \$$    $$
    \\                                              \$$$$$$ 
    \\
    \\     workj — Git Worktree & Zellij Helper
    \\
    \\ Work with Zellij tabs backed by Git worktrees
    \\ Seamlessly add and remove workspaces with a single command.
    \\
    \\ USAGE:
    \\     workj [OPTIONS] COMMAND BRANCH_NAME [FLAGS]
    \\
    \\ OPTIONS:
    \\     -c, --config-file PATH_CONFIG_FILE
    \\         Choose a specific config file to use
    \\
    \\         Examples:
    \\           workj -c ./test/config.cfg add feature/foo
    \\
    \\     -nec, --no-envs-copy
    \\         Do not copy `.env*` files when creating a new git worktree.
    \\
    \\         Examples:
    \\           workj --no-env-files add feature/foo
    \\
    \\ COMMANDS:
    \\     add BRANCH_NAME
    \\         🆕  Create (or use) a Git worktree and open a Zellij tab
    \\         📌  Uses your project’s `layout.kdl` configuration
    \\
    \\         Examples:
    \\           workj add feature/foo
    \\           workj add bugfix/123
    \\
    \\     remove BRANCH_NAME
    \\         ❌  Close the Zellij tab associated with a worktree
    \\         🧹  Remove the Git worktree afterward
    \\
    \\         Examples:
    \\           workj remove feature/foo
    \\           workj remove bugfix/123
    \\
    \\     -h, --help
    \\         Show this help message
    \\
    \\         Examples:
    \\           workj -h
    \\           workj --help
    \\
    \\ FLAGS:
    \\     Flags that will be passed to the underlying git worktree command.
    \\     To know more, do `git worktree add --help` or `git worktree remove --help`.
    \\
    \\         Examples:
    \\           workj remove feature/foo --force (here --force will allow removing
    \\           the worktree even if it has uncommited changes).
    \\
    \\ FEATURES:
    \\     ✓ Automatically create worktrees
    \\     ✓ Open matching Zellij tabs
    \\     ✓ Clean tab removal & cleanup
    \\     ✓ Zero configuration unless you want custom layout rules
    \\
    \\ EXAMPLES:
    \\     # Create a new workspace tab for a feature
    \\     workj add feature/new-awesome
    \\
    \\     # Remove the tab and its worktree when done
    \\     workj remove feature/new-awesome
    \\
    \\ TIPS:
    \\     • Use descriptive worktree names for clarity.
    \\     • Combine with git aliases to boost your workflow.
    \\
    \\ HAPPY CODING WITH WORKJ 🚀
    \\ Source & documentation: https://github.com/Guilospanck/workj
    \\
;

pub const DEFAULT_CONFIG_PATH: []const u8 = ".workj/config.cfg";
pub const DEFAULT_MAIN_BRANCH: []const u8 = "origin/main";
pub const DEFAULT_LAYOUT_CONFIG: []const u8 = "configs/layout.kdl";
pub const DEFAULT_NO_ENVS_COPY: bool = false; // By default we copy the envs files

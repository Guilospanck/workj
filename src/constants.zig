pub const USAGE: []const u8 =
    \\                                    /$$          
    \\                                   | $$          
    \\  /$$  /$$  /$$  /$$$$$$   /$$$$$$ | $$   /$$ /$$
    \\ | $$ | $$ | $$ /$$__  $$ /$$__  $$| $$  /$$/|__/
    \\ | $$ | $$ | $$| $$  \ $$| $$  \__/| $$$$$$/  /$$
    \\ | $$ | $$ | $$| $$  | $$| $$      | $$_  $$ | $$
    \\ |  $$$$$/$$$$/|  $$$$$$/| $$      | $$ \  $$| $$
    \\  \_____/\___/  \______/ |__/      |__/  \__/| $$
    \\                                        /$$  | $$
    \\                                       |  $$$$$$/
    \\                                        \______/
    \\
    \\  🎯  workj — Git Worktree & Zellij Helper
    \\
    \\ Work with Zellij tabs backed by Git worktrees
    \\ Seamlessly add and remove workspaces with a single command.
    \\
    \\ USAGE:
    \\     workj <COMMAND> [OPTIONS]
    \\
    \\ COMMANDS:
    \\     add <name>          🆕  Create (or use) a Git worktree and open a Zellij tab
    \\                         📌  Uses your project’s `layout.kdl` configuration
    \\                         
    \\                         Examples:
    \\                           workj add feature/foo
    \\                           workj add bugfix/123
    \\
    \\     remove <name>       ❌  Close the Zellij tab associated with a worktree
    \\                         🧹  Remove the Git worktree afterward
    \\                         
    \\                         Examples:
    \\                           workj remove feature/foo
    \\                           workj remove bugfix/123
    \\
    \\     -h, --help          Show this help message
    \\
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
    \\       to know how to layout your Zellij panes.
    \\     • Use descriptive worktree names for clarity.
    \\     • Combine with git aliases to boost your workflow!
    \\
    \\ HAPPY CODING WITH WORKJ 🚀  
    \\ Source & documentation: https://github.com/Guilospanck/workj
    \\
;

pub const CONFIG_PATH: []const u8 = ".workj/config.cfg";

pub const DEFAULT_MAIN_BRANCH: []const u8 = "origin/main";
pub const DEFAULT_LAYOUT_CONFIG: []const u8 = "configs/layout.kdl";

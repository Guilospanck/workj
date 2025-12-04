#!/bin/bash
set -euo pipefail

new_tab(){
	zellij action new-tab --name $1
}

# Example:
# ./zellij.sh launch_program_new_pane ./ kiro-cli
launch_program_new_pane(){
	zellij run --cwd $1 -- $2
}

# Direction (-d): the direction to create a new pane. Can be either "down" or "right".
# CWD (--cwd): which directory to open the new pane into.
#
# Example:
# ./zellij.sh new_pane right ./
new_pane(){
	zellij action new-pane -d "$1" --cwd "$2" -- "$SHELL"
}

"$@"

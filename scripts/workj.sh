#!/bin/bash
set -euo pipefail

add() {
	local BRANCH_NAME=$1

	# gitworktree add
	local WORKTREE_DIRECTORY=$("$PWD/scripts/git_worktree.sh" add $BRANCH_NAME)

	"$PWD/scripts/zellij.sh" new_tab $BRANCH_NAME $WORKTREE_DIRECTORY
}

remove() {
	echo "(remove) Hey from script: $1"
}

"$@"

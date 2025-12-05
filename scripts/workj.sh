#!/bin/bash
set -euo pipefail

add() {
	local BRANCH_NAME=$1

	# gitworktree add
	local WORKTREE_DIRECTORY=$("$PWD/scripts/git_worktree.sh" add $BRANCH_NAME)

	if [ -n "$WORKTREE_DIRECTORY" ]; then
	  "$PWD/scripts/zellij.sh" new_tab $BRANCH_NAME $WORKTREE_DIRECTORY
	else
	  echo "WORKTREE_DIRECTORY is empty"
	fi

}

remove() {
	local BRANCH_NAME=$1
	"$PWD/scripts/git_worktree.sh" remove $BRANCH_NAME
}

"$@"

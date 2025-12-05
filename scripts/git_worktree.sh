#!/bin/bash
set -euo pipefail

MAIN_BRANCH=origin/main
WORKTREE_DIRECTORY="$PWD"

get_or_create_worktree_directory(){
	# Get/Create branch folder
	local PROJECT_ROOT_LEVEL=$(git rev-parse --show-toplevel)
	local PROJECT_NAME=$(git remote get-url origin | xargs basename -s .git)
	WORKTREE_DIRECTORY="$PROJECT_ROOT_LEVEL/../${PROJECT_NAME}__worktrees/$BRANCH_NAME"
	mkdir -p $WORKTREE_DIRECTORY
}


# Usage: add <branch_name>
add(){
	local BRANCH_NAME=$1
	get_or_create_worktree_directory $BRANCH_NAME

	if git rev-parse --verify $BRANCH_NAME >/dev/null 2>&1; then
	  echo "Branch exists"
	  git worktree add $WORKTREE_DIRECTORY $BRANCH_NAME -q
	else
	  echo "Branch does not exist"
	  git worktree add $WORKTREE_DIRECTORY -b $BRANCH_NAME $MAIN_BRANCH -q
	fi

	echo "Directory: $WORKTREE_DIRECTORY"
}

# Usage: remove <branch_name>
remove(){
	git worktree remove $1
}

"$@"

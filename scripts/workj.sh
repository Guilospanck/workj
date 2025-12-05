#!/bin/bash
set -euo pipefail

add() {
	echo "(add) Hey from script: $1"
}

remove() {
	echo "(remove) Hey from script: $1"
}

"$@"

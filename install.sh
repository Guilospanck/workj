#!/bin/bash
set -e
set -m

INSTALL_BIN="$HOME/.local/bin"
WORKJ="workj"

# Ensure directory exists
mkdir -p "$INSTALL_BIN"

if command -v zig >/dev/null 2>&1; then
	# build release mode
	zig build -Doptimize=ReleaseSafe

	# Install workj
	echo "Installing workj to $INSTALL_BIN..."
	cp zig-out/bin/$WORKJ "$INSTALL_BIN/$WORKJ"
	chmod +x "$INSTALL_BIN/$WORKJ"
	
	echo "workj is installed!"

else
    echo "Zig is NOT installed. Please install it first."
fi

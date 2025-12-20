# Run the built executable
run cmd branch:
  zig build run -- {{cmd}} {{branch}}

# Run all tests
tests:
  zig build test

# Run a specific test
#
# Example:
# `just test git gitWorktreeAdd`
# will be transformed into:
# `zig test --test-filter "gitWorktreeAdd" src/git_test.zig`
#
test file test_name:
  zig test --test-filter "{{test_name}}" src/{{file}}_test.zig

# Build the app
build:
  zig build

# Build the app in release mode
release:
  zig build -Doptimize=ReleaseSafe

# Install the app
install:
  ./install.sh


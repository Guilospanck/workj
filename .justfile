# Run the built executable
# Examples:
# just run add potato
# just run remove larry ./test/config.cfg
run cmd branch config="none":
  if [ "{{config}}" = "none" ]; then \
    zig build run -- {{cmd}} {{branch}}; \
  else \
    zig build run -- -c {{config}} {{cmd}} {{branch}}; \
  fi

# Run all tests
tests:
  zig build test

# Run a specific test in a specific file
#
# Example:
# `just test-t git gitWorktreeAdd`
# will be transformed into:
# `zig test --test-filter "gitWorktreeAdd" src/tests/git_test.zig`
#
test-t file test_name:
  zig test --test-filter "{{test_name}}" src/tests/{{file}}_test.zig

# Run a specific file
test file:
  zig test src/tests/{{file}}_test.zig

# Build the app
build:
  zig build

# Build the app in release mode
release:
  zig build -Doptimize=ReleaseSafe

# Install the app
install:
  ./install.sh


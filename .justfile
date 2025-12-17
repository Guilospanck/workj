run cmd branch:
  zig build run -- {{cmd}} {{branch}}

tests:
  zig build test

# Example:
# `just test git gitWorktreeAdd`
# will be transformed into:
# `zig test --test-filter "gitWorktreeAdd" src/git_test.zig`
test file test_name:
  zig test --test-filter "{{test_name}}" src/{{file}}_test.zig

build:
  zig build

release:
  zig build -Doptimize=ReleaseSafe

install:
  ./install.sh


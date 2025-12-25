# Run the built executable
# Examples:
# just run add potato
# just run remove larry -c ./test/config.cfg
# just run add feature/32 --force --dry-run
# just run remove potato --config-file ./config.cfg
# just run remove potato --config-file=./config.cfg
run cmd branch *args:
  #!/usr/bin/env sh

  set -eu

  config=""
  rest=()

  # Put variadic args into positional parameters
  set -- {{args}}

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -c)
        shift
        config="$1"
        shift
        ;;

      --config-file)
        shift
        config="$1"
        shift
        ;;

      --config-file=*)
        config="${1#*=}"
        shift
        ;;

      *)
        rest+=("$1")
        shift
        ;;
    esac
  done

  if [ -n "$config" ]; then
    zig build run -- -c "$config" {{cmd}} {{branch}} "${rest[@]}" 
  else
    zig build run -- {{cmd}} {{branch}} "${rest[@]}"
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


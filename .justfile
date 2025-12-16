run cmd branch:
  zig build run -- {{cmd}} {{branch}}

tests:
  zig build test

build:
  zig build

release:
  zig build -Doptimize=ReleaseSafe

install:
  ./install.sh


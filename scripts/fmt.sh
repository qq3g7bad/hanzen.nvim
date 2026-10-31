#!/bin/sh
# Format Lua files with stylua.
set -eu

cd "$(dirname "$0")/.."
stylua lua plugin tests

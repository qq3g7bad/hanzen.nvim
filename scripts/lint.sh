#!/bin/sh
# Check formatting with stylua (no changes are made).
set -eu

cd "$(dirname "$0")/.."
stylua --check lua plugin tests

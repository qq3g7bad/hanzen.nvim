#!/bin/sh
# Run the test suite with plenary.nvim (cloned into .deps/ on first run).
#
#   scripts/test.sh                        # all specs in tests/
#   scripts/test.sh tests/space_spec.lua   # one spec file
set -eu

cd "$(dirname "$0")/.."

plenary=.deps/plenary.nvim
if [ ! -d "$plenary" ]; then
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$plenary"
fi

target=${1:-tests/}
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory $target { minimal_init = 'tests/minimal_init.lua' }"

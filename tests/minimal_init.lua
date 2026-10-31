-- Minimal init for headless test runs (see scripts/test.sh).
--   nvim --headless --noplugin -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.getcwd() .. "/.deps/plenary.nvim")
vim.opt.swapfile = false

-- `--noplugin` skips plenary's plugin/plenary.vim, so :PlenaryBustedDirectory
-- is never defined and the headless `-c` hangs. Source it explicitly.
vim.cmd("runtime plugin/plenary.vim")

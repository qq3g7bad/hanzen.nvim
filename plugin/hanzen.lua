--
-- @file plugin/hanzen.lua
-- @brief Registers the :Hanzen user command.
--

if vim.g.loaded_hanzen then
  return
end
vim.g.loaded_hanzen = true

vim.api.nvim_create_user_command("Hanzen", function(cmd)
  require("hanzen").run(cmd)
end, {
  nargs = "?",
  range = true,
  bang = true,
  desc = "Japanese width normalization; ! = dry-run",
  complete = function(arglead)
    local out = {}
    for _, name in ipairs(require("hanzen").subcommands) do
      if name:find(arglead, 1, true) == 1 then
        out[#out + 1] = name
      end
    end
    return out
  end,
})

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

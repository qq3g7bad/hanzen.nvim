--
-- @file lua/hanzen/init.lua
-- @brief Public API and converter registry for hanzen.nvim.
--
-- Adding a converter = one module exposing `convert(text, ctx) -> text` plus
-- one line in `converters` below. The command layer never changes.
--

local M = {}

-- A closure (not a bare function ref) so it reads the current config at
-- call time, after a possible `setup()`. `flush` forces leading-indent
-- conversion regardless of the config — used internally by `flush-all`.
-- A segment that follows protected code is not at the line start, so its
-- U+3000 is never an indent.
local function make_space(flush)
  return function(text, ctx)
    local at_start = not (ctx and ctx.at_line_start == false)
    return require("hanzen.space").convert(text, {
      repeat_n = M.config.space_repeat,
      keep_leading_indent = not flush
        and at_start
        and M.config.space_keep_leading_indent,
    })
  end
end

---@type table<string, fun(text: string, ctx?: { at_line_start: boolean }): string>
local converters = {
  katakana = require("hanzen.katakana").convert,
  alphanum = require("hanzen.alphanum").convert,
  space = make_space(false),
  compat = require("hanzen.compat").convert,
  enclosed = require("hanzen.enclosed").convert,
}

-- `flush-all` substitutes this in place of `space`; not exposed as its own
-- subcommand because the only difference is the leading-indent override.
local flush_space = make_space(true)

-- Order used by the `all` / `flush-all` pseudo-converters. The byte ranges
-- are disjoint, so order does not affect the result; it only affects
-- reporting. `all` is the **complete** set of registered verbs — adding a
-- verb extends `all` by design (see README "Non-goals").
local ALL = { "katakana", "alphanum", "space", "compat", "enclosed" }

---@class hanzen.Config
---@field default string Subcommand used when `:Hanzen` is called with no argument.
---@field notify boolean Emit a `vim.notify` summary after running.
---@field space_repeat integer How many ASCII spaces each U+3000 becomes (`space`/`all`).
---@field space_keep_leading_indent boolean Keep a leading run of U+3000 (paragraph indent); default true.
---@field protect string Span provider: `"none"` (default) or `"treesitter"` (skip Markdown code).
M.config = {
  default = "katakana",
  notify = true,
  space_repeat = 1,
  space_keep_leading_indent = true,
  protect = "none",
}

---Subcommands exposed for `:Hanzen` completion.
M.subcommands = {
  "katakana",
  "alphanum",
  "space",
  "compat",
  "enclosed",
  "all",
  "flush-all",
}

---@param opts? hanzen.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function summarize(lnums)
  local max = 20
  if #lnums <= max then
    return table.concat(lnums, ", ")
  end
  return table.concat(vim.list_slice(lnums, 1, max), ", ")
    .. (", ... (+%d more)"):format(#lnums - max)
end

local function notify(result, name)
  if not M.config.notify then
    return
  end
  if result.degraded then
    vim.notify(
      "hanzen: treesitter unavailable; converted without code protection",
      vim.log.levels.WARN
    )
  end
  if result.blocked then
    vim.notify(
      ("hanzen: buffer is not modifiable (%s would change %d line(s))"):format(
        name,
        result.changed
      ),
      vim.log.levels.WARN
    )
  elseif result.changed == 0 then
    vim.notify(("hanzen: no %s changes"):format(name), vim.log.levels.INFO)
  elseif result.dry_run then
    vim.notify(
      ("hanzen: %s would change %d line(s): %s"):format(
        name,
        result.changed,
        summarize(result.lnums)
      ),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      ("hanzen: %s changed %d line(s)"):format(name, result.changed),
      vim.log.levels.INFO
    )
  end
end

---Programmatic API. Convert the current buffer (or a range).
---`line1`/`line2` are order-independent; pass them in any order.
---@param name string One of `katakana`, `alphanum`, `space`, `compat`, `enclosed`, `all`, `flush-all`.
---@param opts? { line1?: integer, line2?: integer, dry_run?: boolean, protect?: string }
---@return { changed: integer, lnums: integer[], dry_run: boolean, blocked: boolean, protect: string, degraded: boolean }
function M.convert(name, opts)
  opts = vim.tbl_extend("force", {}, opts or {})
  opts.protect = opts.protect or M.config.protect
  local engine = require("hanzen.convert")

  if name == "all" or name == "flush-all" then
    local total = {
      changed = 0,
      lnums = {},
      dry_run = opts.dry_run or false,
      blocked = false,
      protect = opts.protect,
      degraded = false,
    }
    local flush = (name == "flush-all")
    for _, key in ipairs(ALL) do
      local fn = (flush and key == "space") and flush_space or converters[key]
      local r = engine.apply(fn, opts)
      total.changed = total.changed + r.changed
      total.blocked = total.blocked or r.blocked
      total.degraded = total.degraded or r.degraded
      vim.list_extend(total.lnums, r.lnums)
    end
    return total
  end

  local fn = converters[name]
  if not fn then
    vim.notify(
      "hanzen: unknown converter '" .. tostring(name) .. "'",
      vim.log.levels.ERROR
    )
    return {
      changed = 0,
      lnums = {},
      dry_run = false,
      blocked = false,
      protect = opts.protect,
      degraded = false,
    }
  end

  return engine.apply(fn, opts)
end

---`:Hanzen[!] [subcommand]` entry point.
---@param cmd table Neovim user-command argument table.
function M.run(cmd)
  local name = (cmd.fargs and cmd.fargs[1]) or M.config.default
  if not (name == "all" or name == "flush-all" or converters[name]) then
    vim.notify(
      ("hanzen: unknown subcommand '%s' (expected: %s)"):format(
        tostring(name),
        table.concat(M.subcommands, ", ")
      ),
      vim.log.levels.ERROR
    )
    return
  end

  local opts = { dry_run = cmd.bang or false }
  if cmd.range and cmd.range > 0 then
    opts.line1 = cmd.line1
    opts.line2 = cmd.line2
  end

  notify(M.convert(name, opts), name)
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

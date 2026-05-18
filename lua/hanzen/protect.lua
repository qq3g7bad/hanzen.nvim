--
-- @file lua/hanzen/protect.lua
-- @brief Compute "protected" character spans the engine must not convert.
--
-- A provider maps a buffer to a list of 0-indexed, end-exclusive
-- { srow, scol, erow, ecol } spans. The engine converts only the text
-- *outside* these spans.
--
-- Modes:
--   "none"       -> {} (default; you scope conversions with a range)
--   "treesitter" -> Markdown fenced/indented code blocks and inline code
--                   spans, when a parser is available. If it is not, this
--                   degrades to {} and reports it -- it never guesses.
--
-- treesitter's *runtime* is in Neovim core; only the `markdown` /
-- `markdown_inline` grammars are external (bundled with Neovim >= 0.10).
-- Keeping the default "none" is what preserves the zero-dependency stance.
--

local M = {}

-- Node types to leave untouched, per tree-sitter language.
local QUERY = {
  markdown = "[(fenced_code_block) (indented_code_block)] @p",
  markdown_inline = "(code_span) @p",
}

-- Returns a span list, or nil if a markdown parser could not be obtained
-- (any treesitter error degrades to nil -- a failed parse must never break
-- an edit).
local function treesitter_spans(buf)
  if not (vim.treesitter and vim.treesitter.get_parser) then
    return nil
  end
  local ok, spans = pcall(function()
    local parser = vim.treesitter.get_parser(buf, "markdown")
    if not parser then
      return nil
    end
    parser:parse(true) -- include injected markdown_inline trees
    local acc = {}
    parser:for_each_tree(function(tree, ltree)
      local src = QUERY[ltree:lang()]
      if not src then
        return
      end
      local query = vim.treesitter.query.parse(ltree:lang(), src)
      for _, node in query:iter_captures(tree:root(), buf) do
        local sr, sc, er, ec = node:range()
        acc[#acc + 1] = { sr, sc, er, ec }
      end
    end)
    return acc
  end)
  if not ok then
    return nil
  end
  return spans
end

---@param buf integer
---@param mode? "none"|"treesitter"
---@return table spans  list of {srow,scol,erow,ecol} (0-indexed, end-exclusive)
---@return boolean degraded  true if a non-"none" mode could not be honored
function M.spans(buf, mode)
  if mode == "treesitter" then
    local s = treesitter_spans(buf)
    if s == nil then
      return {}, true
    end
    return s, false
  end
  return {}, false
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

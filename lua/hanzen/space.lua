--
-- @file lua/hanzen/space.lua
-- @brief Convert the fullwidth (ideographic) space U+3000 to ASCII space(s).
--
-- Direction: zen -> han. Touches *only* U+3000 (UTF-8 E3 80 80) -- it does
-- not collapse other whitespace or rewrite existing ASCII spaces.
--
-- A fullwidth space is one CJK column wide (~2 ASCII columns), so the
-- replacement count is configurable via `repeat_n` (default 1, the
-- NFKC-style mapping). A run of U+3000 at the start of the line is
-- preserved by default (`keep_leading_indent`, default true) -- Japanese
-- prose uses it for paragraph indentation, which the writer almost always
-- *intends* to keep; pass `keep_leading_indent = false` to convert it too.
--

local M = {}

local FW = "\227\128\128" -- U+3000 in UTF-8 (E3 80 80)

---Convert the fullwidth space to ASCII space(s).
---"Leading" is the start of `text`. The engine passes a whole line, or a
---segment of one between protected spans; for a segment that does not
---start the line, the caller turns `keep_leading_indent` off.
---@param text string A line, or a segment of one.
---@param opts? { repeat_n?: integer, keep_leading_indent?: boolean }
---@return string
function M.convert(text, opts)
  opts = opts or {}
  local n = opts.repeat_n or 1
  if n < 0 then
    n = 0
  end
  local replacement = (" "):rep(n)

  -- Default ON: only an explicit `false` opts out of indent preservation.
  local keep = opts.keep_leading_indent
  if keep == nil then
    keep = true
  end

  -- FW is all bytes >= 0x80, so it carries no Lua pattern magic and a plain
  -- gsub is exact (same reasoning as the katakana map).
  if not keep then
    return (text:gsub(FW, replacement))
  end

  -- A Lua pattern cannot express "a repeated 3-byte literal" (`*` binds to
  -- one byte), so the leading U+3000 run is sliced off explicitly, kept
  -- verbatim, and only the remainder is converted. The Vim-regex spelling
  -- of this is `:s/\%(^　*\)\@<!　/ /g` -- the converter just does it per
  -- line, so non-regex users get it for free via `:Hanzen space`.
  local i = 1
  while text:sub(i, i + 2) == FW do
    i = i + 3
  end
  local lead, rest = text:sub(1, i - 1), text:sub(i)
  return lead .. (rest:gsub(FW, replacement))
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

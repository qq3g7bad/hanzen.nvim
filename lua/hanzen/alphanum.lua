--
-- @file lua/hanzen/alphanum.lua
-- @brief Convert fullwidth (zenkaku) ASCII to halfwidth (hankaku) ASCII.
--
-- Direction: zen -> han. Covers the fullwidth ASCII block U+FF01..U+FF5E
-- (letters, digits, and symbols). The fullwidth space U+3000 is a
-- different prefix (E3 80 80) and is deliberately left untouched.
--
-- Unlike NFKC normalization, this touches *only* this block: it will not
-- rewrite circled numbers, era ligatures, fullwidth brackets, etc.
--

local M = {}

-- Fullwidth ASCII is contiguous: codepoint - 0xFEE0 == ASCII. In UTF-8
-- the block splits across two 3-byte prefixes, so a single arithmetic
-- gsub per prefix covers every character without a lookup table.
--
--   U+FF01..U+FF3F  ->  EF BC 81..BF   ascii = byte3 - 0x60
--   U+FF40..U+FF5E  ->  EF BD 80..9E   ascii = byte3 - 0x20
---Convert fullwidth ASCII to halfwidth ASCII.
---@param text string
---@return string
function M.convert(text)
  local out = text

  out = out:gsub("\239\188([\129-\191])", function(c)
    return string.char(c:byte() - 0x60)
  end)

  out = out:gsub("\239\189([\128-\158])", function(c)
    return string.char(c:byte() - 0x20)
  end)

  return out
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

--
-- @file lua/hanzen/katakana.lua
-- @brief Convert halfwidth (hankaku) katakana to fullwidth (zenkaku) katakana.
--
-- Direction: han -> zen. Operates only on the halfwidth katakana block
-- (U+FF61..U+FF9F), so it is independent of the alphanum converter.
--

local M = {}

-- Composite sequences (base kana + dakuten/handakuten) must be replaced
-- before the single-character map, otherwise e.g. "ｶﾞ" would degrade to
-- "カ゛" instead of composing into "ガ".
local COMPOSITE_MAP = {
  ["ｳﾞ"] = "ヴ",
  ["ｶﾞ"] = "ガ",
  ["ｷﾞ"] = "ギ",
  ["ｸﾞ"] = "グ",
  ["ｹﾞ"] = "ゲ",
  ["ｺﾞ"] = "ゴ",
  ["ｻﾞ"] = "ザ",
  ["ｼﾞ"] = "ジ",
  ["ｽﾞ"] = "ズ",
  ["ｾﾞ"] = "ゼ",
  ["ｿﾞ"] = "ゾ",
  ["ﾀﾞ"] = "ダ",
  ["ﾁﾞ"] = "ヂ",
  ["ﾂﾞ"] = "ヅ",
  ["ﾃﾞ"] = "デ",
  ["ﾄﾞ"] = "ド",
  ["ﾊﾞ"] = "バ",
  ["ﾋﾞ"] = "ビ",
  ["ﾌﾞ"] = "ブ",
  ["ﾍﾞ"] = "ベ",
  ["ﾎﾞ"] = "ボ",
  ["ﾊﾟ"] = "パ",
  ["ﾋﾟ"] = "ピ",
  ["ﾌﾟ"] = "プ",
  ["ﾍﾟ"] = "ペ",
  ["ﾎﾟ"] = "ポ",
  ["ﾜﾞ"] = "ヷ",
  ["ｦﾞ"] = "ヺ",
}

local SINGLE_MAP = {
  ["｡"] = "。",
  ["｢"] = "「",
  ["｣"] = "」",
  ["､"] = "、",
  ["･"] = "・",
  ["ｦ"] = "ヲ",
  ["ｧ"] = "ァ",
  ["ｨ"] = "ィ",
  ["ｩ"] = "ゥ",
  ["ｪ"] = "ェ",
  ["ｫ"] = "ォ",
  ["ｬ"] = "ャ",
  ["ｭ"] = "ュ",
  ["ｮ"] = "ョ",
  ["ｯ"] = "ッ",
  ["ｰ"] = "ー",
  ["ｱ"] = "ア",
  ["ｲ"] = "イ",
  ["ｳ"] = "ウ",
  ["ｴ"] = "エ",
  ["ｵ"] = "オ",
  ["ｶ"] = "カ",
  ["ｷ"] = "キ",
  ["ｸ"] = "ク",
  ["ｹ"] = "ケ",
  ["ｺ"] = "コ",
  ["ｻ"] = "サ",
  ["ｼ"] = "シ",
  ["ｽ"] = "ス",
  ["ｾ"] = "セ",
  ["ｿ"] = "ソ",
  ["ﾀ"] = "タ",
  ["ﾁ"] = "チ",
  ["ﾂ"] = "ツ",
  ["ﾃ"] = "テ",
  ["ﾄ"] = "ト",
  ["ﾅ"] = "ナ",
  ["ﾆ"] = "ニ",
  ["ﾇ"] = "ヌ",
  ["ﾈ"] = "ネ",
  ["ﾉ"] = "ノ",
  ["ﾊ"] = "ハ",
  ["ﾋ"] = "ヒ",
  ["ﾌ"] = "フ",
  ["ﾍ"] = "ヘ",
  ["ﾎ"] = "ホ",
  ["ﾏ"] = "マ",
  ["ﾐ"] = "ミ",
  ["ﾑ"] = "ム",
  ["ﾒ"] = "メ",
  ["ﾓ"] = "モ",
  ["ﾔ"] = "ヤ",
  ["ﾕ"] = "ユ",
  ["ﾖ"] = "ヨ",
  ["ﾗ"] = "ラ",
  ["ﾘ"] = "リ",
  ["ﾙ"] = "ル",
  ["ﾚ"] = "レ",
  ["ﾛ"] = "ロ",
  ["ﾜ"] = "ワ",
  ["ﾝ"] = "ン",
  ["ﾞ"] = "゛",
  ["ﾟ"] = "゜",
}

-- Halfwidth katakana is encoded as 3-byte UTF-8 with every byte >= 0x80,
-- so none of the map keys contain Lua pattern magic characters and plain
-- gsub is safe.
---Convert halfwidth katakana to fullwidth katakana.
---@param text string
---@return string
function M.convert(text)
  local out = text

  for half, full in pairs(COMPOSITE_MAP) do
    out = out:gsub(half, full)
  end

  for half, full in pairs(SINGLE_MAP) do
    out = out:gsub(half, full)
  end

  return out
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

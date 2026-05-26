local c = require("hanzen.compat")

describe("compat (CJK Compatibility decomposition)", function()
  it("decomposes era ligatures", function()
    assert.equals("平成", c.convert("㍻"))
    assert.equals("昭和", c.convert("㍼"))
    assert.equals("大正", c.convert("㍽"))
    assert.equals("明治", c.convert("㍾"))
  end)

  it("decomposes 株式会社", function()
    assert.equals("株式会社", c.convert("㍿"))
  end)

  it("decomposes SI/unit ligatures", function()
    assert.equals("kg", c.convert("㎏"))
    assert.equals("mm", c.convert("㎜"))
    assert.equals("m2", c.convert("㎡"))
    assert.equals("Hz", c.convert("㎐"))
  end)

  it("decomposes square katakana abbreviations", function()
    assert.equals("アール", c.convert("㌃"))
    assert.equals("トン", c.convert("㌧"))
    assert.equals("メートル", c.convert("㍍"))
  end)

  it("decomposes day-of-month and score lookups", function()
    assert.equals("1日", c.convert("㏠"))
    assert.equals("31日", c.convert("㏾"))
    assert.equals("0点", c.convert("㍘"))
  end)

  it("handles a mixed sentence", function()
    assert.equals(
      "今日は平成 30 年、体重はkg 表示。",
      c.convert("今日は㍻ 30 年、体重は㎏ 表示。")
    )
  end)

  it("leaves out-of-block characters untouched", function()
    -- ① is U+2460 (Enclosed Alphanumerics); ❶ is U+2776; ㊀ is U+3280
    -- (Enclosed CJK Letters and Months) — all outside U+3300..U+33FF.
    assert.equals("①❶㊀", c.convert("①❶㊀"))
    assert.equals("ABC ascii", c.convert("ABC ascii"))
    assert.equals(
      "日本語のテキスト",
      c.convert("日本語のテキスト")
    )
  end)

  it("leaves ㋿ (Reiwa, U+32FF) untouched — different block", function()
    -- 令和 is in the Enclosed CJK block (U+3200..U+32FF), handled by the
    -- `enclosed` verb. `compat` is strictly U+3300..U+33FF, so ㋿ falls
    -- through this verb unchanged — the block boundary is the contract.
    assert.equals("㋿", c.convert("㋿"))
  end)

  it("converts every codepoint in U+3300..U+33FF (sanity)", function()
    -- All 256 codepoints in the block have a non-identity NFKD; verify
    -- the map covers them so a future Unicode revision can't silently
    -- regress to identity.
    for cp = 0x3300, 0x33FF do
      local ch = vim.fn.nr2char(cp)
      local got = c.convert(ch)
      assert.are_not.equal(ch, got)
    end
  end)
end)

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

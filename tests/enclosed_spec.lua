local e = require("hanzen.enclosed")

describe("enclosed (CJK enclosed letters & months)", function()
  it("decomposes parenthesized corporate abbreviations", function()
    assert.equals("(株)", e.convert("㈱"))
    assert.equals("(有)", e.convert("㈲"))
    assert.equals("(社)", e.convert("㈳"))
  end)

  it("decomposes parenthesized numerals and weekday markers", function()
    assert.equals("(一)", e.convert("㈠"))
    assert.equals("(十)", e.convert("㈩"))
    assert.equals("(月)", e.convert("㈪"))
    assert.equals("(日)", e.convert("㈰"))
  end)

  it("decomposes circled ideographs", function()
    assert.equals("一", e.convert("㊀"))
    assert.equals("秘", e.convert("㊙"))
    assert.equals("男", e.convert("㊚"))
    assert.equals("女", e.convert("㊛"))
    assert.equals("株", e.convert("㊑"))
  end)

  it("decomposes enclosed numerals 21..50", function()
    assert.equals("21", e.convert("㉑"))
    assert.equals("35", e.convert("㉟"))
    assert.equals("50", e.convert("㊿"))
  end)

  it("decomposes circled month abbreviations", function()
    assert.equals("1月", e.convert("㋀"))
    assert.equals("12月", e.convert("㋋"))
  end)

  it("decomposes circled katakana", function()
    assert.equals("ア", e.convert("㋐"))
    assert.equals("ヲ", e.convert("㋾"))
  end)

  it("decomposes ㋿ to 令和 (Reiwa era)", function()
    assert.equals("令和", e.convert("㋿"))
  end)

  it("handles a mixed sentence (real-world business form)", function()
    assert.equals(
      "(株)山田商事 (有)鈴木工業 秘書類 注意:21名以上",
      e.convert("㈱山田商事 ㈲鈴木工業 ㊙書類 注意:㉑名以上")
    )
  end)

  it("leaves out-of-block characters untouched", function()
    -- ① is U+2460 (Enclosed Alphanumerics, a *different* block);
    -- ㍻ is U+337B (CJK Compatibility, handled by `compat`).
    assert.equals("①㍻ABC", e.convert("①㍻ABC"))
    assert.equals(
      "日本語のテキスト",
      e.convert("日本語のテキスト")
    )
  end)
end)

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

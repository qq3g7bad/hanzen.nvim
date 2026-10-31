local k = require("hanzen.katakana")

describe("katakana han -> zen", function()
  it("converts plain katakana", function()
    assert.equals("アイウエオ", k.convert("ｱｲｳｴｵ"))
  end)

  it("composes dakuten", function()
    assert.equals(
      "ガギグゲゴ",
      k.convert("ｶﾞｷﾞｸﾞｹﾞｺﾞ")
    )
    assert.equals("ヴ", k.convert("ｳﾞ"))
    assert.equals("ヷ ヺ", k.convert("ﾜﾞ ｦﾞ"))
  end)

  it("composes handakuten", function()
    assert.equals(
      "パピプペポ",
      k.convert("ﾊﾟﾋﾟﾌﾟﾍﾟﾎﾟ")
    )
  end)

  it("converts small kana and punctuation", function()
    assert.equals(
      "ッャュョ。「」、・ー",
      k.convert("ｯｬｭｮ｡｢｣､･ｰ")
    )
  end)

  it("splits a mark that has no composite", function()
    assert.equals("ア゛", k.convert("ｱﾞ"))
    assert.equals("゛゜", k.convert("ﾞﾟ"))
    assert.equals("ガ゛", k.convert("ｶﾞﾞ"))
  end)

  it("leaves the rest of the U+FF40..U+FFBF range alone", function()
    -- fullwidth ｚ (U+FF5A) and halfwidth hangul ﾡ (U+FFA1) share the
    -- katakana lead bytes but are not katakana
    assert.equals("ｚﾡ", k.convert("ｚﾡ"))
  end)

  it("leaves ascii and fullwidth text alone", function()
    assert.equals("Hello 日本語 123", k.convert("Hello 日本語 123"))
  end)

  it("handles a mixed sentence", function()
    assert.equals(
      "テストです（カタカナ）",
      k.convert("ﾃｽﾄです（ｶﾀｶﾅ）")
    )
  end)
end)

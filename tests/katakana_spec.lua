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

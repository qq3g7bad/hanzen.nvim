local a = require("hanzen.alphanum")

describe("alphanum zen -> han", function()
  it("converts uppercase letters", function()
    assert.equals("ABCXYZ", a.convert("ＡＢＣＸＹＺ"))
  end)

  it("converts lowercase letters", function()
    assert.equals("abcxyz", a.convert("ａｂｃｘｙｚ"))
  end)

  it("converts digits", function()
    assert.equals("0123456789", a.convert("０１２３４５６７８９"))
  end)

  it("converts symbols", function()
    assert.equals(
      "!@#$%()[]{}+-=_~",
      a.convert("！＠＃＄％（）［］｛｝＋－＝＿～")
    )
  end)

  it("leaves the fullwidth space untouched", function()
    -- U+3000 == \227\128\128 ; must NOT become an ASCII space.
    assert.equals("\227\128\128", a.convert("\227\128\128"))
  end)

  it("leaves katakana and kanji alone", function()
    assert.equals("アイウ日本語", a.convert("アイウ日本語"))
  end)

  it("handles a mixed sentence", function()
    assert.equals(
      "version 2.0 (RC1) 日本語",
      a.convert("ｖｅｒｓｉｏｎ ２．０ （ＲＣ１） 日本語")
    )
  end)
end)

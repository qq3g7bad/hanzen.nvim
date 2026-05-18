local s = require("hanzen.space")

describe("space zen -> han", function()
  local FW = "\227\128\128" -- U+3000

  it("converts a fullwidth space to one ASCII space by default", function()
    assert.equals("A B", s.convert("A" .. FW .. "B"))
  end)

  it("honors repeat_n for width-preserving output", function()
    assert.equals("A  B", s.convert("A" .. FW .. "B", { repeat_n = 2 }))
  end)

  it("repeat_n = 0 deletes the fullwidth space", function()
    assert.equals("AB", s.convert("A" .. FW .. "B", { repeat_n = 0 }))
  end)

  it("leaves ASCII spaces and other text alone", function()
    assert.equals("a b 日本語", s.convert("a b 日本語"))
  end)

  it("keeps a leading U+3000 run by default (default ON)", function()
    assert.equals(FW .. FW .. "x y", s.convert(FW .. FW .. "x" .. FW .. "y"))
  end)

  it("keep_leading_indent = false converts every fullwidth space", function()
    assert.equals(
      " x y",
      s.convert(FW .. "x" .. FW .. "y", { keep_leading_indent = false })
    )
  end)

  it("with no leading run, keep_leading_indent still converts all", function()
    assert.equals(
      "x y",
      s.convert("x" .. FW .. "y", { keep_leading_indent = true })
    )
  end)
end)

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

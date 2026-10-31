local protect = require("hanzen.protect")

local function md_buf(lines, ft)
  local b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].filetype = ft or "markdown"
  return b
end

local function ts_ok(buf)
  return pcall(vim.treesitter.get_parser, buf, "markdown")
end

describe("protect provider", function()
  it("'none' returns no spans and is not degraded", function()
    local b = md_buf({ "ＡＢＣ" })
    local spans, degraded = protect.spans(b, "none")
    assert.same({}, spans)
    assert.is_false(degraded)
  end)

  it("nil mode behaves like 'none'", function()
    local b = md_buf({ "ＡＢＣ" })
    local spans, degraded = protect.spans(b, nil)
    assert.same({}, spans)
    assert.is_false(degraded)
  end)

  it("degrades (not crashes) when treesitter is unavailable", function()
    local b = md_buf({ "`code`" })
    local real = vim.treesitter.get_parser
    vim.treesitter.get_parser = function()
      error("simulated: no parser")
    end
    local spans, degraded = protect.spans(b, "treesitter")
    vim.treesitter.get_parser = real
    assert.same({}, spans)
    assert.is_true(degraded)
  end)

  it("marks Markdown code regions when a parser is available", function()
    local b = md_buf({
      "prose ＡＢＣ and `ＸＹＺ` inline",
      "",
      "```",
      "ＡＢＣ in a fence",
      "```",
    })
    if not ts_ok(b) then
      pending("markdown treesitter parser not installed")
      return
    end
    local spans, degraded = protect.spans(b, "treesitter")
    assert.is_false(degraded)
    assert.is_true(#spans >= 2) -- inline code span + fenced block
  end)

  it("protects nothing in a non-Markdown buffer", function()
    -- Parsed as Markdown, the indented line would be an indented code block.
    local b = md_buf({ "x", "", "    'ＡＢＣ'" }, "python")
    local spans, degraded = protect.spans(b, "treesitter")
    assert.same({}, spans)
    assert.is_false(degraded)
  end)
end)

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

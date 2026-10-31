local hanzen = require("hanzen")

local function set_buf(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function get_buf()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("buffer / range engine", function()
  before_each(function()
    vim.cmd("enew!")
  end)

  it("converts the whole buffer by default", function()
    set_buf({ "ｱｲｳ", "ＡＢＣ" })
    local r = hanzen.convert("katakana")
    assert.equals(1, r.changed)
    assert.same({ "アイウ", "ＡＢＣ" }, get_buf())
  end)

  it("respects a line range", function()
    set_buf({ "ｱ", "ｲ", "ｳ" })
    hanzen.convert("katakana", { line1 = 2, line2 = 2 })
    assert.same({ "ｱ", "イ", "ｳ" }, get_buf())
  end)

  it("normalizes a reversed line range", function()
    set_buf({ "ｱ", "ｲ", "ｳ", "ｴ" })
    local r = hanzen.convert("katakana", { line1 = 3, line2 = 1 })
    assert.equals(3, r.changed)
    assert.same({ "ア", "イ", "ウ", "ｴ" }, get_buf())
  end)

  it("dry_run reports without mutating the buffer", function()
    set_buf({ "ＡＢＣ", "x" })
    local r = hanzen.convert("alphanum", { dry_run = true })
    assert.equals(1, r.changed)
    assert.same({ 1 }, r.lnums)
    assert.same({ "ＡＢＣ", "x" }, get_buf())
  end)

  it(
    "'all' applies every converter (kana, ascii, space, compat, enclosed)",
    function()
      -- ｱ + U+3000 + ＡＢＣ + ㍻ + ㈱: katakana, space, alphanum, compat,
      -- enclosed. 'all' is the **complete** verb set — every registered
      -- converter runs; see README "Non-goals".
      set_buf({ "ｱ" .. "\227\128\128" .. "ＡＢＣ" .. "㍻" .. "㈱" })
      hanzen.convert("all")
      assert.same({ "ア ABC平成(株)" }, get_buf())
    end
  )

  it("'all' counts a line once however many verbs touch it", function()
    set_buf({ "ｱＡ㍻", "x", "ＢＢ", "ｲ" .. "\227\128\128" .. "㈱" })
    local r = hanzen.convert("all", { dry_run = true })
    assert.equals(3, r.changed)
    assert.same({ 1, 3, 4 }, r.lnums)
  end)

  it("preserves leading fullwidth indent by default", function()
    local FW = "\227\128\128" -- U+3000
    -- leading indent (2x U+3000) kept; interior U+3000 -> one ASCII space
    set_buf({ FW .. FW .. "あ" .. FW .. "い" })
    hanzen.convert("space")
    assert.same({ FW .. FW .. "あ い" }, get_buf())
  end)

  it("flush-all converts leading U+3000 too", function()
    local FW = "\227\128\128" -- U+3000
    -- same input as the test above; flush-all collapses everything
    set_buf({ FW .. FW .. "あ" .. FW .. "い" })
    hanzen.convert("flush-all")
    assert.same({ "  あ い" }, get_buf())
  end)

  it("flush-all also runs katakana + alphanum", function()
    local FW = "\227\128\128" -- U+3000
    set_buf({ FW .. "ｱ" .. FW .. "ＡＢＣ" })
    hanzen.convert("flush-all")
    assert.same({ " ア ABC" }, get_buf())
  end)

  it("keeps marks and extmarks on unchanged lines", function()
    set_buf({ "hello world", "ＡＢＣ" })
    local ns = vim.api.nvim_create_namespace("hanzen_test")
    local id = vim.api.nvim_buf_set_extmark(0, ns, 0, 6, {})
    vim.fn.setpos("'a", { 0, 1, 7, 0 })
    hanzen.convert("alphanum")
    assert.same({ 0, 6 }, vim.api.nvim_buf_get_extmark_by_id(0, ns, id, {}))
    assert.same({ 0, 1, 7, 0 }, vim.fn.getpos("'a"))
  end)

  it("keeps an extmark before the edit on a changed line", function()
    set_buf({ "ab ＡＢＣ" })
    local ns = vim.api.nvim_create_namespace("hanzen_test")
    local id = vim.api.nvim_buf_set_extmark(0, ns, 0, 1, {})
    hanzen.convert("alphanum")
    assert.same({ "ab ABC" }, get_buf())
    assert.same({ 0, 1 }, vim.api.nvim_buf_get_extmark_by_id(0, ns, id, {}))
  end)

  it("undoes 'all' in one step", function()
    set_buf({ "ｱＡ", "x", "㍻" .. "\227\128\128" .. "㈱" })
    vim.bo.undolevels = vim.bo.undolevels -- close the set_buf undo step
    local before = vim.fn.undotree().seq_last
    hanzen.convert("all")
    vim.bo.undolevels = vim.bo.undolevels
    assert.equals(before + 1, vim.fn.undotree().seq_last)
    vim.cmd("silent undo")
    assert.same({ "ｱＡ", "x", "㍻" .. "\227\128\128" .. "㈱" }, get_buf())
  end)

  it("keeps the cursor on the same character", function()
    local function char_at_cursor()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      return vim.fn.strcharpart(get_buf()[1]:sub(col + 1), 0, 1)
    end
    set_buf({ "ＡＢＣあいう" })
    vim.api.nvim_win_set_cursor(0, { 1, 12 }) -- on い, after the edit
    hanzen.convert("alphanum")
    assert.equals("い", char_at_cursor())

    set_buf({ "ＡＢＣあいう" })
    vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- on Ｃ, inside the edit
    hanzen.convert("alphanum")
    assert.equals("C", char_at_cursor())
  end)

  it("reports a non-modifiable buffer instead of erroring", function()
    set_buf({ "ＡＢＣ" })
    vim.bo.modifiable = false
    local r = hanzen.convert("alphanum")
    vim.bo.modifiable = true
    assert.is_true(r.blocked)
    assert.same({ "ＡＢＣ" }, get_buf())
  end)
end)

describe("engine: protected-span segmentation", function()
  local engine = require("hanzen.convert")
  local up = function(s)
    return (s:gsub("a", "A"))
  end

  it("no intervals -> whole line through text_fn", function()
    assert.equals("AAA", engine._convert_line("aaa", {}, up))
  end)

  it("leaves a mid-line protected span verbatim", function()
    assert.equals("AAaaAA", engine._convert_line("aaaaaa", { { 2, 4 } }, up))
  end)

  it("handles a protected span at the start", function()
    assert.equals("aaAA", engine._convert_line("aaaa", { { 0, 2 } }, up))
  end)

  it("handles a protected span at the end", function()
    assert.equals("AAaa", engine._convert_line("aaaa", { { 2, 4 } }, up))
  end)

  it("tells text_fn whether each segment starts the line", function()
    local seen = {}
    engine._convert_line("aabbaa", { { 2, 4 } }, function(text, ctx)
      seen[#seen + 1] = ctx.at_line_start
      return text
    end)
    assert.same({ true, false }, seen)
    engine._convert_line("aa", {}, function(text, ctx)
      seen[#seen + 1] = ctx.at_line_start
      return text
    end)
    assert.same({ true, false, true }, seen)
  end)

  it("handles multiple protected spans", function()
    assert.equals(
      "AaAaA",
      engine._convert_line("aaaaa", { { 1, 2 }, { 3, 4 } }, up)
    )
  end)
end)

describe("engine: treesitter protect (integration)", function()
  local function ts_md_ok()
    local b = vim.api.nvim_create_buf(false, true)
    local ok = pcall(vim.treesitter.get_parser, b, "markdown")
    vim.api.nvim_buf_delete(b, { force = true })
    return ok
  end

  before_each(function()
    vim.cmd("enew!")
    vim.bo.filetype = "markdown"
  end)

  it("skips Markdown code, converts prose", function()
    if not ts_md_ok() then
      pending("markdown treesitter parser not installed")
      return
    end
    set_buf({
      "prose ＡＢＣ `ＸＹＺ`",
      "```",
      "ＡＢＣ fenced",
      "```",
    })
    local r = hanzen.convert("alphanum", { protect = "treesitter" })
    assert.is_false(r.degraded)
    assert.same({
      "prose ABC `ＸＹＺ`",
      "```",
      "ＡＢＣ fenced",
      "```",
    }, get_buf())
  end)

  it(
    "reports degraded but still converts when treesitter is unavailable",
    function()
      set_buf({ "ＡＢＣ" })
      local real = vim.treesitter.get_parser
      vim.treesitter.get_parser = function()
        error("simulated: no parser")
      end
      local r = hanzen.convert("alphanum", { protect = "treesitter" })
      vim.treesitter.get_parser = real
      assert.is_true(r.degraded)
      assert.same({ "ABC" }, get_buf())
    end
  )

  it("treats U+3000 after inline code as interior, not indent", function()
    if not ts_md_ok() then
      pending("markdown treesitter parser not installed")
      return
    end
    local FW = "\227\128\128" -- U+3000
    set_buf({ "`x`" .. FW .. "a", FW .. FW .. "`x`" .. FW .. "a" })
    hanzen.convert("space", { protect = "treesitter" })
    assert.same({ "`x` a", FW .. FW .. "`x` a" }, get_buf())
  end)

  it("converts every line of a non-Markdown buffer", function()
    vim.bo.filetype = "python"
    set_buf({ "def f():", "", "    s = 'ＡＢＣ'  # `ＤＥＦ`" })
    local r = hanzen.convert("alphanum", { protect = "treesitter" })
    assert.is_false(r.degraded)
    assert.same({ "def f():", "", "    s = 'ABC'  # `DEF`" }, get_buf())
  end)
end)

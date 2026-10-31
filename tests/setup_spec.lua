local hanzen = require("hanzen")

describe("setup()", function()
  local saved, real_notify, messages

  before_each(function()
    saved = vim.deepcopy(hanzen.config)
    messages = {}
    real_notify = vim.notify
    vim.notify = function(msg, level)
      messages[#messages + 1] = { msg = msg, level = level }
    end
  end)

  after_each(function()
    vim.notify = real_notify
    hanzen.config = saved
  end)

  it("merges valid options", function()
    hanzen.setup({ protect = "treesitter", space_repeat = 2 })
    assert.equals("treesitter", hanzen.config.protect)
    assert.equals(2, hanzen.config.space_repeat)
    assert.equals("katakana", hanzen.config.default)
    assert.same({}, messages)
  end)

  for _, bad in ipairs({
    { protect = "markdown" },
    { default = "nope" },
    { space_repeat = -1 },
    { space_repeat = 1.5 },
    { notify = "yes" },
    { space_keep_leading_indent = 0 },
  }) do
    it(
      "rejects " .. vim.inspect(bad, { newline = " ", indent = "" }),
      function()
        local before = vim.deepcopy(hanzen.config)
        hanzen.setup(vim.tbl_extend("force", { space_repeat = 3 }, bad))
        assert.same(before, hanzen.config) -- nothing applied, not even the valid key
        assert.equals(1, #messages)
        assert.equals(vim.log.levels.ERROR, messages[1].level)
        assert.truthy(messages[1].msg:find(next(bad), 1, true))
      end
    )
  end
end)

describe("subcommands", function()
  it("lists every verb, then all and flush-all", function()
    assert.same({
      "katakana",
      "alphanum",
      "space",
      "compat",
      "enclosed",
      "all",
      "flush-all",
    }, hanzen.subcommands)
  end)
end)

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

# hanzen.nvim

Selective, dependency-free Japanese character-width **conversion** for
Neovim — one direction at a time, on demand.

> Unicode **NFKC** folds every width difference at once, and is the right
> tool when that is what you want. hanzen deliberately does less: it
> changes only the block you ask for, only when you ask — a scalpel, not a
> rule.

Each subcommand is one directional verb:

| Subcommand | Direction         | What it touches                                                                        |
| ---------- | ----------------- | -------------------------------------------------------------------------------------- |
| `katakana` | hankaku → zenkaku | `ｱｲｳ ｶﾞ ﾊﾟ` → `アイウ ガ パ` (halfwidth katakana, with dakuten/handakuten composition) |
| `alphanum` | zenkaku → hankaku | `ＡＢＣ １２３ ！＠＃` → `ABC 123 !@#` (fullwidth ASCII letters, digits, symbols)      |
| `space`    | zenkaku → hankaku | `A　B` → `A B` (fullwidth space U+3000 → ASCII space; width & leading-indent configurable) |
| `all`      | every block       | runs `katakana`, then `alphanum`, then `space`                                          |

The fullwidth space `　` (U+3000) is touched **only** by `space` (and therefore
by `all`); `katakana`/`alphanum` never touch it. Each converted U+3000 becomes
**one** ASCII space (`space_repeat` changes the count). A run of U+3000 at the
**start of a line** — Japanese paragraph indentation — is **preserved by
default**; set `space_keep_leading_indent = false` to convert those too.

## Why not just NFKC?

Unicode **NFKC** normalization performs both of these conversions — and it is
the right tool when you want *everything* folded at once. `hanzen.nvim` exists
for the case NFKC cannot express:

- **NFKC is monolithic and bidirectional in a fixed way.** It always maps
  fullwidth ASCII → halfwidth **and** halfwidth kana → fullwidth
  simultaneously. You cannot ask it to fix only stray halfwidth katakana while
  leaving your text alone, or vice versa. `:Hanzen katakana` /
  `:Hanzen alphanum` are independent, directional verbs.
- **NFKC rewrites far more than you may want.** `①`→`1`, `㍻`→`平成`,
  `™` ligatures, fullwidth brackets `（）`→`()` — changes a Markdown author
  often *intends* to keep. `hanzen.nvim` touches only the halfwidth-katakana
  block and the fullwidth-ASCII block, nothing else.
- **Zero runtime dependencies.** Pure Lua — nothing to install, nothing
  to shell out to.
- **In-editor and range-aware.** `:Hanzen <Tab>` completion, dry-run
  preview, visual/range scoping, and a small Lua API for your own keymaps.

Outside the editor, batch tools like `nkf`, `jaconv`, and `mojimoji` do
this job well; hanzen only aims to be the selective, in-buffer option.

## Non-goals

Staying small is the point. hanzen will **not**:

- touch anything outside the halfwidth-katakana, fullwidth-ASCII, and
  U+3000 blocks — no `①`→`1`, `㍻`→`平成`, `（）`→`()`, no ligatures;
- infer context by default: it converts the lines it is given, so scope
  it with a range or a visual selection. Opt into `protect = "treesitter"`
  to skip Markdown code blocks and inline code spans — and if no parser is
  available it degrades to no protection rather than guessing;
- convert the lossy, rarely-wanted direction (fullwidth katakana →
  halfwidth, etc.).

## Install

### lazy.nvim

```lua
{
  "qq3g7bad/hanzen.nvim",
  cmd = "Hanzen",
  opts = {},
}
```

### packer.nvim

```lua
use({ "qq3g7bad/hanzen.nvim", config = function() require("hanzen").setup() end })
```

`setup()` is optional; the `:Hanzen` command works without it.

## Usage

```vim
:Hanzen katakana        " convert halfwidth katakana, whole buffer
:Hanzen alphanum        " convert fullwidth ASCII, whole buffer
:Hanzen space           " convert fullwidth space U+3000 (config: space_*)
:Hanzen all             " run katakana + alphanum + space
:Hanzen                 " default subcommand (see config: 'default')
:'<,'>Hanzen alphanum   " only the visual selection
:10,20Hanzen katakana   " only lines 10–20
:Hanzen! alphanum       " dry-run: report which lines WOULD change, no edits
:Hanzen <Tab>           " complete subcommands
```

### Lua API

```lua
local hanzen = require("hanzen")

hanzen.convert("katakana")                       -- whole buffer
hanzen.convert("alphanum", { line1 = 1, line2 = 40 })
local r = hanzen.convert("all", { dry_run = true })
-- r = { changed = <n>, lnums = { ... }, dry_run = true, blocked = false }
```

### Example keymaps

```lua
vim.keymap.set("n", "<leader>jk", function()
  require("hanzen").convert("katakana") -- no range -> whole buffer
end, { desc = "hanzen: halfwidth → fullwidth katakana" })

vim.keymap.set("x", "<leader>ja", function()
  require("hanzen").convert("alphanum", {
    line1 = vim.fn.line("v"), -- selection anchor; order vs. line2 doesn't matter
    line2 = vim.fn.line("."), -- cursor line (convert() normalizes a reversed range)
  })
end, { desc = "hanzen: fullwidth → halfwidth alphanumerics (selection)" })
```

## Configuration

```lua
require("hanzen").setup({
  default = "katakana",              -- subcommand used by a bare :Hanzen
  notify = true,                     -- vim.notify summary after running
  space_repeat = 1,                  -- U+3000 -> this many ASCII spaces
  space_keep_leading_indent = true,  -- false: also convert a leading U+3000 run
  protect = "none",                  -- "treesitter": skip Markdown code regions
})
```

`protect = "treesitter"` leaves fenced/indented code blocks and inline
code spans untouched, using the `markdown` / `markdown_inline` grammars
(bundled with Neovim ≥ 0.10). If they are unavailable it converts with no
protection and says so — it never guesses where code is. It can also be
set per call: `require("hanzen").convert("alphanum", { protect = "treesitter" })`.

## Development

```sh
make test   # plenary headless specs (auto-fetches plenary.nvim)
make lint   # stylua --check
make fmt    # stylua
```

## License

[MIT](./LICENSE)

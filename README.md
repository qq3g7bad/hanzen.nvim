# hanzen.nvim

Selective, dependency-free Japanese character-width **conversion** for
Neovim — one direction at a time, on demand.

> Unicode **NFKC** folds every difference (width, kana composition,
> compatibility ligatures, ...) at once, and is the right tool when
> *that* is what you want. hanzen exposes the same folds as separate,
> directional verbs — so you can apply only the ones you want, only
> where you want them. A scalpel for cases NFKC's hammer would over-touch.

Each subcommand is one directional verb:

| Subcommand  | Direction             | What it touches                                                                        |
| ----------- | --------------------- | -------------------------------------------------------------------------------------- |
| `katakana`  | hankaku → zenkaku     | `ｱｲｳ ｶﾞ ﾊﾟ` → `アイウ ガ パ` (halfwidth katakana, with dakuten/handakuten composition) |
| `alphanum`  | zenkaku → hankaku     | `ＡＢＣ １２３ ！＠＃` → `ABC 123 !@#` (fullwidth ASCII letters, digits, symbols)      |
| `space`     | zenkaku → hankaku     | `A　B` → `A B` (fullwidth space U+3000 → ASCII space; width & leading-indent configurable) |
| `compat`    | ligature → decomposed | `㍻` → `平成`, `㎏` → `kg`, `㍿` → `株式会社`, … (CJK Compatibility block U+3300..U+33FF) |
| `enclosed`  | enclosed → bare       | `㈱` → `(株)`, `㊙` → `秘`, `㉑` → `21`, `㋿` → `令和`, … (Enclosed CJK Letters & Months U+3200..U+32FF — the common "機種依存文字") |
| `all`       | every verb            | runs every verb above, in registration order — this is the **complete** set |
| `flush-all` | every verb            | like `all`, but also converts a leading-indent U+3000 run (ignores `space_keep_leading_indent`) |

The fullwidth space `　` (U+3000) is touched **only** by `space` (and therefore
by `all`); `katakana`/`alphanum` never touch it. Each converted U+3000 becomes
**one** ASCII space (`space_repeat` changes the count). A run of U+3000 at the
**start of a line** — Japanese paragraph indentation — is **preserved by
default**; set `space_keep_leading_indent = false` to convert those too.

## Why not just NFKC?

Unicode **NFKC** folds every transformation it knows in a single pass: width
changes, halfwidth-kana composition, CJK Compatibility decomposition
(`㍻` → `平成`, `㎏` → `kg`), circled-numeral flattening, ligature
decomposition, ... It is the right tool when *all of those at once* is what
you want.

hanzen exposes the same folds, but **one verb at a time**:

- **Independent, directional verbs.** `:Hanzen katakana` only composes
  halfwidth katakana. `:Hanzen alphanum` only flattens fullwidth ASCII.
  `:Hanzen compat` only decomposes the CJK Compatibility block.
  `:Hanzen enclosed` only decomposes parenthesized / circled CJK
  (the "機種依存文字" that show up in old business documents). You
  can fix stray halfwidth katakana without touching your fullwidth
  brackets, or expand `㈱` ligatures without rewriting your spaces.
- **`all` is the complete verb set, applied in one pass.** When a verb
  is added to hanzen, `all` (and `flush-all`) grow with it — the table
  above is the source of truth; behavior changes between releases are
  called out in CHANGELOG.
- **Zero runtime dependencies.** Pure Lua — nothing to install, nothing
  to shell out to.
- **In-editor and range-aware.** `:Hanzen <Tab>` completion, dry-run
  preview (`:Hanzen!`), visual/range scoping, and a small Lua API for
  your own keymaps.

Outside the editor, batch tools like `nkf`, `jaconv`, and `mojimoji` do
this job well; hanzen aims to be the selective, in-buffer option.

## Non-goals

Some things are deliberately out of scope:

- **No context inference by default.** hanzen converts the lines it is
  given. Scope it with a range, a visual selection, or `protect =
  "treesitter"` (which skips Markdown code blocks and inline code spans,
  and falls back to no protection if no parser is available — it never
  *guesses* where code is).
- **No lossy reverse direction.** Fullwidth katakana → halfwidth,
  ASCII → fullwidth ASCII, etc. are not provided. `mojimoji` and
  similar dedicated tools cover that direction.
- **No other whitespace.** ASCII spaces, tabs, trailing whitespace, line
  endings are not normalized. The `space` verb is U+3000-only.
- **Per-verb scope is the Unicode block.** Each verb operates inside its
  named block (e.g. `katakana` = U+FF61..U+FF9F, `compat` = U+3300..
  U+33FF, `enclosed` = U+3200..U+32FF). Cross-block conveniences belong
  in new verbs, not in existing ones — and new verbs become part of `all`.

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
:Hanzen compat          " decompose CJK Compatibility (㍻ → 平成, ㎏ → kg, …)
:Hanzen enclosed        " decompose enclosed CJK (㈱ → (株), ㊙ → 秘, ㋿ → 令和, …)
:Hanzen all             " run every verb above
:Hanzen flush-all       " like all, but flush a leading U+3000 run too
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
scripts/test.sh                        # plenary headless specs (auto-fetches plenary.nvim)
scripts/test.sh tests/space_spec.lua   # one spec file
scripts/lint.sh                        # stylua --check
scripts/fmt.sh                         # stylua
```

## License

[MIT](./LICENSE)

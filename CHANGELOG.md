# Changelog

All notable changes to hanzen.nvim are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Converting no longer deletes marks or moves extmarks (diagnostics,
  signs) on unchanged lines; only the changed characters are rewritten,
  and one `undo` still reverts the whole command.
- The cursor stays on the same character after a conversion changes the
  byte length of its line.
- `protect = "treesitter"` parses only buffers whose filetype maps to the
  markdown parser. In other buffers (Python, Lua, …) nothing is protected;
  before, an indented line after a blank line was taken for a Markdown
  code block and skipped.
- `space` with `protect = "treesitter"`: a U+3000 right after inline code
  is converted instead of being kept as leading indent.
- `all` / `flush-all` report each changed line once (`lnums` has no
  duplicates) and parse and write the buffer once instead of once per
  verb.
- `katakana` composes `ﾜﾞ` → `ヷ` and `ｦﾞ` → `ヺ`.

### Changed

- Converters receive a second argument, `ctx = { at_line_start = bool }`.
  Converters with one parameter keep working.
- Development: the Makefile is replaced by `scripts/test.sh`,
  `scripts/lint.sh` and `scripts/fmt.sh`.

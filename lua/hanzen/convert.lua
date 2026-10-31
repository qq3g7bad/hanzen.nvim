--
-- @file lua/hanzen/convert.lua
-- @brief Range/buffer engine shared by every converter.
--
-- Each converter is a pure `function(text, ctx) -> text`. This module applies
-- one over a line range (or the whole buffer), preserves the cursor/view,
-- and supports a non-mutating dry-run. Only the bytes that actually change
-- are written back, so marks, extmarks (diagnostics, signs) and LSP
-- change events outside them are left alone.
--
-- A `protect` provider (see protect.lua) may mark character spans the
-- converter must skip. The engine slices each line into protected /
-- unprotected segments and only feeds the unprotected ones to `text_fn`.
-- `ctx.at_line_start` tells the converter whether its segment begins the
-- line (only `space` cares, for the leading-indent rule).
-- When nothing is protected (the default), each line takes the original
-- one-call fast path, so behavior and performance are unchanged.
--

local protect = require("hanzen.protect")

local M = {}

local function result(changed, lnums, opts, blocked, mode, degraded)
  return {
    changed = changed,
    lnums = lnums,
    dry_run = opts.dry_run or false,
    blocked = blocked,
    protect = mode,
    degraded = degraded,
  }
end

-- Merge a row's raw {a, b} byte intervals: clamp to the line, drop empties,
-- sort by start, coalesce overlaps/adjacency. `b` may be math.huge for a
-- fully-covered middle line; it is clamped to the line length here.
local function normalize(intervals, line_len)
  local cleaned = {}
  for _, iv in ipairs(intervals) do
    local a = math.max(0, math.min(iv[1], line_len))
    local b = math.max(a, math.min(iv[2], line_len))
    if b > a then
      cleaned[#cleaned + 1] = { a, b }
    end
  end
  table.sort(cleaned, function(x, y)
    return x[1] < y[1]
  end)
  local merged = {}
  for _, iv in ipairs(cleaned) do
    local top = merged[#merged]
    if top and iv[1] <= top[2] then
      top[2] = math.max(top[2], iv[2])
    else
      merged[#merged + 1] = { iv[1], iv[2] }
    end
  end
  return merged
end

---Convert `line`, applying `text_fn` only outside the protected `intervals`
---(sorted, merged, clamped; 0-indexed byte offsets, end-exclusive). Pure --
---no buffer or treesitter access -- so it is unit-testable on its own.
---@param line string
---@param intervals integer[][]
---@param text_fn fun(text: string, ctx: { at_line_start: boolean }): string
---@return string
function M._convert_line(line, intervals, text_fn)
  if not intervals or #intervals == 0 then
    return text_fn(line, { at_line_start = true })
  end
  local parts = {}
  local pos = 0
  for _, iv in ipairs(intervals) do
    local a, b = iv[1], iv[2]
    if a > pos then
      parts[#parts + 1] =
        text_fn(line:sub(pos + 1, a), { at_line_start = pos == 0 })
    end
    parts[#parts + 1] = line:sub(a + 1, b) -- protected, verbatim
    pos = b
  end
  if pos < #line then
    parts[#parts + 1] = text_fn(line:sub(pos + 1), { at_line_start = false })
  end
  return table.concat(parts)
end

-- Bucket buffer-wide spans into per-line-number raw interval lists, limited
-- to the [l1, l2] range actually being processed.
local function bucket(spans, l1, l2)
  local by_lnum = {}
  for _, sp in ipairs(spans) do
    local sr, sc, er, ec = sp[1], sp[2], sp[3], sp[4]
    for row = sr, er do
      local lnum = row + 1
      if lnum >= l1 and lnum <= l2 then
        local a = (row == sr) and sc or 0
        local b = (row == er) and ec or math.huge
        by_lnum[lnum] = by_lnum[lnum] or {}
        local list = by_lnum[lnum]
        list[#list + 1] = { a, b }
      end
    end
  end
  return by_lnum
end

-- UTF-8 continuation byte (10xxxxxx) at 1-indexed `i`; false past the end.
local function is_cont(str, i)
  local b = str:byte(i)
  return b ~= nil and b >= 0x80 and b < 0xC0
end

-- The part of `old` that differs from `new`: returns the 0-indexed byte
-- range [s, e) in `old` and its replacement. The range is widened to
-- whole characters, so a mark or extmark never ends up mid-character.
local function diff_span(old, new)
  local n = math.min(#old, #new)
  local s = 0
  while s < n and old:byte(s + 1) == new:byte(s + 1) do
    s = s + 1
  end
  while s > 0 and (is_cont(old, s + 1) or is_cont(new, s + 1)) do
    s = s - 1
  end
  local q = 0 -- common suffix length
  while q < n - s and old:byte(#old - q) == new:byte(#new - q) do
    q = q + 1
  end
  while q > 0 and (is_cont(old, #old - q + 1) or is_cont(new, #new - q + 1)) do
    q = q - 1
  end
  return s, #old - q, new:sub(s + 1, #new - q)
end

-- Convert one line, honoring its raw protected intervals (if any).
local function convert_line(line, raw, text_fn)
  if raw then
    return M._convert_line(line, normalize(raw, #line), text_fn)
  end
  return text_fn(line, { at_line_start = true }) -- fast path
end

---Apply a pure text function over a buffer range.
---`line1`/`line2` are order-independent: a reversed range (e.g. from a
---bottom-to-top Visual selection) is normalized here, so callers never
---need to sort the bounds themselves.
---@param text_fn fun(text: string, ctx: { at_line_start: boolean }): string
---@param opts? { line1?: integer, line2?: integer, dry_run?: boolean, protect?: string }
---@return { changed: integer, lnums: integer[], dry_run: boolean, blocked: boolean, protect: string, degraded: boolean }
function M.apply(text_fn, opts)
  opts = opts or {}
  local mode = opts.protect or "none"
  local buf = vim.api.nvim_get_current_buf()
  local last = vim.api.nvim_buf_line_count(buf)

  local r1, r2 = opts.line1, opts.line2
  if r1 and r2 and r1 > r2 then
    r1, r2 = r2, r1
  end
  local l1 = r1 and math.max(r1, 1) or 1
  local l2 = r2 and math.min(r2, last) or last
  -- Still empty here only if the range lies entirely outside the buffer.
  if l1 > l2 then
    return result(0, {}, opts, false, mode, false)
  end

  local spans, degraded = protect.spans(buf, mode)
  local by_lnum = bucket(spans, l1, l2)

  local lines = vim.api.nvim_buf_get_lines(buf, l1 - 1, l2, false)
  local out = {}
  local lnums = {}
  for i, line in ipairs(lines) do
    local lnum = l1 + i - 1
    local converted = convert_line(line, by_lnum[lnum], text_fn)
    if converted ~= line then
      lnums[#lnums + 1] = lnum
      out[lnum] = { line, converted }
    end
  end

  if #lnums == 0 then
    return result(0, {}, opts, false, mode, degraded)
  end
  if opts.dry_run then
    return result(#lnums, lnums, opts, false, mode, degraded)
  end
  if not vim.bo[buf].modifiable then
    return result(#lnums, lnums, opts, true, mode, degraded)
  end

  -- Line count is preserved 1:1, so each line is patched in place. The
  -- set_text calls of one command form a single undo step.
  local view = vim.fn.winsaveview()
  for _, lnum in ipairs(lnums) do
    local s, e, mid = diff_span(out[lnum][1], out[lnum][2])
    vim.api.nvim_buf_set_text(buf, lnum - 1, s, lnum - 1, e, { mid })
  end
  vim.fn.winrestview(view)

  -- winrestview put the cursor back at its old byte column; on a changed
  -- line that is a different character. Its new column is the length of
  -- the converted text before it, snapped to a character start.
  local cur = out[view.lnum]
  if cur then
    local old, new = cur[1], cur[2]
    local prefix = old:sub(1, view.col)
    local raw = by_lnum[view.lnum]
    local col = #convert_line(prefix, raw, text_fn)
    if col < #new then
      col = col + vim.str_utf_start(new, col + 1)
    end
    vim.api.nvim_win_set_cursor(0, { view.lnum, col })
  end

  return result(#lnums, lnums, opts, false, mode, degraded)
end

return M

-- vim: set sw=2 ts=2 sts=2 et tw=80 ft=lua:

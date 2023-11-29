local Util = require "SingleComment.util"

local MiniComment = {}
local H = {}

MiniComment.setup = function()
  _G.MiniComment = MiniComment

  vim.keymap.set("n", "gc", function() return MiniComment.operator() end, { expr = true })
  -- Using `:<c-u>` instead of `<cmd>` as latter results into executing before
  -- proper update of `'<` and `'>` marks which is needed to work correctly.
  vim.keymap.set("x", "gc", [[:<c-u>lua MiniComment.operator('visual')<cr>]], {})
end

MiniComment.config = {
  options = {
    custom_commentstring = function()
      return require('ts_context_commentstring').calculate_commentstring() or vim.bo.commentstring
    end,
    -- Whether to ignore blank lines
    ignore_blank_line = false,
    -- Whether to recognize as comment only lines without indent
    start_of_line = false,
    -- Whether to ensure single space pad for comment parts
    pad_comment_parts = true,
  },
}

-- Module functionality =======================================================
--- Main function to be mapped
---
--- It is meant to be used in expression mappings (see |map-<expr>|) to enable
--- dot-repeatability and commenting on range. There is no need to do this
--- manually, everything is done inside |MiniComment.setup()|.
---
--- It has a somewhat unintuitive logic (because of how expression mapping with
--- dot-repeatability works): it should be called without arguments inside
--- expression mapping and with argument when action should be performed.
---
---@param mode string|nil Optional string with 'operatorfunc' mode (see |g@|).
---
---@return string|nil 'g@' if called without argument, '' otherwise (but after
---   performing action).
MiniComment.operator = function(mode)
  if H.is_disabled() then return '' end

  -- If used without arguments inside expression mapping:
  -- - Set itself as `operatorfunc` to be called later to perform action.
  -- - Return 'g@' which will then be executed resulting into waiting for a
  --   motion or text object. This textobject will then be recorded using `'[`
  --   and `']` marks. After that, `operatorfunc` is called with `mode` equal
  --   to one of "line", "char", or "block".
  -- NOTE: setting `operatorfunc` inside this function enables usage of 'count'
  -- like `10gc_` toggles comments of 10 lines below (starting with current).
  if mode == nil then
    vim.o.operatorfunc = 'v:lua.MiniComment.operator'
    return 'g@'
  end

  -- If called with non-nil `mode`, get target region and perform comment
  -- toggling over it.
  local mark_left, mark_right = '[', ']'
  if mode == 'visual' then
    mark_left, mark_right = '<', '>'
  end

  local line_left, col_left = unpack(vim.api.nvim_buf_get_mark(0, mark_left))
  local line_right, col_right = unpack(vim.api.nvim_buf_get_mark(0, mark_right))

  -- Do nothing if "left" mark is not on the left (earlier in text) of "right"
  -- mark (indicating that there is nothing to do, like in comment textobject).
  if (line_left > line_right) or (line_left == line_right and col_left > col_right) then return end

  -- Use `vim.cmd()` wrapper to allow usage of `lockmarks` command, because raw
  -- execution deletes marks in region (due to `vim.api.nvim_buf_set_lines()`).
  vim.cmd(string.format(
  -- NOTE: use cursor position as reference for possibly computing local
  -- tree-sitter-based 'commentstring'. Compute them inside command for
  -- a proper dot-repeat. For Visual mode and sometimes Normal mode it uses
  -- left position.
    [[lockmarks lua MiniComment.toggle_lines(%d, %d, { ref_position = { vim.fn.line('.'), vim.fn.col('.') } })]],
    line_left,
    line_right
  ))
  return ''
end

--- Toggle comments between two line numbers
---
--- It uncomments if lines are comment (every line is a comment) and comments
--- otherwise. It respects indentation and doesn't insert trailing
--- whitespace. Toggle commenting not in visual mode is also dot-repeatable
--- and respects |count|.
---
--- # Notes ~
---
--- - Comment structure is inferred from buffer's 'commentstring' option or
---   local language of tree-sitter parser (if active; only on Neovim>=0.9).
---
--- - Currently call to this function will remove marks inside written range.
---   Use |lockmarks| to preserve marks.
---
---@param line_start number Start line number (inclusive from 1 to number of lines).
---@param line_end number End line number (inclusive from 1 to number of lines).
---@param opts table|nil Options. Possible fields:
---   - <ref_position> `(table)` - A two-value array with `{ row, col }` (both
---     starting at 1) of reference position at which 'commentstring' value
---     will be computed. Default: `{ line_start, 1 }`.
MiniComment.toggle_lines = function(line_start, line_end, opts)
  if H.is_disabled() then return end

  opts = opts or {}
  local ref_position = opts.ref_position or { line_start, 1 }

  local n_lines = vim.api.nvim_buf_line_count(0)
  if not (1 <= line_start and line_start <= n_lines and 1 <= line_end and line_end <= n_lines) then
    error(('(mini.comment) `line_start` and `line_end` should be within range [1; %s].'):format(n_lines))
  end
  if not (line_start <= line_end) then
    error('(mini.comment) `line_start` should be less than or equal to `line_end`.')
  end

  local config = H.get_config()

  local comment_parts = H.make_comment_parts(ref_position)
  local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)

  vim.g.l = { lines, line_start, line_end, comment_parts }

  -- core
  Util.toggle_comment(lines, 1, #lines, { comment_parts.left, comment_parts.right })

  -- NOTE: This function call removes marks inside written range. To write
  -- lines in a way that saves marks, use one of:
  -- - `lockmarks` command when doing mapping (current approach).
  -- - `vim.fn.setline(line_start, lines)`, but this is **considerably**
  --   slower: on 10000 lines 280ms compared to 40ms currently.
  vim.api.nvim_buf_set_lines(0, line_start - 1, line_end, false, lines)
end

--- Get 'commentstring'
---
--- This function represents default approach of computing relevant
--- 'commentstring' option in current buffer. Used to infer comment structure.
---
--- It has the following logic:
--- - (Only on Neovim>=0.9) If there is an active tree-sitter parser, try to get
---   'commentstring' from the local language at `ref_position`.
---
--- - If first step is not successful, use buffer's 'commentstring' directly.
---
---@param ref_position table Reference position inside current buffer at which
---   to compute 'commentstring'. Same structure as `opts.ref_position`
---   in |MiniComment.toggle_lines()|.
---
---@return string Relevant value of 'commentstring'.
MiniComment.get_commentstring = function(ref_position)
  local buf_cs = vim.bo.commentstring

  -- Neovim<0.9 can only have buffer 'commentstring'
  if vim.fn.has('nvim-0.9') == 0 then return buf_cs end

  local has_ts_parser, ts_parser = pcall(vim.treesitter.get_parser)
  if not has_ts_parser then return buf_cs end

  -- Try to get 'commentstring' associated with local tree-sitter language.
  -- This is useful for injected languages (like markdown with code blocks).
  -- Sources:
  -- - https://github.com/neovim/neovim/pull/22634#issue-1620078948
  -- - https://github.com/neovim/neovim/pull/22643
  local row, col = ref_position[1] - 1, ref_position[2] - 1
  local ref_range = { row, col, row, col + 1 }

  -- - Get 'commentstring' from the deepest LanguageTree which both contains
  --   reference range and has valid 'commentstring' (meaning it has at least
  --   one associated 'filetype' with valid 'commentstring').
  --   In simple cases using `parser:language_for_range()` would be enough, but
  --   it fails for languages without valid 'commentstring' (like 'comment').
  local ts_cs, res_level = nil, 0
  local traverse

  traverse = function(lang_tree, level)
    if not lang_tree:contains(ref_range) then return end

    local lang = lang_tree:lang()
    local filetypes = vim.treesitter.language.get_filetypes(lang)
    for _, ft in ipairs(filetypes) do
      -- Using `vim.filetype.get_option()` for performance as it has caching
      local cur_cs = vim.filetype.get_option(ft, 'commentstring')
      if type(cur_cs) == 'string' and cur_cs ~= '' and level > res_level then ts_cs = cur_cs end
    end

    for _, child_lang_tree in pairs(lang_tree:children()) do
      traverse(child_lang_tree, level + 1)
    end
  end
  traverse(ts_parser, 1)

  return ts_cs or buf_cs
end

-- Helper data ================================================================
-- Module default config

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------

H.is_disabled = function() return vim.g.minicomment_disable == true or vim.b.minicomment_disable == true end

H.get_config = function(config)
  return vim.tbl_deep_extend('force', MiniComment.config, vim.b.minicomment_config or {}, config or {})
end

-- Core implementations --
H.make_comment_parts = function(ref_position)
  local options = H.get_config().options

  local cs = H.call_safely(options.custom_commentstring, ref_position) or MiniComment.get_commentstring(ref_position)

  -- Assumed structure of 'commentstring':
  -- <space> <left> <'%s'> <right> <space>
  -- So this extracts parts without surrounding whitespace
  local left, right = cs:match('^%s*(.*)%%s(.-)%s*$')
  -- Trim comment parts from inner whitespace to ensure single space pad
  if options.pad_comment_parts then
    left, right = vim.trim(left), vim.trim(right)
  end
  return { left = left, right = right }
end

-- Utilities --
H.error = function(msg) error(string.format('(mini.comment) %s', msg), 0) end

H.map = function(mode, lhs, rhs, opts)
  if lhs == '' then return end
  opts = vim.tbl_deep_extend('force', { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

H.call_safely = function(f, ...)
  if not vim.is_callable(f) then return nil end
  return f(...)
end

return MiniComment

local Util = require "SingleComment.util"

local M = {}
local H = {}

M.setup = function()
  _G.MiniComment = M

  vim.keymap.set("n", "gc", function() return M.operator() end, { expr = true })
  -- Using `:<c-u>` instead of `<cmd>` as latter results into executing before
  -- proper update of `'<` and `'>` marks which is needed to work correctly.
  vim.keymap.set("x", "gc", [[:<c-u>lua MiniComment.operator('visual')<cr>]], {})
end

M.config = {
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

M.operator = function(mode)
  local mark_left, mark_right = '[', ']'
  if mode == 'visual' then
    mark_left, mark_right = '<', '>'
  end

  local line_left, col_left = unpack(vim.api.nvim_buf_get_mark(0, mark_left))
  local line_right, col_right = unpack(vim.api.nvim_buf_get_mark(0, mark_right))

  -- Use `vim.cmd()` wrapper to allow usage of `lockmarks` command, because raw
  -- execution deletes marks in region (due to `vim.api.nvim_buf_set_lines()`).
  -- TODO: remove this part, just add ts_context_commentstring plugin as deps only
  vim.cmd(string.format(
  -- NOTE: use cursor position as reference for possibly computing local
  -- tree-sitter-based 'commentstring'. Compute them inside command for
  -- a proper dot-repeat. For Visual mode and sometimes Normal mode it uses
  -- left position.
    [[lockmarks lua MiniComment.toggle_lines(%d, %d)]],
    line_left,
    line_right
  ))
  return ''
end

M.toggle_lines = function(line_start, line_end)
  local comment_parts = M.make_comment_parts()
  -- format only on selected lines
  local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
  -- core
  Util.toggle_comment(lines, 1, #lines, { comment_parts.left, comment_parts.right })
  vim.api.nvim_buf_set_lines(0, line_start - 1, line_end, false, lines)
end

H.get_config = function(config)
  return vim.tbl_deep_extend('force', M.config, vim.b.minicomment_config or {}, config or {})
end

M.make_comment_parts = function()
  local options = H.get_config().options

  local cs = options.custom_commentstring()

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

return M

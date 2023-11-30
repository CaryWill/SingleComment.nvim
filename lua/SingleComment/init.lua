local Util = require "SingleComment.util"
local M = {}

M.setup = function()
  _G.__MiniComment = M

  vim.keymap.set("n", "gcc", function() return M.operator() .. '_' end, { expr = true })
  -- Using `:<c-u>` instead of `<cmd>` as latter results into executing before
  -- proper update of `'<` and `'>` marks which is needed to work correctly.
  vim.keymap.set("x", "gc", [[:<c-u>lua __MiniComment.operator('visual')<cr>]], {})
end

M.operator = function(mode)
  -- single line comment
  if mode == nil then
    vim.o.operatorfunc = 'v:lua.__MiniComment.operator'
    return 'g@'
  end

  local mark_left, mark_right = '[', ']'
  if mode == 'visual' then
    mark_left, mark_right = '<', '>'
  end

  local line_left, col_left = unpack(vim.api.nvim_buf_get_mark(0, mark_left))
  local line_right, col_right = unpack(vim.api.nvim_buf_get_mark(0, mark_right))

  if (line_left > line_right) or (line_left == line_right and col_left > col_right) then return end
  -- Use `vim.cmd()` wrapper to allow usage of `lockmarks` command, because raw
  -- execution deletes marks in region (due to `vim.api.nvim_buf_set_lines()`).
  vim.cmd(string.format(
    [[lockmarks lua __MiniComment.toggle_lines(%d, %d)]],
    line_left,
    line_right
  ))
  return ''
end

M.toggle_lines = function(line_start, line_end)
  local bufnr = vim.api.nvim_get_current_buf()
  local comment_parts = M.make_comment_parts()
  local lines = vim.api.nvim_buf_get_lines(bufnr, line_start - 1, line_end, false)
  Util.toggle_comment(lines, 1, #lines, { comment_parts.left, comment_parts.right })
  vim.api.nvim_buf_set_lines(bufnr, line_start - 1, line_end, false, lines)
end

M.make_comment_parts = function()
  local cs = require('ts_context_commentstring').calculate_commentstring() or vim.bo.commentstring

  -- Assumed structure of 'commentstring':
  -- <space> <left> <'%s'> <right> <space>
  -- So this extracts parts without surrounding whitespace
  local left, right = cs:match('^%s*(.*)%%s(.-)%s*$')
  return { left = left, right = right }
end

return M

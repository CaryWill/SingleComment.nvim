function CommentNonPairs(lines, sr, er, comment)
  -- comment each line of the block
  if (lines[sr]:find(commentstr[1])) then
    -- uncomment it
    for i = sr, er do
      lines[i] = lines[i]:gsub(comment[1], "")
    end
  else
    -- comment it
    -- keep indent
    for i = sr, er do
      local indent = lines[i]:match("^%s*")
      local trimmed = lines[i]:gsub(indent, "")

      lines[i] =
          indent
          .. comment[1]
          .. trimmed
    end
  end
end

function SingleLine(lines, sr, er, comment)
  local indent = lines[sr]:match("^%s*")
  local trimmed = lines[sr]:gsub(indent, "")

  local matchStart = trimmed:find("^" .. comment[1])
  local matchEnd = lines[sr]:find(comment[2] .. "$")

  -- commented
  if matchStart and matchEnd then
    lines[sr] = lines[sr]:gsub(comment[1], ""):gsub(comment[2], "")
  else
    lines[sr] =
        indent
        .. comment[1]
        .. trimmed
        .. comment[2]
  end
  -- cursor in the same line
  --[[ lines[sr] = lines[sr]:sub(1, sc - 1)
        .. " "
        .. comment[1]
        .. lines[sr]:sub(sc, ec):gsub("^%s+", "")
        .. comment[2]
        .. (#lines[sr]:sub(ec + 1) > 0 and " " .. lines[er]:sub(ec + 1) or "") ]]
end

function reverseString(str)
  local reversed = ""
  for i = #str, 1, -1 do
    reversed = reversed .. string.sub(str, i, i)
  end
  return reversed
end

function Comment()
  local comment = {}
  local ok, tsc = pcall(require, "ts_context_commentstring")
  tsc.calculate_commentstring()
  local bufnr = vim.api.nvim_get_current_buf()
  local cs = vim.api.nvim_buf_get_option(bufnr, "commentstring")

  local left = cs:match("^(.-)%s")
  local right = reverseString(reverseString(cs):match("^(.-)%s"))
  comment[1] = left
  comment[2] = right

  local _, sr, sc, _ = unpack(vim.fn.getpos("."))
  local _, er, ec, _ = unpack(vim.fn.getpos("v"))
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- TODO: some place using below line will not work line lua
  -- muti-line comment
  -- toggle the selected lines to make it simple
  if sr > er then
    sr, er = er, sr
    sc, ec = ec, sc
  end

  if sr == er then
    M.SingleLine(lines, sr, er, comment)
  else
    if (comment[2] == "") then
      M.CommentNonPairs(lines, sr, er, comment)
    else
      M.CommentPairs(lines, sr, er, comment)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_feedkeys("=", "n", false)
end

local M = {}

-- default keep indent
function M.insert_at_start(str, unescaped_chars, _indent)
  vim.g.chars = unescaped_chars
  local indent = _indent or str:match("^%s*")
  local unindented = str:sub(#indent + 1, #str)
  local result = indent .. unescaped_chars .. unindented
  return result
end

-- default not keep indent
function M.insert_at_end(str, unescaped_chars, keep_indent, left_padding)
  if keep_indent then
    return left_padding .. str .. unescaped_chars
  else
    return str .. unescaped_chars
  end
end

function M.remove_from_start(str, unescaped_chars)
  local indent = str:match("^%s*")
  local escaped_chars = vim.pesc(unescaped_chars)
  return str:gsub(indent .. escaped_chars, indent)
end

function M.remove_from_end(str, unescaped_chars)
  local escaped_chars = vim.pesc(unescaped_chars)
  if not str:find(escaped_chars .. "$") then
    return str
  end
  return str:sub(1, #str - #unescaped_chars)
end

-- syntax sugar 🍬
-- 1. if both left_chars & right_chars exists then only comment on first and last line
-- 2. if right_chars are missing then comment on each line
-- 3. keep indent
function M.insert_comment_multiline(lines, sr, er, unescaped_left_chars, unescaped_right_chars)
  if sr == nil then sr = 1 end
  if er == nil then er = #lines end

  if unescaped_left_chars and unescaped_right_chars ~= "" then
    for i = sr, er do
      if i == sr then
        -- comment only on first line
        if sr == er then
          lines[i] = M.insert_at_end(lines[i], unescaped_right_chars)
        end
        lines[i] = M.insert_at_start(lines[i], unescaped_left_chars)
      elseif i == er then
        lines[i] = M.insert_at_end(lines[i], unescaped_right_chars)
      else
        lines[i] = lines[i]
      end
    end
  else
    -- comment on each line when right_chars are missing
    for i = sr, er do
      if sr == er then
        lines[i] = M.insert_at_end(lines[i], unescaped_right_chars)
      end
      if #lines[i] > 0 then
        lines[i] = M.insert_at_start(lines[i], unescaped_left_chars, lines[sr]:match("^%s*"))
      end
    end
  end

  return lines
end

function M.remove_comment_multiline(lines, sr, er, unescaped_left_chars, unescaped_right_chars)
  if sr == nil then sr = 1 end
  if er == nil then er = #lines end

  if unescaped_left_chars and unescaped_right_chars ~= "" then
    for i = sr, er do
      if i == sr then
        if sr == er then
          lines[i] = M.remove_from_end(lines[i], unescaped_right_chars)
        end
        lines[i] = M.remove_from_start(lines[i], unescaped_left_chars)
      elseif i == er then
        lines[i] = M.remove_from_end(lines[i], unescaped_right_chars)
      end
    end
  else
    -- uncomment on each line when right_chars are missing
    for i = sr, er do
      if sr == er then
        lines[i] = M.remove_from_start(lines[i], unescaped_right_chars)
      end
      lines[i] = M.remove_from_start(lines[i], unescaped_left_chars)
    end
  end

  return lines
end

function M.tableSubsetByRange(originalTable, a, b)
  local subset = {}
  for i = a, b do
    subset[i - a + 1] = originalTable[i]
  end
  return subset
end

function M.toggle_comment(lines, sr, er, comment)
  if (lines[sr]:find(vim.pesc(comment[1]))) then
    -- uncomment it
    M.remove_comment_multiline(lines, sr, er, comment[1], comment[2])
  else
    -- comment it
    M.insert_comment_multiline(lines, sr, er, comment[1], comment[2])
  end
  return lines
end

return M

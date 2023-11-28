local M = {}

-- default keep indent
function M.insert_at_start(str, chars)
  local indent = str:match("^%s*")
  local unindented = str:sub(#indent + 1, #str)
  local result = indent .. chars .. unindented
  return result
end

-- default not keep indent
function M.insert_at_end(str, chars, keep_indent, left_padding)
  if keep_indent then
    return left_padding .. str .. chars
  else
    return str .. chars
  end
end

function M.remove_from_start(str, chars)
  local indent = str:match("^%s*")
  local escaped_chars = vim.pesc(chars)
  return str:gsub(indent .. escaped_chars, indent)
end

function M.remove_from_end(str, chars)
  local escaped_chars = vim.pesc(chars)
  if not str:find(escaped_chars .. "$") then
    return str
  end
  return str:sub(1, #str - #chars)
end

-- syntax sugar 🍬
-- left_chars & right_comment should be unescaped chars
-- TODO: add notes
-- TODO: right_comment
function M.insert_comment_multiline(lines, sr, er, left_chars, right_chars)
  if sr == nil then sr = 1 end
  if er == nil then er = #lines end

  local indent = string.rep(" ", #left_chars)
  for i = 1, #lines do
    if i < sr or i > er then
      -- do nothing
    elseif i == 1 then
      -- comment only on first line
      lines[i] = M.insert_at_start(lines[i], left_chars)
      -- keep indent
    elseif i == #lines then
      lines[i] = M.insert_at_end(lines[i], right_chars, true, indent)
    else
      lines[i] = indent .. lines[i]
    end
  end
  return lines
end

function M.remove_comment_multiline(lines, sr, er, left_chars, right_chars)
  if sr == nil then sr = 1 end
  if er == nil then er = #lines end

  for i = 1, #lines do
    if i < sr or i > er then
      -- do nothing
    elseif i == 1 then
      lines[i] = M.remove_from_start(lines[i], left_chars)
    elseif i == #lines then
      lines[i] = M.remove_from_end(lines[i], right_chars)
      -- restore indent
      lines[i] = lines[i]:sub(#left_chars + 1, #lines[i])
    else
      lines[i] = lines[i]:sub(#left_chars + 1, #lines[i])
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

return M

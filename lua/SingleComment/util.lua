local M = {}

-- all function will be indent aware
function M.insert_at_start(str, chars)
  local indent = str:match("^%s*")
  local unindented = str:sub(#indent + 1, #str)
  local result = indent .. chars .. unindented
  return result
end

function M.insert_at_end(str, chars)
  return str .. chars
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
function M.insert_comment_multiline(lines, left_chars, right_comment)
  local indent = string.rep(" ", #left_chars)
  for i = 1, #lines do
    if i == 1 then
      -- comment only on first line
      lines[i] = M.insert_at_start(lines[i], left_chars)
      -- keep indent
    else
      lines[i] = indent .. lines[i]
    end
  end
  return lines
end

function M.remove_comment_multiline(lines, left_chars, right_chars)
  for i = 1, #lines do
    if i == 1 then
      lines[i] = M.remove_from_start(lines[i], left_chars)
    elseif i == #lines then
      lines[i] = M.remove_from_end(lines[i], right_chars)
      -- restore indent
      lines[i] = lines[i].sub(#left_chars, #lines[i])
    else
      lines[i] = lines[i].sub(#left_chars, #lines[i])
    end
  end
  return lines
end

return M

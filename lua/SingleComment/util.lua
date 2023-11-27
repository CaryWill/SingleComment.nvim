local M = {}

-- all function will be indent aware
function M.insert_at_start(str, chars)
  local indent = str:match("^%s*")
  local unindented = str:sub(#indent + 1, #str)
  local result = indent .. chars .. unindented
  return result
end

function M.insert_at_end(str)
end

function M.remove_from_start(str, chars)
  local indent = str:match("^%s*")
  local escaped_chars = vim.pesc(chars)
  return str:gsub(indent .. escaped_chars, indent)
end

function M.remove_from_end(str, chars)
end

return M
-- TODO:
-- 多行的时候要注意，插了几个，就得在中间的行里面补上几个空格

local M = {}
local Util = require "SingleComment.util"

---@type table kinds of comments
-- stylua: ignore
local comments = {
  ---@type table lines and filetypes that can be changed to block comments
  -- some can't be changed ;-; but are here for format adjustments
  block = {
    ["<!--"]     = { "<!-- ", " -->" },
    ["--[["]     = { "--[[ ", " ]]" },
    ["-- "]      = { "--[[ ", " ]]" },
    ["--"]       = { "--[[ ", " ]]" },
    ["/*"]       = { "/* ", " */" },
    lisp         = { "#| ", " |#" },
    cmake        = { "#[[ ", " ]]" },
    haskell      = { "{- ", " -}" },
    elm          = { "{- ", " -}" },
    julia        = { "#= ", " =#" },
    luau         = { "--[[ ", " ]]" },
    nim          = { "#[ ", " ]#" },
    ocaml        = { "(* ", " *)" },
    fsharp       = { "(* ", " *)" },
    markdown     = { "<!-- ", " -->" },
    org          = { "# ", "" },
    neorg        = { "# ", "" },
    javascript   = { "/* ", " */" },
    editorconfig = { "# ", "" },
    fortran      = { "! ", "" },
    default      = { "/* ", " */" },
  },
  ---@type table blocks and filetypes that can be changed to line comments
  -- some can't be changed ;-; but are here for format adjustments
  line = {
    ["<!--"]     = { "<!-- ", " -->" },
    ["/*"]       = { "// ", "" },
    ["/* "]      = { "// ", "" },
    [";"]        = { "; ", "" },
    ["%"]        = { "% ", "" },
    ['#']        = { "# ", "" },
    nim          = { "# ", "" },
    json         = { "// ", "" },
    jsonc        = { "// ", "" },
    nelua        = { "-- ", "" },
    luau         = { "-- ", "" },
    ocaml        = { "(* ", " *)" },
    css          = { "/* ", " */" },
    markdown     = { "<!-- ", " -->" },
    org          = { "# ", "" },
    neorg        = { "# ", "" },
    editorconfig = { "# ", "" },
    fortran      = { "! ", "" },
    default      = { "// ", "" },
  },
}

---@param kind? string kind of returned comment, defaults to "line"
---@return table table with the comment beginning/end
function M.GetComment(kind)
  kind = kind or "line"
  local comment = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  local ok, tsc = pcall(require, "ts_context_commentstring.internal")

  if ok then
    tsc.update_commentstring({})
  end

  local cs = vim.api.nvim_buf_get_option(bufnr, "commentstring")

  if comments[kind][filetype] ~= nil then
    -- use [filetype] override
    comment = comments[kind][filetype]
  elseif cs == "" or cs == nil then
    -- use [default] comment for [kind]
    comment = comments[kind]["default"]
  else
    -- separating strings like `%%s` like tex comments
    -- does not work well in a for loop with gmatch
    comment[1] = cs:match("(.*)%%s")
    comment[2] = cs:match("%%s(.*)")

    -- use a better [kind] of comment, or adjust its format
    if comments[kind][comment[1]] then
      comment = comments[kind][comment[1]]
    end

    if comment[1] == nil then
      comment[1] = ""
    end

    if comment[2] == nil then
      comment[2] = ""
    end
  end

  return comment
end

function M.BlockComment()
  local bufnr = vim.api.nvim_get_current_buf()
  local comment = M.GetComment("block")
  local _, sr, sc, _ = unpack(vim.fn.getpos("."))
  local _, er, ec, _ = unpack(vim.fn.getpos("v"))
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- keep start/end in the right place in reverse selection
  if sr > er then
    sr, er = er, sr
    sc, ec = ec, sc
  end

  lines = M.CommentPairs(lines, sr, er, comment)
  if sr == er then
  else
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  --  vim.api.nvim_feedkeys("=", "n", false)
end

function M.CommentPairs(lines, sr, er, commentstr)
  -- if comment string comes is paired
  -- then comment the start of the block and
  -- the end of the block
  -- otherwise comment each line of the block
  local comment = { vim.pesc(commentstr[1]), vim.pesc(commentstr[2]) }
  if (lines[sr]:find(comment[1])) then
    -- uncomment it
    Util.remove_comment_multiline(lines, sr, er, comment[1], comment[2])
  else
    -- comment it
    Util.insert_comment_multiline(lines, sr, er, comment[1], comment[2])
  end

  return lines
end

return M

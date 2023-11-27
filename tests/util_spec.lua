local scm = require "SingleComment.util"

describe("Insert/Remove at start", function()
  -- leftpad 5 space
  local original_str = "     const str = 123;"
  local comment = "{/*"

  it("insert at start", function()
    assert.equals(scm.insert_at_start(original_str, comment), "     {/*const str = 123;")
  end)

  it("remove from start", function()
    local str = scm.insert_at_start(original_str, comment)
    assert.equals(scm.remove_from_start(str, comment), original_str)
  end)
end)

describe("magic chars", function()
  it("{/*", function()
    local str = "{/*"
    local chars = "{/*"
    local escaped_chars = vim.pesc(chars)
    local match1 = str:find(chars)
    local match2 = str:find(escaped_chars)
    assert.equals(match1 == nil, false)
    assert.equals(match2 == nil, false)
  end)
end)

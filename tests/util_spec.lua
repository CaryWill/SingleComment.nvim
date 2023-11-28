local scm = require "SingleComment.util"

describe("comment contains magic chars", function()
  -- leftpad 5 spaces
  local original_str = "     const str = 123;"
  local left_comment = "{/*"
  local right_comment = "*/}"

  it("insert at start", function()
    assert.equals(scm.insert_at_start(original_str, left_comment), "     {/*const str = 123;")
  end)

  it("remove from start", function()
    local str = scm.insert_at_start(original_str, left_comment)
    assert.equals(scm.remove_from_start(str, left_comment), original_str)
  end)

  it("insert at end", function()
    assert.equals(scm.insert_at_end(original_str, right_comment), "     const str = 123;*/}")
  end)

  it("remove from start", function()
    local str = "     const str = 123;*/}"
    assert.equals(scm.remove_from_end(str, right_comment), original_str)
  end)

  it("insert in multi-lines", function()
    local mutli_lines = {
      "     const str = 123;",
      "     const str2 = 123;",
      "     const str3 = 123;"
    }
    local mutli_lines_modified = {
      "     {/*const str = 123;",
      "        const str2 = 123;",
      "        const str3 = 123;/*}"
    }
    local result = scm.insert_comment_multiline(mutli_lines, left_comment, right_comment)
    assert.equals(result[0], mutli_lines_modified[0])
    assert.equals(result[1], mutli_lines_modified[1])
    assert.equals(result[2], mutli_lines_modified[2])
  end)

  it("remove in multi-lines", function()
    local mutli_lines = {
      "     {/*const str = 123;",
      "        const str2 = 123;",
      "        const str3 = 123;/*}"
    }
    local mutli_lines_modified = {
      "     const str = 123;",
      "     const str2 = 123;",
      "     const str3 = 123;"
    }
    local result = scm.remove_comment_multiline(mutli_lines, left_comment, right_comment)
    assert.equals(result[0], mutli_lines_modified[0])
    assert.equals(result[1], mutli_lines_modified[1])
    assert.equals(result[2], mutli_lines_modified[2])
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

  it("no special chars", function()
    local str = "{/1"
    local chars = "{/*"
    local escaped_chars = vim.pesc(chars)
    local match = str:find(escaped_chars)
    local match2 = str:find(chars)
    -- 没有使用通配符所以匹配不上
    assert.equals(match ~= nil, false)
    -- 使用了通配符，所以可以匹配
    assert.equals(match2 == nil, false)
  end)
end)
